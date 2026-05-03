# VEXHelper

![Platform iOS](https://img.shields.io/badge/Platform-iOS-blue.svg)
![Language Swift](https://img.shields.io/badge/Language-Swift%205-orange.svg)
![UI Framework SwiftUI](https://img.shields.io/badge/UI-SwiftUI-brightgreen.svg)

VEXHelper 是一款专为 VEX 机器人竞赛设计的 iOS 辅助应用程序。其核心目标是为比赛提供精准的计时功能，并在比赛的关键节点自动播放符合规则的语音和音效提示，帮助参赛选手、裁判及现场观众更好地掌控比赛节奏。

本项目不仅提供功能完备的本地计时工具，还创新地集成了**局域网远程显示系统（Remote Display System）**，允许将 iOS 设备作为控制中枢，通过局域网将时间进度和比赛音效实时同步投射到任意设备的浏览器上，完美契合赛事现场的大屏展示需求。

---

## 🌟 核心特性

- **⏱️ 高精度赛事倒计时**
  - 支持标准的 60 秒 VEX 比赛时长。
  - 精确到毫秒级的状态同步机制，提供可靠的时间保障。

- **🎵 智能语音与音效提示**
  - 在比赛关键节点自动触发标准提示音：
    - 比赛开始 (`Start`)
    - 剩余 35 秒（交换驾驶员 `Change`）
    - 剩余 25 秒（比赛警告）
    - 比赛结束 (`Over/Stop`)
  - 支持后台播放及静音模式下强制播放，确保不漏过任何重要提示。

- **📡 局域网远程投屏与控制 (Client-Server 架构)**
  - **iOS 主机端**：内置基于 `NWListener` 的自定义 HTTP 服务与 WebSocket 服务，完全掌控比赛进程。
  - **浏览器显示端**：只需在同一局域网下访问提供的 IP 地址，即可获得大屏沉浸式显示，并同步播放比赛音效。
  - 极低的延迟同步与断线自动重连机制。

- **🎨 现代化的 UI 设计**
  - 基于 SwiftUI 构建，支持 iOS 原生深色/浅色模式。
  - 引入极具质感的液态玻璃/磨砂玻璃视觉特效。
  - Web 端同步复刻原生客户端的 UI 风格。

- **🌐 多语言支持**
  - 内置简体中文 (`zh-Hans`) 与英文 (`en`) 支持。

---

## 🛠 技术栈

本项目基于 Apple 生态的原生技术栈以及标准 Web 技术开发：

- **开发语言**: Swift 5, HTML/CSS/JavaScript
- **UI 框架**: SwiftUI
- **音频处理**: AVFoundation (`AVAudioPlayer`, `AVAudioSession`)
- **网络通信**: Network (`NWListener`), WebSocket, 自定义 HTTP Server
- **架构模式**: MVVM (Model-View-ViewModel)

---

## 📂 项目结构

```text
VEXHelper/
├── VEXHelperApp.swift         # 应用入口，负责音频会话等全局配置
├── ContentView.swift          # 根视图与路由管理
├── Model/                     # 核心逻辑层 (计时引擎、远程控制、音频调度)
│   ├── PhoneTimerEngine.swift # 本地计时器引擎
│   ├── WebTimerEngine.swift   # Web 远程计时器引擎
│   └── SoundsControlCenter.swift # 音频播放中心
├── Network/                   # 网络层 (HTTP/WebSocket 服务端实现)
│   ├── LocalNetworkService.swift # 局域网服务主类
│   └── WebSocketConnection.swift # WebSocket 连接管理
├── TimerGroup/                # 计时器相关的 SwiftUI 视图组件
├── WebAssets/                 # 浏览器端网页资源 (HTML/JS/CSS)
│   ├── index.html             # 远程显示端页面
│   └── app.js                 # 远程显示端 WebSocket 逻辑
└── MediaAssets/               # 媒体资源目录 (包含比赛音效文件和应用图标)
```

---

## 🚀 安装与运行说明

### 1. 环境要求
- macOS 系统
- Xcode 14.0 或更高版本
- iOS 15.0+ 实体设备或模拟器

### 2. 编译与运行
1. 克隆或下载本仓库到本地。
2. 双击 `VEXHelper.xcodeproj` 在 Xcode 中打开项目。
3. 在 Xcode 顶部导航栏选择你的目标运行设备（推荐使用实体 iPhone 以获得最佳的音频测试体验）。
4. 点击运行按钮或使用快捷键 `Cmd + R` 进行编译并运行。

---

## 📖 使用指南

### 📱 本地使用
1. 打开应用，进入主界面即可看到高亮显示的计时器。
2. 点击屏幕下方的 **开始 / 暂停 / 重置** 按钮来控制比赛时间。
3. 计时期间，系统会在相应的关键时间点自动播放声音提示。

### 💻 局域网远程显示
1. 确保 iOS 控制设备和展示设备（如电脑、平板）连接在**同一个局域网（Wi-Fi）**下。
2. 在 App 内进入 **远程服务器 (Remote Server)** 页面，开启**远程显示**服务。
3. App 会生成一个局域网访问地址（例如 `http://192.168.1.100:8080`）和二维码。
4. 在展示设备的浏览器中输入该地址或扫描二维码打开网页。
5. **重要**：在浏览器页面中，必须**点击屏幕任意位置**以解除现代浏览器的“自动播放音频限制”。
6. 连接成功后，Web 页面状态将显示为 "Connected"，此时在 iOS 端的任何操作和计时都将实时同步至浏览器大屏并播放对应音效。

---

## 📝 许可证与版权

本项目为 VEX 机器人竞赛专属定制工具。
Copyright © 2026. All rights reserved.
