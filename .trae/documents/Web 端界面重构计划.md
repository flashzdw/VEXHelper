# Web 界面样式重构计划

根据您的要求，我将把 Web 端界面重构为与手机端横屏计时器一致的风格。

## 1. 样式重构 (CSS Refactoring)
- **边框 (Border)**：添加环绕屏幕的蓝色边框。
  - `border: 20px solid #007AFF;` (iOS Blue)
  - `border-radius: 40px;` (匹配手机屏幕圆角)
  - `box-sizing: border-box;` 确保边框包含在视口内。
- **背景 (Background)**：
  - 移除渐变背景，使用纯色深灰 `#1c1c1e` (匹配 App 的 `darkGray`)。
- **布局 (Layout)**：
  - 移除 `.glass-panel` (磨砂玻璃面板) 容器，改为全屏显示。
  - 移除 `.container` 的宽度限制，内容直接居中。
- **文字 (Typography)**：
  - 极大化计时器字体 (`font-size: 35vw`)，使其尽可能充满屏幕。
  - 移除或隐藏 `.status-indicator` (状态文字) 和 `.progress-container` (进度条)，以保持界面纯净（根据参考图）。
- **交互**：
  - 保持 `#overlay` (点击连接层) 不变，但优化其样式以匹配新风格。

## 2. 结构调整 (HTML Updates)
- 简化 DOM 结构，可能移除不再需要的容器标签，或仅保留用于定位的最小结构。
- 隐藏 `status` 和 `progress` 元素（通过 CSS `display: none`），保留它们在 DOM 中以防逻辑报错，或在 `app.js` 中做相应兼容。

## 3. 实施步骤
1.  **修改 `style.css`**：重写 `body` 和 `.timer-display` 样式，隐藏多余元素。
2.  **验证**：确保在浏览器窗口缩放时，边框和文字自适应良好。

请确认此计划。