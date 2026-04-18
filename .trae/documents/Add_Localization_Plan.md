# 多语言支持补全计划

## 1. 概述 (Summary)
彻底检查当前项目中的各个模块（包括 SwiftUI 视图、Model 数据、以及 Web 前端），找出所有硬编码且未支持多语言（国际化/本地化）的文本，并为它们添加统一的英文键与中英文翻译。

## 2. 当前状态分析 (Current State Analysis)
通过全量代码检索（Grep）及文件审查，发现以下部分仍存在未支持多语言的情况：
1. **模型枚举数据（SharedData.swift）**：`TimerMode.localizedName` 等枚举直接返回了硬编码的中文（如 `"手机计时"`）。
2. **模式选择界面（ModeSelectionView.swift）**：视图中存在硬编码中文字符串，如 `Text("选择计时模式")`。
3. **主选项卡视图（MainTabView.swift）**：全局返回按钮包含中文 `Text("模式选择")`。
4. **设置界面（SettingsView.swift）**：新增的 `"Open at Launch"`、`"Startup"` 未添加多语言；另外 `"When enabled and a browser is connected, sound will play on the browser instead of this device."` 没有复用现有的 Localizable.strings 键。
5. **远程控制视图（RemoteServerView.swift）**：无网络提示、Web 端断开连接的弹窗（`Alert` 和 `Button`），以及服务器状态的动态文本未包裹 `LocalizedStringKey`。

## 3. 提议的更改 (Proposed Changes)

### 3.1 修改 Swift 代码使用英文 Key
*   **`VEXHelper/SharedData.swift`**：
    *   将 `TimerMode` 中的中文名称替换为英文键：`"手机计时"` -> `"Phone Timer"`，`"远程控制"` -> `"Remote Control"`。
*   **`VEXHelper/ModeSelectionView.swift`**：
    *   将 `Text("选择计时模式")` 替换为 `Text("Select Timer Mode")`。
    *   将 `ModeButton` 传入的中文 `title` 和 `subtitle` 修改为英文键（如 `"Phone Timer"` 和 `"Timer and control on the phone screen"` 等）。
*   **`VEXHelper/MainTabView.swift`**：
    *   将 `Text("模式选择")` 修改为 `Text("Mode Selection")`。
*   **`VEXHelper/SettingsView.swift`**：
    *   将 `"When enabled and a browser is connected..."` 修正为与已有多语言完全一致的 `"When enabled, sound will play on the connected browser instead of this device."`。
*   **`VEXHelper/RemoteServerView.swift`**：
    *   将动态 IP 文本 `Text(server.serverIP)` 包装为 `Text(LocalizedStringKey(server.serverIP))`。
    *   为 Alert 及其按钮添加多语言支持。

### 3.2 更新多语言字符串文件 (Localizable.strings)
需要在 `en.lproj/Localizable.strings` 和 `zh-Hans.lproj/Localizable.strings` 两个文件中同时添加以下新增的键值对：
*   `"Mode Selection"`
*   `"Select Timer Mode"`
*   `"Phone Timer"`
*   `"Timer and control on the phone screen"`
*   `"Control with your phone, display on any browser"`
*   `"Open at Launch"`
*   `"Startup"`
*   `"No Wi-Fi Connection"`
*   `"Please connect to Wi-Fi or Hotspot"`
*   `"Web Disconnected"`
*   `"Switch to Phone Timer"`
*   `"Stay in Web Mode"`
*   `"The Web client has disconnected. Would you like to switch back to phone timer mode?"`

## 4. 假设与决策 (Assumptions & Decisions)
*   **假设**：项目中 Web 端的界面（`index.html` 和 `app.js`）的 `i18n` 字典已经能够覆盖当前的所有 Web 文本，无需在此次计划中扩充 Web 端的键值。
*   **决策**：对于 SwiftUI 中的 Picker 和 Text，尽量使用标准的字面量方式触发系统自带的 `LocalizedStringKey` 解析，对于动态变量（如 IP 地址）手动包裹 `LocalizedStringKey`。

## 5. 验证步骤 (Verification Steps)
1. 运行项目并进入“Settings”将语言切换为 English，检查应用各处（特别是启动模式选择、底部全局返回按钮、远程投屏界面、设置界面）是否完全显示英文。
2. 切换回“中文”，检查是否能正确渲染中文翻译。
3. 模拟无网络状态，检查 RemoteServerView 的错误提示是否正常被翻译。
4. 模拟 Web 端连接后断开，检查弹出的 Alert 是否正常翻译。