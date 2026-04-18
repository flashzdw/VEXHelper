# 1. 问题

计时器模块把“状态到按钮集合到动作语义”的核心交互规则直接写进多个 SwiftUI 片段。当前至少分散在 `VEXHelper/TimerGroup/TimerPage.swift:78-109`、`VEXHelper/TimerGroup/TimerPage.swift:147-177` 和 `VEXHelper/TimerGroup/WebControlView.swift:70-98`，同一规则需要三处同步维护。

## 1.1. **状态映射分散**

`TimerPage` 的竖屏和全屏视图各自维护一套 `switch timerCenter.status`，`WebControlView` 又复制了一套 `switch timerEngine.status`。三处代码只在按钮尺寸、排列方向上不同，状态到图标和动作的映射完全一致。

```swift
switch timerCenter.status {
case .idle:
    controlButton(iconName: "play.fill") { timerCenter.start() }
case .running:
    controlButton(iconName: "pause.fill") { timerCenter.pause() }
    controlButton(iconName: "square.fill") { timerCenter.stop() }
case .paused:
    controlButton(iconName: "xmark") { timerCenter.reset() }
    controlButton(iconName: "play.fill") { timerCenter.start() }
case .stopped:
    controlButton(iconName: "arrow.triangle.2.circlepath") { timerCenter.reset() }
}
```

修改按钮顺序、图标或新增状态时，开发者必须跨三个视图同时改动。只要漏掉一处，就会出现竖屏、全屏和 Web 控制端行为不一致的问题。

## 1.2. **交互语义没有独立模型**

当前 UI 同时负责“显示什么按钮”和“点了调用哪个引擎方法”。例如 `paused` 场景里显示继续按钮，但实际调用仍是 `start()`。这不是立即的 bug，但语义被埋在视图分支里，后续如果要区分“首次开始”和“继续计时”，只能再去多个页面翻 `switch`。

# 2. 收益

把控制规则收敛成单一事实来源后，计时器的核心交互会从“分散在三个页面的 UI 细节”变成“可复用、可测试的领域规则”。

## 2.1. **减少重复修改点**

状态映射可以从 **3 处 switch** 收敛到 **1 处规则表**。以后新增状态或调整按钮顺序时，核心改动集中在一个文件，页面只负责布局和样式。

## 2.2. **降低行为不一致风险**

竖屏、全屏、Web 控制端共享同一份规则后，能直接消除“某个端漏改一处”的典型风险。回归时也更容易把注意力放在状态切换本身，而不是逐个检查 UI 分支是否同步。

## 2.3. **提升可测试性**

提取 `TimerControlAction` 和 `TimerControlRule` 后，可以直接对 `idle`、`running`、`paused`、`stopped` 做映射测试，不必每次都通过 SwiftUI 渲染验证按钮结果。测试粒度会从页面级下降到规则级，成本更低。

# 3. 方案

建议把“状态映射”和“动作分发”从页面里抽离出来，保留页面只处理布局差异，形成“共享规则 + 通用按钮面板 + 引擎协议”的轻量结构。

## 3.1. **抽取共享控制规则：解决“状态映射分散”**

方案概述：新增 `TimerControlAction`、`TimerControlRule` 和复用按钮面板，统一描述按钮图标、顺序和动作语义；`TimerPage` 与 `WebControlView` 只消费规则结果。

实施步骤：

* 定义 `TimerControlAction`，显式区分 `start`、`resume`、`pause`、`stop`、`reset`。

* 定义 `TimerControlRule.items(for:)`，集中维护 `TimerStatus` 到按钮列表的映射。

* 让 `PhoneTimerEngine` 和 `WebTimerEngine` 遵循同一控制协议，并提供 `perform(_:)`。

* 抽出 `TimerControlButtons` 组件，参数化按钮大小、间距、旋转角度和阴影，保留三种页面的展示差异。

修改后：

```swift
enum TimerControlAction: Hashable {
    case start, resume, pause, stop, reset

    var iconName: String {
        switch self {
        case .start, .resume: return "play.fill"
        case .pause: return "pause.fill"
        case .stop: return "square.fill"
        case .reset: return "arrow.triangle.2.circlepath"
        }
    }
}

enum TimerControlRule {
    static func items(for status: TimerStatus) -> [TimerControlAction] {
        switch status {
        case .idle: return [.start]
        case .running: return [.pause, .stop]
        case .paused: return [.reset, .resume]
        case .stopped: return [.reset]
        }
    }
}

protocol TimerControlEngine: ObservableObject {
    var status: TimerStatus { get }
    func perform(_ action: TimerControlAction)
}
```

```swift
ForEach(TimerControlRule.items(for: timerEngine.status), id: \.self) { action in
    controlButton(iconName: action.iconName) {
        timerEngine.perform(action)
    }
}
```

这样做以后，页面只负责“横着摆还是竖着摆、按钮多大、是否旋转”，不再负责判断状态分支。规则变更只需要修改 `TimerControlRule` 和 `perform(_:)`。

## 3.2. **引入动作语义层：解决“交互语义没有独立模型”**

不要让页面直接知道 `paused` 时是不是继续调用 `start()`。页面只表达用户意图，例如“继续”，具体落到 `start()` 还是未来的 `resume()`，由引擎协议或适配层决定。

这个动作语义层很轻，但价值很直接。它把“用户点的是什么”与“底层怎么执行”分开了。前者是产品规则，后者是实现细节，分开后更容易演进。

# 4. 回归范围

这次调整主要影响计时器控制入口的一致性。回归重点不是某个 SwiftUI 函数有没有被调用，而是同一状态在不同界面里是否呈现相同按钮、触发相同行为。

## 4.1. 主链路

* 手机竖屏进入计时页面，验证 `idle -> running -> paused -> running -> stopped -> idle` 的完整流程，重点检查每个状态下按钮数量、顺序、图标和点击结果。

* 从竖屏切到全屏后继续操作，确认同一状态下按钮集合不变，只允许布局和旋转样式不同。

* 进入 Web 控制端，重复同一套状态流转，确认与手机端行为一致。

## 4.2. 边界情况

* 计时运行中自然结束，确认自动进入 `stopped` 后只展示重置入口，不出现暂停或停止按钮残留。

* 在 `paused` 状态下连续切换页面或反复进入全屏，确认“继续”按钮始终存在，且点击后恢复计时而不是重置。

* 后续如果新增状态，例如预备态或完成态，优先回归 `TimerControlRule` 的映射测试，再覆盖三个界面的呈现结果。

