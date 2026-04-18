# VEXHelper 远程控制功能增强计划 (修订版)

根据您的最新指示，明确了音频控制的独立性。

## 1. 修复重置同步问题
- **修复**：在 `TimerEngine.reset()` 方法末尾显式调用 `broadcastState()`，确保重置操作即时同步到 Web 端。

## 2. 音频控制逻辑细化 (Audio Logic)
- **本地计时器 (Timer Tab)**：完全独立，仅受本地静音按钮控制，**不**受“仅远程音频”开关影响。
- **远程控制器 (Web Controller)**：
  - 受“仅远程音频”开关控制（决定声音是从手机出还是 Web 出）。
  - 新增“全局静音”按钮：点击后发送指令让 Web 端静音，同时手机端（如果在播放）也静音。

## 3. IPv6 与网络状态显示优化
- **IPv6 支持**：`LocalNetworkService` 识别 IPv6 地址并在 URL 中添加 `[]` 包裹。
- **Wi-Fi 检测**：当无有效 IP 时，提示“未连接 Wi-Fi”。

## 4. Web 端多语言修复
- **强制同步**：在 `RemoteControlManager` 初始化及连接建立时，强制发送一次当前的语言设置指令，确保 Web 端在任何时候连接都能获得正确语言。

## 5. 实施步骤
1.  **TimerEngine**: 修复 `reset` 广播。
2.  **LocalNetworkService**: 优化 IP 获取与格式化。
3.  **RemoteControlManager**: 添加 `toggleMute()` 功能，发送 `{ "type": "toggleMute" }` 指令。
4.  **WebAssets**: 更新 `app.js` 处理静音指令。
5.  **WebControlView**: 添加静音按钮，并显示当前静音状态。

请确认此计划。