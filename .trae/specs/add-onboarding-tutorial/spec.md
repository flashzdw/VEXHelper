# 欢迎界面与新手指引 Spec

## Why
应用目前缺乏首次启动时的引导流程，新用户初次打开时可能不清楚应用的核心功能和各个模块的作用。

## What Changes
- 添加一个首次启动欢迎界面 (OnboardingView)。
- 包含几页简短的轮播/分页内容，简要介绍应用的核心模块（如：双模式计时器、远程控制、快捷设置等）。
- 在应用启动入口增加状态判断，确保只在首次安装或重置状态后显示。

## Impact
- Affected specs: 应用启动路由 (App Launch Routing)。
- Affected code: 
  - `VEXHelperApp.swift` / `ContentView.swift` (或启动根视图)
  - 新增 `OnboardingView.swift`

## ADDED Requirements
### Requirement: 首次启动引导
系统应当在用户首次打开应用时，展示欢迎界面和简要的功能介绍。

#### Scenario: 首次启动应用
- **WHEN** 用户第一次安装并打开应用
- **THEN** 系统显示新手指引界面，介绍各部分功能。
- **WHEN** 用户浏览完毕并点击“开始使用”
- **THEN** 系统保存已阅读状态，并进入应用的常规模式选择或主界面。

#### Scenario: 非首次启动应用
- **WHEN** 用户已完成新手指引并再次打开应用
- **THEN** 系统直接进入常规模式选择或主界面，跳过新手指引。
