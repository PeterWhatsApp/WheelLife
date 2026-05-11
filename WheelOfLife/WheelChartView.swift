import SwiftUI

struct WheelChartView: View {
    let areas: [LifeArea]
    var animated: Bool = true

    @State private var progress: Double = 0

    var body: some View {
        GeometryReader { geo in
            let minDim  = min(geo.size.width, geo.size.height)
            let center  = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxR    = minDim * 0.36
            let labelR  = minDim * 0.462

            ZStack {
                Canvas { ctx, _ in
                    drawWeb(ctx: ctx, center: center, maxRadius: maxR)
                }

                Canvas { ctx, _ in
                    drawWheel(ctx: ctx, center: center, maxRadius: maxR, progress: progress)
                }

                ForEach(Array(areas.enumerated()), id: \.element.id) { i, area in
                    let angle = midAngle(index: i)
                    VStack(spacing: 2) {
                        Image(systemName: area.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(area.name)
                            .font(.system(size: 9, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundStyle(area.color)
                    .frame(width: 58)
                    .position(
                        x: center.x + CGFloat(cos(angle)) * labelR,
                        y: center.y + CGFloat(sin(angle)) * labelR
                    )
                }
            }
        }
        .onAppear {
            if animated {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.75)) {
                    progress = 1.0
                }
            } else {
                progress = 1.0
            }
        }
    }

    private func midAngle(index: Int) -> Double {
        let seg = 2 * Double.pi / Double(areas.count)
        return seg * Double(index) + seg / 2 - Double.pi / 2
    }

    private func drawWeb(ctx: GraphicsContext, center: CGPoint, maxRadius: CGFloat) {
        let n = areas.count
        guard n > 0 else { return }
        let seg = 2 * Double.pi / Double(n)

        for ring in 1...5 {
            let r = maxRadius * CGFloat(ring) / 5
            var path = Path()
            for i in 0..<n {
                let a = seg * Double(i) - Double.pi / 2
                let pt = CGPoint(x: center.x + CGFloat(cos(a)) * r,
                                 y: center.y + CGFloat(sin(a)) * r)
                i == 0 ? path.move(to: pt) : path.addLine(to: pt)
            }
            path.closeSubpath()
            let opacity: Double = ring == 5 ? 0.3 : 0.15
            ctx.stroke(path, with: .color(.primary.opacity(opacity)),
                       lineWidth: ring == 5 ? 1.5 : 0.8)
        }

        for i in 0..<n {
            let a = seg * Double(i) - Double.pi / 2
            var path = Path()
            path.move(to: center)
            path.addLine(to: CGPoint(x: center.x + CGFloat(cos(a)) * maxRadius,
                                     y: center.y + CGFloat(sin(a)) * maxRadius))
            ctx.stroke(path, with: .color(.primary.opacity(0.15)), lineWidth: 0.8)
        }
    }

    private func drawWheel(ctx: GraphicsContext, center: CGPoint,
                            maxRadius: CGFloat, progress: Double) {
        let n = areas.count
        guard n > 0 else { return }
        let seg  = 2 * Double.pi / Double(n)
        let gap  = 0.04

        for (i, area) in areas.enumerated() {
            let start = seg * Double(i)     - Double.pi / 2 + gap
            let end   = seg * Double(i + 1) - Double.pi / 2 - gap
            let r: CGFloat = max(1.5, CGFloat(area.score / 10.0 * progress) * maxRadius)

            var fill = Path()
            fill.move(to: center)
            fill.addArc(center: center, radius: r,
                        startAngle: .init(radians: start),
                        endAngle:   .init(radians: end),
                        clockwise: false)
            fill.closeSubpath()
            ctx.fill(fill, with: .color(area.color.opacity(0.72)))

            var arc = Path()
            arc.addArc(center: center, radius: r,
                       startAngle: .init(radians: start),
                       endAngle:   .init(radians: end),
                       clockwise: false)
            ctx.stroke(arc, with: .color(area.color), lineWidth: 2.5)
        }
    }
}
