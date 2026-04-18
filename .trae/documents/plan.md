# 实施计划

## 1. 目标与范围
- **移除“菜单隐藏”设置项**：彻底抛弃根据计时状态隐藏底部菜单栏的逻辑，让菜单栏在正常界面下始终保持显示。
- **清理相关状态与延迟逻辑**：移除为该功能服务的状态变量（如 `isMenuVisible`、`targetMenuVisibility`）及用于控制消失速度的延迟动画逻辑。
- **保留全屏隐藏逻辑**：在进入全屏模式时，依然需要隐藏底部菜单栏。

## 2. 详细修改步骤

### 2.1 修改 `SharedData.swift`
- 彻底删除 `MenuVisibilityMode` 枚举定义。
- 删除 `SharedData` 类中的 `@AppStorage("menuVisibilityMode") var menuVisibilityMode: MenuVisibilityMode = .afterStart` 属性。

### 2.2 修改 `SettingsView.swift`
- 移除顶部声明的 `@AppStorage("menuVisibilityMode") private var menuVisibilityMode: MenuVisibilityMode = .afterStart`。
- 删除 `Form` 中用于选择“Menu Visibility (底部菜单显示)”的整个 `Section` 视图块。

### 2.3 修改 `ContentView.swift`
- 移除 `@AppStorage("menuVisibilityMode") private var menuVisibilityMode: MenuVisibilityMode = .afterStart`。
- 移除用于控制延迟消失的 `@State private var isMenuVisible: Bool = true` 状态变量。
- 移除计算属性 `targetMenuVisibility` 及其包含的所有状态判断逻辑。
- 移除 `.onChange(of: targetMenuVisibility)` 及其内部的 `DispatchQueue.main.asyncAfter` 延迟动画逻辑。
- 移除 `.onAppear` 中关于 `isMenuVisible = targetMenuVisibility` 的初始化代码。
- 在实例化 `MainTabView` 时，将 `shouldShowMenu` 参数的值直接改为 `!isFullscreen`（即只要不是全屏模式，就始终显示）。

## 3. 验收标准
- 编译通过且无任何报错。
- 运行应用后，进入“设置”页面，发现“Menu Visibility”设置项已被移除。
- 在“手机计时”模式下，点击“Start”开始计时，底部菜单栏不再消失，始终保持可见。
- 点击进入全屏模式时，底部菜单栏依然能够正常隐藏，退出全屏后恢复显示。