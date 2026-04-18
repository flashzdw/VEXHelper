# 问题修复计划

本计划旨在解决手机计时器无法计时、底部菜单栏主题刷新异常以及 Web 控制器静音按钮动画延迟的问题。

## 1. 修复手机计时器逻辑 (TimerEngine)

**问题分析**：`startTimer` 方法内部调用了 `stopTimer`，而 `stopTimer` 最近被修改为“强制归零”并广播状态。这导致每次开始计时时，时间都会先被重置为 0，从而立即结束计时。

**实施步骤**：

1. 修改 `TimerEngine.swift`：

   * 将 `stopTimer` 方法重构，拆分为两个方法：

     * `invalidateTimer()`: 仅负责停止 `Timer` 实例，不修改时间数据。

     * `stopAndReset()`: 调用 `invalidateTimer()` 并将时间归零、广播状态。

   * 更新调用点：

     * `startTimer(resuming:)`: 调用 `invalidateTimer()`（不再归零）。

     * `pause()`: 调用 `invalidateTimer()`。

     * `stop()` (用户手动停止): 调用 `invalidateTimer()`（保持当前时间，状态改为 stopped）。

     * `reset()`: 调用 `stopAndReset()`。

     * `handleTimerFinished()`: 调用 `stopAndReset()`（计时结束自动归零）。

## 2. 修复底部菜单栏主题刷新与闪烁 (Theme & TabBar)

**问题分析**：

* **刷新不及时**：移除 `.id(appTheme)` 后，SwiftUI 不会强制重建视图，导致 `UITabBar` 可能不立即响应外观变化。

* **颜色闪烁**：多个视图（`SettingsView`, `RemoteServerView`）在 `init` 中修改全局 `UIAppearance`，可能导致冲突。且未显式配置 `UITabBarAppearance` 可能导致其在 Light/Dark 模式切换时表现不一致。

**实施步骤**：

1. 修改 `ContentView.swift`：

   * 添加 `updateTabBarAppearance()` 方法，显式配置 `UITabBarAppearance`，确保背景色和图标颜色在不同主题下正确。

   * 在 `.onChange(of: appTheme)` 中调用此方法。

   * 在 `init` 或 `onAppear` 中也调用此方法进行初始配置。
2. 修改 `MainTabView.swift`：

   * 重新评估是否需要 `.id(appTheme)`。为了用户体验（保留选中 Tab），我们将尝试不使用 `.id`，而是依赖 `ContentView` 的 `preferredColorScheme` 和显式的 `UITabBarAppearance` 更新来驱动界面刷新。

## 3. 修复 Web 控制器静音按钮动画 (Animation)

**问题分析**：`Button` 的 `label` 中的图片切换带有隐式动画，普通的 `.animation(nil)` 有时无法完全消除。

**实施步骤**：

1. 修改 `WebControlView.swift`：

   * 在静音按钮的 `Image` 上使用 `.transaction { $0.animation = nil }` 来强制禁用动画事务。

## 4. 验证计划

* **计时器**：点击开始，确认时间正常倒数，不再瞬间归零。

* **主题**：在设置中切换主题（Light/Dark/System），确认底部菜单栏颜色立即跟随变化，且不会随机闪烁。

* **Web控制**：反复点击静音按钮，确认图标切换瞬间完成，无渐变效果。

