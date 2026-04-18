# VEXHelper 构建与运行指南

本项目基于 SwiftUI 和 AVFoundation 构建。以下是构建和运行项目的步骤。

## 1. 文件结构检查

确保项目目录包含以下新创建的文件和文件夹：

- `VEXHelper/Model/`
  - `TimerControlCenter.swift`
  - `SoundsControlCenter.swift`
- `VEXHelper/TimerGroup/`
  - `TimerPage.swift`
  - `TimerNumber.swift`
  - `HorizontalTimerNumber.swift`
- `VEXHelper/SharedData.swift`
- `VEXHelper/VEXHelperApp.swift` (已更新)
- `VEXHelper/ContentView.swift` (已更新)

## 2. Xcode 项目配置 (重要)

由于项目文件 (`.pbxproj`) 无法自动修改，您需要手动将新文件添加到 Xcode 项目中：

1.  打开 `VEXHelper.xcodeproj`。
2.  在左侧项目导航栏中，右键点击 `VEXHelper` 文件夹。
3.  选择 **"Add Files to 'VEXHelper'..."**。
4.  选择 `Model` 和 `TimerGroup` 文件夹，以及 `SharedData.swift` 文件。
5.  确保 **"Copy items if needed"** 未勾选（因为文件已在目录中）。
6.  确保 **"Create groups"** 被选中。
7.  确保 **"Add to targets"** 中勾选了 `VEXHelper` target。
8.  点击 **Add**。

## 3. 资源文件检查

确保音频文件已包含在项目中：

1.  在 Xcode 中检查 `MediaAssets/Audio` 文件夹是否存在。
2.  如果不存在，请按照上述步骤添加 `MediaAssets` 文件夹。
3.  确保 `Start.MP3`, `Change.MP3`, `Over.MP3` 等文件在 Build Phases -> **Copy Bundle Resources** 中。

## 4. 运行项目

1.  选择目标模拟器（如 iPhone 15 Pro）。
2.  点击 Xcode 顶部的 **Run** 按钮 (或 Cmd+R)。
3.  应用启动后，点击 "开始使用" 进入计时器页面。
4.  测试功能：
    - 点击播放按钮开始计时。
    - 验证 35秒 (剩余36秒时) 和 25秒 (剩余26秒时) 是否有提示音。
    - 验证 0秒时是否有结束音效。
    - 点击右上角扩展按钮测试横屏/全屏模式。

## 5. 故障排除

- **无声音？**
  - 检查模拟器是否静音。
  - 检查 Xcode 控制台是否有 "Sound file not found" 错误。如果是，请确认音频文件已添加到 Target。
- **布局错乱？**
  - 确保使用的是 iOS 15.0+ 模拟器。

祝您比赛顺利！
