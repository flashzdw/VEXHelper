我将严格按照您的要求，使用智能体（`ios-expert`）和 MCP 工具来执行以下重构计划：

### 1. 逻辑重构：创建 `TimerEngine.swift`
我将委托 `ios-expert` 智能体创建 `VEXHelper/Model/TimerEngine.swift` 文件。
- **高精度计时**：使用 `DispatchSourceTimer` 实现 1ms 级别的底层计时精度。
- **逻辑封装**：将原 `TimerControlCenter` 的状态管理（开始、暂停、重置）、音效触发（35s, 25s, 0s）全部集中到此类中。
- **对外接口**：提供 `@Published` 的 `progress` (0.0-1.0) 和 `timeString` 供视图层使用。

### 2. UI 组件分离与迁移
我将委托 `ios-expert` 智能体对视图文件进行拆分和重构：

- **`TimerNumber.swift` (竖屏核心组件)**：
    - 将 `TimerPage.swift` 中的竖屏圆环视图（包括背景圆环、动态进度圆环、中间倒计时文字、静音按钮）完整迁移至此文件。
    - 确保其成为一个独立的、自包含的 SwiftUI 视图组件。

- **`HorizontalTimerNumber.swift` (横屏核心组件)**：
    - 将 `TimerPage.swift` 中的横屏全屏视图（包括背景圆角矩形边框、动态进度条边框、旋转的倒计时文字）完整迁移至此文件。
    - 保持原有的旋转和布局逻辑不变。

- **`TimerPage.swift` (页面组装)**：
    - 删除所有已迁移的绘图和布局代码。
    - 重构为容器视图，仅负责根据横竖屏状态切换显示 `TimerNumber` 或 `HorizontalTimerNumber`，以及底部的控制按钮布局。

### 3. 代码规范化
我将委托 `ios-expert` 智能体执行以下规范化操作：
- **统一文件头**：将 `SharedData.swift` 及所有新建/修改文件的头部注释统一为 `ContentView.swift` 的格式（Created by DongZi.8009 on 2026/1/24）。
- **优化注释**：清理冗余注释，并为 `TimerEngine` 的核心逻辑添加清晰的中文说明。

### 4. 编译与验证
- 在每一步重构完成后，我将使用 `mcp_xcodebuild` 相关工具（如 `mcp_build_sim` 或 `mcp_xcodebuild_doctor`）来验证项目能否成功编译，确保重构没有引入错误。

请确认此计划，我将立即开始执行。