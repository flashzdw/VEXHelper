# VEXHelper UI/UX 优化方案与设计规范

## 1. 概述 (Summary)

本项目旨在对 VEXHelper 应用进行全面的 UI/UX 优化。基于前期对代码架构和用户交互流程的系统性梳理，本次优化将重点聚焦于\*\*「导航与信息架构」**及**「远程连接与服务器管理」**两大核心模块。
本方案作为**纯设计规范与重构指南文档\*\*（高保真原型替代物），将详细定义交互改进点与视觉重构方向，为后续的代码实施提供清晰的蓝图。

***

## 2. 现状分析与痛点识别 (Current State Analysis)

### 2.1 导航与信息架构 (Navigation & Information Architecture)

* **模式选择前置导致的阻断感**：当前应用在启动后（若未设置默认启动模式），会强制用户在 `ModeSelectionView` 中进行二选一（手机计时 vs 远程控制）。这种前置拦截增加了用户进入核心功能的认知负荷与操作步数。

* **全局返回按钮体验突兀**：在 `MainTabView` 左上角悬浮的“Mode Selection”返回按钮，采用了绝对定位悬浮设计，不仅容易与内部视图（如计时器数字）发生重叠，也打破了 iOS 标准的导航直觉。

* **TabBar 状态耦合过深**：TabBar 的显隐动画（`shouldShowMenu`）与界面的全屏状态、模式选择状态强绑定，在某些边缘场景下容易出现视觉跳跃。

### 2.2 远程连接与服务器管理 (Remote Server Management)

* **UI 风格割裂**：`RemoteServerView` 强行使用了原生的 `Form` 结构，并通过 `UITableView.appearance().backgroundColor = .clear` 等 Hack 手段试图融入自定义的 `AppDarkGray` 背景。这导致界面在不同 iOS 版本上存在样式兼容隐患，且视觉表现生硬。

* **状态反馈缺乏情感化设计**：网络连接状态、IP 地址以及“连接客户端数量”均采用纯文本展示。用户无法第一眼判断当前服务是否处于健康运行状态。

* **控制模式入口割裂**：用户在扫码连接后，还需要手动点击“Enter Control Mode”按钮弹出一个 `fullScreenCover`（`WebControlView`）。逻辑不够连贯。

* **断连提示生硬**：Web 端断开连接时，直接弹出系统的 Alert 拦截用户操作，打断了使用心流。

***

## 3. 优化方案与设计规范 (Proposed Changes)

### 3.1 模块一：重构导航与信息架构

* **扁平化路由结构**：

  * 废弃启动时的全屏 `ModeSelectionView` 拦截。应用启动后直接进入主控台（默认为手机计时模式或记忆上次模式）。

  * **交互规范**：将“模式切换”功能移动至顶部导航栏 (Navigation Title View) 的下拉菜单或分段选择器 (Segmented Control) 中。用户可随时在“本地模式”与“远程模式”间无缝切换，无需“返回主菜单”。

* **消除悬浮按钮**：

  * 移除 `MainTabView` 左上角的悬浮胶囊按钮，彻底释放屏幕顶部空间。

* **稳定 TabBar**：

  * 重新定义 Tab 的分配。建议的 Tab 结构：`Timer/Control` (核心操作区), `Connection` (连接管理，仅远程模式高亮或可用), `Settings` (全局设置)。

### 3.2 模块二：重新设计远程连接管理 (RemoteServerView)

* **卡片式视觉重构 (Card-based UI)**：

  * **设计规范**：摒弃 `Form` 和 `Section`，采用自定义的卡片布局。每张卡片使用 `Color.white.opacity(0.05)` 作为背景，圆角设为 `16`，内部边距 `20`，并增加轻微的阴影。卡片之间保持 `16pt` 的间距，完美适配暗黑主题。

* **可视化状态指示灯 (Status Indicators)**：

  * **设计规范**：在“服务器状态”卡片顶部引入发光指示灯。

    * 🔴 红色/离线：无 Wi-Fi 或服务未启动。

    * 🟡 黄色/等待：服务已启动，等待客户端扫码连接。

    * 🟢 绿色/已连接：已有 Web 客户端接入（附带微弱的呼吸动画 `scaleEffect` 和 `opacity` 动画）。

* **无缝衔接的控制面板 (Seamless Control Flow)**：

  * **交互规范**：取消“Enter Control Mode”全屏弹窗按钮。当检测到 `connectedClientsCount > 0` 时，利用 SwiftUI 的 `withAnimation(.spring())` 自动在下方展开“控制面板（大按钮）”区域；或者在 TabBar 自动跳转到对应的控制 Tab。

* **柔和的异常处理**：

  * **交互规范**：当 Web 客户端意外断开时，不使用系统 Alert。改为在界面顶部滑出一个非阻断式的 Banner 提示（Toast），并在状态卡片中将指示灯变为黄色，提示用户重新连接。

***

## 4. 实施路径预演 (Implementation Steps)

*(注：本方案当前为纯设计文档输出，以下为后续如需代码落地的建议步骤)*

1. **组件封装**：创建 `GlassCardView`（毛玻璃卡片）、`StatusDotView`（状态指示灯）以及 `ToastBannerView`（顶部提示条）等可复用 UI 组件。
2. **重构 ContentView & MainTabView**：移除 `ModeSelectionView` 相关的状态绑定，将模式切换逻辑集成到 NavigationBar 中。
3. **重绘 RemoteServerView**：使用 `ScrollView` + `VStack` 替换原有的 `Form`，应用新的卡片式设计和可视化状态灯。
4. **动效与交互植入**：添加客户端连接数变化时的平滑过渡动画，以及断连时的 Toast 提示逻辑。

***

## 5. 验收标准 (Verification)

* [ ] 设计规范文档已充分响应用户关于“导航信息架构”与“远程连接体验”的优化诉求。

* [ ] 提出了明确的视觉重构方向（卡片式UI、消除原生Form的Hack实现）。

* [ ] 制定了降低认知负荷的交互改进策略（取消前置拦截、自动展开控制面板、非阻断式断连提示）。

