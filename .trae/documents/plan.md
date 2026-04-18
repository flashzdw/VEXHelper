# 实施计划

## 1. 目标与范围
- **目标**：解决“手机计时”模式下网页端仍会同步显示计时状态和播放音频的问题，实现“手机计时”与“远程控制（Web计时）”彻底独立隔离。
- **范围**：
  - `PhoneRemoteControlManager`：切断手机计时模式下的状态广播和音频广播。
  - `SharedData`：修改新连接建立时的初始状态同步逻辑，在手机计时模式下不向 Web 端发送任何计时器数据。
  - （可选/预防性）`PhoneTimerEngine`：确保其 `onBroadcast` 和 `onPlaySound` 闭包的触发不会导致不必要的网络开销。

## 2. 当前状态分析
目前，`PhoneRemoteControlManager` 监听了 `PhoneTimerEngine` 的 `onBroadcast` 和 `onPlaySound` 事件，并在收到事件时无条件地调用 `networkService.broadcast(message:)`。
同时，在 `SharedData.swift` 的 `syncInitialState(to:)` 方法中，当有新的 WebSocket 客户端连接时，代码会判断当前是 `.phone` 还是 `.web` 模式，如果是 `.phone` 模式，依然会把 `phoneTimerEngine` 的状态打包成 JSON 发送给客户端。
这两个原因导致了手机计时模式下，Web 页面依然会跟着同步变化和响铃。

## 3. 详细修改步骤

### 3.1 修改 `SharedData.swift`
- **定位**：`syncInitialState(to connection: WebSocketConnection)` 方法。
- **修改**：
  - 保留语言同步（`language`）。
  - 在处理计时器状态和静音状态同步时，增加对 `activeTimerMode` 的严格限制。
  - 如果 `activeTimerMode == .phone`，则**不发送** `toggleMute` 消息，也**不发送** `update` 状态消息（或者发送一个特定的“待机/未连接”的空闲状态，但更简单的做法是直接不发送，或者发送 `timeString: "--:--"`）。
  - 为了让 Web 端在手机模式下明确显示未激活状态，可以在 `.phone` 模式下发送一个固定为 `00:00` 且状态为 `idle` 的空数据，或者发送特定指令让前端知道当前非 Web 控制模式。
  - **决定**：最稳妥的做法是在 `.phone` 模式下，发送一个默认的重置状态：`timeString: "00:00"` (或对应默认时间), `progress: 0.0`, `status: "idle"`，并且不发送静音同步。或者，直接保持原样但不赋值真实数据。
  - **更彻底的修改**：直接在 `PhoneRemoteControlManager` 中拦截广播，并在 `syncInitialState` 中对于 `.phone` 模式发送默认空闲状态。

  ```swift
  switch activeTimerMode {
  case .phone:
      // 彻底隔离：手机模式下不向 Web 同步任何真实数据
      isMuted = true // 强制静音，防止手机模式下网页发声
      timeString = "--:--"
      progress = 0.0
      statusStr = "idle"
  case .web:
      // 原有逻辑保持不变
      isMuted = webRemoteControlManager.isMuted
      timeString = webTimerEngine.timeString
      progress = webTimerEngine.progress
      // ... 状态转换
  }
  ```

### 3.2 修改 `PhoneRemoteControlManager.swift`
- **定位**：`setupEngine()` 方法。
- **修改**：
  - 目前：
    ```swift
    phoneTimerEngine.onBroadcast = { [weak self] jsonMessage in
        self?.networkService.broadcast(message: jsonMessage)
    }
    ```
  - 更改为：**完全移除** `PhoneRemoteControlManager` 对网络广播的调用，因为它在手机模式下不再需要向 Web 端同步任何信息。或者保留闭包但内部什么也不做。
  - **注意**：如果彻底移除，`PhoneRemoteControlManager` 还需要保留吗？
    - 手机模式下依然可能需要处理本地音频播放逻辑（如果音频逻辑放在了这里）。
    - 检查 `PhoneRemoteControlManager.swift` 的音频处理逻辑：发现它主要处理 `isRemoteAudioEnabled`。既然要求“彻底独立”，且上一轮修改中“音频设置”已经只在 `.web` 模式下显示，那么在手机模式下，音频应该**只**在本地播放，不需要广播到 Web。
  - **行动**：
    - 在 `setupEngine()` 中，删除 `networkService.broadcast(message: jsonMessage)`。
    - 在 `handlePlaySound(soundName:)` 中，删除所有网络广播逻辑（`networkService.broadcast(...)`），只保留可能存在的本地播放逻辑（实际上手机的本地播放是由 `SoundsControlCenter` 在 `PhoneTimerEngine` 中触发的，或者由 Manager 处理的。需要确认）。
    - *探索确认*：阅读 `PhoneRemoteControlManager.swift`，确认它的主要职责。如果它仅仅是为了将手机状态广播给 Web（旧架构的遗留物），那么我们甚至可以清空其广播行为。

### 3.3 检查 `PhoneRemoteControlManager.swift` 的音频逻辑
- `PhoneTimerEngine` 通过 `SoundsControlCenter` 播放本地声音。
- `PhoneRemoteControlManager` 监听到 `onPlaySound` 后，判断 `isRemoteAudioEnabled`，然后决定是否静音本地并广播给网络。
- 既然现在要求“彻底独立”，在手机模式下，应该**永远本地播放，永远不广播给网络**。
- 因此，`PhoneRemoteControlManager` 中关于网络的广播（`onBroadcast` 和 `onPlaySound` 中的 `networkService.broadcast`）应该全部被拦截或移除。

## 4. 假设与决策
- **决策**：为了实现“彻底独立”，`activeTimerMode == .phone` 时，系统不应该向 WebSocket 客户端发送任何有意义的计时数据或音频指令。
- **决策**：如果用户在手机模式下打开了浏览器连接，浏览器上将只会显示 `--:--` 或保持初始的空白状态，并且不会发出任何声音。
- **验证点**：移除 `PhoneRemoteControlManager` 的广播后，需要确保手机端自身的计时器 UI 更新和本地声音播放不受影响（这通常由 `@Published var status/timeRemaining` 和 `SoundsControlCenter` 直接处理，与 Manager 无关）。

## 5. 验证步骤
1. 运行应用，选择“手机计时”模式。
2. 浏览器连接到显示的 IP 地址（如果能看到的话，或者通过切换模式获取 IP）。
3. 在手机上点击 Start/Stop，观察浏览器：浏览器应该**没有任何反应**，时间不走，也没有声音。
4. 手机本地应该能正常显示倒计时，并且能正常发出声音。
5. 切换到“远程控制”模式，在手机上控制 WebTimerEngine，观察浏览器：此时浏览器应该能正常同步倒计时和声音。