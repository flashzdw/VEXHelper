# VEXHelper 项目文档

## 1. 项目概览

VEXHelper 是一款专为 VEX 机器人竞赛设计的 iOS 辅助应用程序。其主要目标是为比赛提供精确的计时功能和符合比赛规则的音效提示，帮助参赛选手和裁判更好地掌控比赛节奏。

应用采用现代化的 SwiftUI 框架构建，界面简洁直观，核心功能包括：

* 精确的倒计时器（标准比赛时长 60 秒）

* 关键时间点的自动语音/音效提示（开始、35秒交换驾驶员、25秒、结束）

* 欢迎引导页面与主功能页面的流畅切换

## 2. 技术栈

本项目完全基于 Apple 生态的原生技术栈开发：

* **编程语言**: Swift 5

* **UI 框架**: SwiftUI

* **音频框架**: AVFoundation (AVAudioPlayer, AVAudioSession)

* **架构模式**: MVVM (Model-View-ViewModel)

* **依赖管理**: 原生 Swift Package Manager (目前无外部依赖)

* **目标平台**: iOS

## 3. 项目结构

项目采用清晰的功能模块化结构（已优化）：

```
VEXHelper/
├── VEXHelperApp.swift         # 应用入口，负责全局配置（如音频会话）
├── ContentView.swift          # 根视图，处理顶层导航和视图路由，包含 SharedData
├── Model/                     # [Model/ViewModel] 核心逻辑层
│   ├── TimerControlCenter.swift # 计时器核心逻辑控制器 (ViewModel)
│   └── SoundsControlCenter.swift # 音频播放服务类
├── TimerGroup/                # [View] 计时器相关 UI 组件
│   ├── TimerPage.swift        # 计时器主页面
│   ├── TimerNumber.swift      # 数字显示组件
│   └── HorizontalTimerNumber.swift # 横屏/全屏数字显示组件
├── MediaAssets/               # 资源文件
│   └── Audio/                 # 比赛音效 (Start.MP3, Over.MP3 等)
└── SharedData                 # (定义在 ContentView.swift 中) 全局状态单例
```

### 关键文件说明

* **VEXHelperApp.swift**: 初始化 `AVAudioSession`，设置 `.playback` 类别以确保在静音模式下也能播放关键提示音。

* **TimerControlCenter.swift**: 经过重构的核心计时器逻辑，包含时间状态机和音效触发逻辑。

* **SharedData**: 一个 `ObservableObject` 单例，用于在不同视图和控制器之间共享应用级状态（如 `timerSetting`, `soundSetting`）。

## 4. 核心模块详解

### 4.1 计时器模块 (TimerControlCenter)

该模块是应用的核心，负责维护比赛时间状态。经过重构，现在具备更高的可维护性：

* **高精度计时**: 使用 `Timer.scheduledTimer` 以 **0.1秒** 为间隔触发，通过 `tick()` 方法统一处理时间扣减。

* **配置化参数**: 所有关键时间节点（总时长、提示点）均定义在 `TimerConfig` 结构体中，告别魔术数字。

  * **Trigger Change**: 剩余 36000ms (36秒，对应35秒提示)

  * **Trigger Warning**: 剩余 26000ms (26秒，对应25秒提示)

  * **Trigger Over**: 剩余 1000ms (1秒，对应结束)

* **状态机**: 维护 `TimerStatus` 枚举状态 (`idle`, `running`, `paused`, `stopped`)，精确控制计时器行为。

### 4.2 音频模块 (SoundsControlCenter)

负责处理所有音效播放，确保比赛提示音的及时响应。

* **动态加载**: 通过 `updateSoundPlayer(with:)` 方法，根据传入的资源名称动态加载对应的 MP3 文件。

* **后台播放支持**: 配置了后台播放权限，防止屏幕锁定或静音开关影响比赛提示音。

### 4.3 状态管理与联动

计时器与音频模块通过 `TimerControlCenter` 紧密协作：

* **时间点检测**: 在 `tick()` 循环中，自动检查是否达到 `TimerConfig` 定义的触发点。

* **防抖动**: 使用 `hasPlayed35SecondSound` 等布尔标志位，确保每个时间点的音效只播放一次，避免重复触发。

## 5. 最近优化日志

* **重构**: 将 `TimerControlCenter` 逻辑重写，提取常量配置，消除重复代码。

* **规范化**: 将 `Modle` 目录更名为 `Model`，修正 `HorizontalTimerNumber` 拼写错误。

* **清理**: 移除了根目录下冗余的旧版 UI 文件。

* **命名**: 将 `TimerSetting` 属性重命名为标准的 `timerSetting`。

