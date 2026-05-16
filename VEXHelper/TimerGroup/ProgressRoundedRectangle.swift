import SwiftUI

/// 自定义倒计时进度圆环形状
/// 保证从顶部中间开始，并逆时针绘制
struct ProgressRoundedRectangle: Shape {
    var cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        let r = min(cornerRadius, min(w/2, h/2))
        
        // 起点：顶部居中
        path.move(to: CGPoint(x: w/2, y: 0))
        
        // 顶部向左画线
        path.addLine(to: CGPoint(x: r, y: 0))
        
        // 左上角圆弧 (从 -90度(顶部) 到 180度(左侧))
        // 在 SwiftUI 坐标系中（Y朝下），从顶部(-90)到左侧(180)是逆时针
        // clockwise: true 表示视觉上的逆时针（按照数学坐标系是顺时针）
        path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(-90), endAngle: .degrees(180), clockwise: true)
        
        // 左侧向下画线
        path.addLine(to: CGPoint(x: 0, y: h - r))
        
        // 左下角圆弧 (从 180度(左侧) 到 90度(底部))
        path.addArc(center: CGPoint(x: r, y: h - r), radius: r, startAngle: .degrees(180), endAngle: .degrees(90), clockwise: true)
        
        // 底部向右画线
        path.addLine(to: CGPoint(x: w - r, y: h))
        
        // 右下角圆弧 (从 90度(底部) 到 0度(右侧))
        path.addArc(center: CGPoint(x: w - r, y: h - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(0), clockwise: true)
        
        // 右侧向上画线
        path.addLine(to: CGPoint(x: w, y: r))
        
        // 右上角圆弧 (从 0度(右侧) 到 -90度(顶部))
        path.addArc(center: CGPoint(x: w - r, y: r), radius: r, startAngle: .degrees(0), endAngle: .degrees(-90), clockwise: true)
        
        // 闭合路径，回到顶部居中
        path.addLine(to: CGPoint(x: w/2, y: 0))
        
        return path
    }
}
