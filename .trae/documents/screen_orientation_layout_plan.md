# 实现方案计划

## 1. 摘要

通过引入 `AppDelegate` 控制 iOS 原生的屏幕方向锁定，替换掉目前通过 `.rotationEffect` 手动模拟横屏的方案。确保应用在普通模式下始终锁定竖屏，在进入全屏时自动旋转并锁定为横屏，并针对原生横屏状态重构全屏模式下的界面元素布局。

## 2. 当前状态分析

* **屏幕方向**：目前应用允许设备进行所有方向的旋转，在全屏模式下通过对视图进行 `.rotationEffect(.degrees(90))` 等手动旋转操作来模拟横屏。这种方式不仅实现繁琐，且不能完美利用横屏的宽屏比例（进度条依然受限于短边）。

* **全屏布局**：`TimerPage` 的 `fullScreenView` 以及 `HorizontalTimerNumber` 都包含了大量的手动旋转代码，各种控件（如退出全屏按钮、控制按钮、静音按钮）都是基于竖屏的坐标系强行位移和旋转的。

## 3. 拟修改内容

### 3.1 引入 AppDelegate 管理屏幕方向

* **文件**: `VEXHelper/VEXHelperApp.swift`

* **修改内容**:

  * 创建 `AppDelegate` 类，继承自 `NSObject, UIApplicationDelegate`。

  * 定义静态属性 `orientationLock = UIInterfaceOrientationMask.portrait` 用于控制全局方向，默认锁定为竖屏。

  * 实现 `supportedInterfaceOrientationsFor` 方法返回 `orientationLock`。

  * 在 `VEXHelperApp` 结构体中，通过 `@UIApplicationDelegateAdaptor` 注册 `AppDelegate`。

### 3.2 动态切换屏幕方向

* **文件**: `VEXHelper/TimerGroup/TimerPage.swift`

* **修改内容**:

  * 在 `TimerPage` 的根 `ZStack` 增加 `.onChange(of: isFullscreen)` 监听器。

  * 当 `isFullscreen` 为 `true` 时，设置 `AppDelegate.orientationLock = .landscape`，并通过 `UIWindowScene.requestGeometryUpdate` (iOS 16+) 或 `UIDevice.setValue` (iOS 15) 强制设备旋转至横屏。

  * 当 `isFullscreen` 为 `false` 时，设置 `AppDelegate.orientationLock = .portrait` 并强制设备旋转至竖屏。

### 3.3 重构横屏布局 (移除手动旋转)

* **文件**: `VEXHelper/TimerGroup/HorizontalTimerNumber.swift`

* **修改内容**:

  * `HorizontalTimerNumber`: 移除 `.rotationEffect(.degrees(90))` 和 `.fixedSize()`，使其在原生横屏中自然居中显示。

  * `LandscapeTimerView`: 移除静音按钮的 `.rotationEffect(.degrees(90))`。将其位置从逻辑旋转调整为横屏的真实左下角（使用 `padding(.bottom, 20)` 和 `padding(.leading, 20)`）。

### 3.4 调整全屏模式界面元素

* **文件**: `VEXHelper/TimerGroup/TimerPage.swift`

* **修改内容**:

  * **退出全屏按钮**: 移除 `.rotationEffect(.degrees(180))`，将其放置在原生横屏的右上角，并保留 `.bottomLeft` 圆角修饰以贴合屏幕边缘。

  * **模式切换按钮**: 移除 `.rotationEffect(.degrees(90))`，将其放置在原生横屏的左上角（保留在安全区域内）。

  * **底部控制按钮**: 移除 `controlButton` 辅助函数的 `rotated` 参数。将原本放在侧边 (`HStack` 里包 `VStack`) 的按钮组，改为水平居中放置在底部的 `HStack`。

## 4. 假设与决策

* **决策**: 采用系统原生的方向控制机制。横屏模式下的倒计时进度条（`RoundedRectangle`）将自动填满整个横屏区域，成为一个宽大的圆角矩形，视觉效果更具冲击力。

* **兼容性**: 屏幕旋转 API `requestGeometryUpdate` 是 iOS 16 引入的，针对较低版本的 iOS 设备需保留 `UIDevice.current.setValue` 的旧方式。

## 5. 验证步骤

1. 编译并运行应用。
2. 停留在默认主界面，尝试物理旋转手机，确认界面始终保持**竖屏锁定**，不会随设备翻转。
3. 点击右上角“全屏”按钮，确认应用能够自动切换到**横屏**。
4. 检查横屏下的 UI 布局：

   * 倒计时数字居中，进度条（宽大圆角矩形）正常铺满显示。

   * 左上角为模式切换按钮，右上角为退出全屏按钮。

   * 底部水平居中显示控制按钮（播放/暂停/重置）。

   * 左下角显示静音按钮。
5. 点击右上角的退出全屏按钮，确认应用能自动恢复并锁定为**竖屏**。

