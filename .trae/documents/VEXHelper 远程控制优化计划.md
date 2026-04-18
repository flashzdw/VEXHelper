# VEXHelper 远程控制优化计划

根据您的需求，我们将进行以下重大更新，以实现 Web 端多语言同步、默认远程音频、以及控制逻辑的解耦。

## 1. 架构解耦 (Decoupling)
将现有的单一 `TimerEngine` 模式拆分为“本地”和“远程”双引擎。
- **本地计时器 (`localTimerEngine`)**: 仅用于 App 内的“计时器”页面，不广播任何状态，不连接网络服务。
- **远程计时器 (`remoteTimerEngine`)**: 仅用于“远程控制”模块，负责驱动 Web 端。
- **音频控制**：
  - 本地计时器 -> 直接调用 `SoundsControlCenter` 播放本地声音。
  - 远程计时器 -> 通过回调通知 `RemoteControlManager`，进而通过 WebSocket 广播 `playSound` 指令。

## 2. 远程控制管理器 (`RemoteControlManager`)
创建一个新的 `ObservableObject` 来管理远程控制的所有逻辑：
- 持有 `remoteTimerEngine`。
- 监听 `remoteTimerEngine` 的状态变化并调用 `LocalNetworkService.broadcast`。
- 监听 App 语言变化，并向 Web 端发送语言同步指令。
- 管理“首次进入”状态，控制介绍页面的显示。

## 3. Web 端多语言适配 (Web Localization)
- **协议升级**：WebSocket 增加 `{ "type": "language", "lang": "zh-Hans" }` 指令。
- **Web 实现**：
  - `index.html`: 为文本元素添加 `data-i18n` 属性。
  - `app.js`: 维护一个简单的翻译字典 (`en` / `zh-Hans`)，收到指令后更新 DOM 文本。

## 4. 界面更新 (UI Updates)
- **SettingsView**: “仅远程音频”开关默认设为 `true`。
- **RemoteServerView**:
  - 移除原有的开关式布局。
  - 增加“进入控制模式” (Enter Control Mode) 大按钮。
  - 增加“首次使用介绍” (Onboarding) 弹窗/页面。
- **WebControlView (新)**:
  - 专用于控制 `remoteTimerEngine` 的界面。
  - 包含开始/暂停/重置按钮，以及当前状态监视。
  - 界面设计简洁，强调“控制器”属性。

## 5. 实施步骤
1.  **重构 TimerEngine**: 移除内部的 `LocalNetworkService` 依赖，改为 `onBroadcast` 和 `onPlaySound` 回调闭包。
2.  **创建 RemoteControlManager**: 实现双引擎管理逻辑。
3.  **Web端升级**: 修改 `index.html` 和 `app.js` 支持多语言。
4.  **UI 开发**: 实现 `WebControlView` 和介绍页，并更新 `RemoteServerView` 入口。

请确认此计划。