# Tasks
- [x] Task 1: 创建新手指引视图
  - [x] SubTask 1.1: 新建 `OnboardingView.swift` 文件。
  - [x] SubTask 1.2: 使用 `TabView` (PageTabViewStyle) 实现多页滑动的引导页面。
  - [x] SubTask 1.3: 编写简要的文案，分别介绍：欢迎页、双模式计时功能、远程控制等核心模块，不深入具体细节。
  - [x] SubTask 1.4: 在最后一页添加“开始使用”按钮。
- [x] Task 2: 配置应用启动路由与状态存储
  - [x] SubTask 2.1: 在应用的入口视图 (如 `ContentView.swift`) 中引入 `@AppStorage("hasSeenOnboarding")` 状态变量。
  - [x] SubTask 2.2: 根据 `hasSeenOnboarding` 的值，条件渲染 `OnboardingView` 或现有的 `ModeSelectionView` / 主界面。
  - [x] SubTask 2.3: 在“开始使用”按钮的点击事件中，将 `hasSeenOnboarding` 设为 `true`。

# Task Dependencies
- [Task 2] depends on [Task 1]
