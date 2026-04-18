# Web 界面动态进度环绕边框实现计划

根据您的要求，我们将 Web 界面升级为模拟 App 端横屏计时器 (`HorizontalTimerNumber.swift`) 的效果：边框不仅变粗，还要作为进度条随着时间减少而缩短。

## 1. 技术方案 (SVG Animation)
由于 CSS `border` 无法直接实现“环绕缩短”的动画效果，我们将采用 **SVG** 技术来实现。
- **背景层**：一个半透明蓝色的圆角矩形描边 (`stroke`)，作为底色。
- **进度层**：一个高亮蓝色的圆角矩形描边，利用 `stroke-dasharray` 和 `stroke-dashoffset` 属性来控制显示的长度。
- **自适应**：SVG 将铺满全屏，内部矩形通过 `width="100%" height="100%"` 和 `rx` (圆角) 自适应。

## 2. 样式调整 (CSS Updates)
- **移除 CSS Border**：删除 `body` 上的 `border` 属性。
- **SVG 容器**：创建一个绝对定位的 SVG 容器，覆盖全屏。
- **字体调整**：将时间字体大小从 `35vw` 减小到 `30vw` (或更合适的值)。

## 3. 逻辑更新 (JavaScript Updates)
- **计算周长**：在窗口大小改变 (`resize`) 时，动态计算矩形的总周长 (Perimeter)。
- **更新进度**：在收到 `update` 消息时，根据 `msg.progress` 计算 `stroke-dashoffset`。
  - `offset = perimeter * (1 - progress)`
- **颜色同步**：根据状态 (`running`/`paused`/`stopped`) 改变进度条颜色（可选，保持与 App 一致）。

## 4. 实施步骤
1.  **修改 `index.html`**：插入 SVG 结构。
2.  **修改 `style.css`**：移除旧边框，添加 SVG 样式，调整字体。
3.  **修改 `app.js`**：实现 SVG 路径长度计算和进度更新逻辑。

请确认此计划。