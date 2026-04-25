# VEXHelper 项目代码审查与改进计划

在对 VEXHelper 项目的架构、网络层、数据模型和视图层进行彻底审查后，我发现了一些潜在的缺陷（Defects）以及可以进一步优化的改进点（Areas for Improvement）。

## 1. 发现的缺陷 (Defects)

### 1.1 WebSocket 内存泄漏与循环引用风险

* **位置**: `Network/WebSocketConnection.swift`

* **问题**:

  * `readMessage()` 方法中 `DispatchQueue.global().async { self.readMessage() }` 强引用了 `self`，如果连接断开但读取任务被堆积，会导致连接对象无法释放。

  * `send()` 方法的 `contentProcessed` 回调中 `self.stop()` 同样强引用了 `self`。

* **修复方案**: 在闭包中使用 `[weak self]` 来打破强引用循环，避免潜在的内存泄漏。

### 1.2 Web 客户端断开连接时的弹窗显示冲突

* **位置**: `RemoteServerView.swift`

* **问题**: 当 Web 端断开连接触发 `showWebDisconnectedAlert = true` 时，如果当前正处于 Web 控制模式（即 `WebControlView` 通过 `.fullScreenCover` 处于全屏呈现状态），在底层的 `RemoteServerView` 上直接触发弹窗会导致 SwiftUI 渲染冲突（"Attempt to present Alert while a presentation is in progress"），用户将无法看到该断开提示。

* **修复方案**: 在检测到断开连接时，应先将 `showControlMode` 设为 `false` 关闭控制面板，稍微延迟（等待全屏关闭动画结束）后再弹出提示框。

### 1.3 定时器对象释放不完全

* **位置**: `Model/PhoneTimerEngine.swift` 和 `Model/WebTimerEngine.swift`

* **问题**: 内部核心 `timer` 被加入到 `RunLoop.main` 中，虽然闭包内使用了 `[weak self]`，但如果没有显式调用 `invalidate()`，定时器实例会一直驻留在 RunLoop 中继续空转。

* **修复方案**: 为两个引擎类添加 `deinit { timer?.invalidate() }` 以确保生命周期结束时彻底销毁。

### 1.4 HTTP 文件服务器路径解析存在隐患

* **位置**: `Network/HTTPConnectionHandler.swift`

* **问题**: `serveFile` 方法通过以 `.` 分割文件名来获取后缀（`components.count == 2`）。如果请求的文件名包含多个点（例如 `Start.1.MP3`），该判断将失效，导致无法正确返回文件而返回 404。

* **修复方案**: 使用 `NSString` 或 `URL` 的标准 API (`deletingPathExtension`, `pathExtension`) 来安全提取文件名和后缀。

### 1.5 状态管理的反模式 (StateObject 误用)

* **位置**: `ContentView.swift`

* **问题**: 使用了 `@StateObject var sharedData = SharedData.shared`。`@StateObject` 的设计初衷是让视图自己创建并拥有该对象的生命周期。将其用于全局单例是反模式，在某些情况下视图重绘时可能引发不可预期的行为。

* **修复方案**: 更改为 `@ObservedObject var sharedData = SharedData.shared`。

***

## 2. 待改进的地方 (Areas for Improvement)

### 2.1 计时器时长和音效设置处于“假脱机”状态 (未生效)

* **位置**: `SharedData.swift`, `PhoneTimerEngine.swift`, `SettingsView.swift`

* **问题**:

  * `SharedData` 中预留了 `TimerSetting` (总时长) 和 `SoundSetting` (全局静音) 的数据结构。

  * 但两个计时器引擎中目前直接硬编码了 `private let totalTime: Int = 60000` (60秒)，完全忽略了全局配置。

  * `SettingsView` 中也缺乏修改这些基础设置（如切换 60s/120s 比赛时长、全局关闭音效）的 UI 控件。

* **改进方案**: 让引擎初始化和重置时读取 `SharedData` 的设置项，并在 `SettingsView` 中增加对应的时长 Picker 和音效 Toggle。

### 2.2 音频播放器缓存淘汰策略不精确

* **位置**: `Model/SoundsControlCenter.swift`

* **问题**: 当音频缓存超过 `maxCachedPlayers` 时，代码使用 `cachedPlayers.keys.first` 来移除元素。由于 Swift 的 Dictionary 是无序的，这可能错误地移除了最近经常使用的、甚至是当前正在播放的音频，而不是最老的音频。

* **改进方案**: 鉴于应用只有 4 个很小体积的音效文件，其实可以直接移除最大数量限制；或者改用数组记录播放顺序，实现真正的 LRU（最近最少使用）淘汰策略。

### 2.3 ObservableObject 内部使用 @AppStorage 的局限性

* **位置**: `SharedData.swift`

* **问题**: 在 `SharedData` 内部使用了 `@AppStorage("launchMode")`。在 `ObservableObject` 中修改 `@AppStorage` 的值并不会自动触发 `objectWillChange`，可能导致依赖该属性的视图无法自动响应更新。

* **改进方案**: 针对需要全局发布的 UserDefaults 属性，建议使用 Combine 监听 `UserDefaults.standard.publisher` 或在属性的 `willSet` 中手动调用 `objectWillChange.send()`。

***

## 3. 下一步执行建议

目前处于 **Plan Mode (计划模式)**。
请您审阅上述发现的问题。您可以：

1. 直接回复 **“确认”**，我将立即为您一揽子修复上述所有 Defects 并完善改进点。
2. 或者指定您希望优先修复的特定部分（例如：“只修复网络和内存泄漏相关的问题”）。

