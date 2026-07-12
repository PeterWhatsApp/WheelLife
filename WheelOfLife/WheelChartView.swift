import SwiftUI

/// Interactive polar-area Wheel of Life with curved outer capsules and drag-to-rate.
struct WheelChartView: View {
    let areas: [LifeArea]
    var selectedID: UUID? = nil
    var animated: Bool = true
    var interactive: Bool = false
    var showCapsules: Bool = true
    var onSelect: ((LifeArea) -> Void)? = nil
    var onScoreChange: ((LifeArea, Double) -> Void)? = nil

    @State private var reveal: Double = 0
    @State private var lastHapticScore: Int = -1
    @State private var dragAreaID: UUID?

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxR = size * (showCapsules ? 0.34 : 0.40)
            let labelR = size * 0.455
            let hubR = maxR * 0.18

            ZStack {
                gridLayer(center: center, maxR: maxR)

                ForEach(Array(areas.enumerated()), id: \.element.id) { index, area in
                    segmentFill(
                        area: area,
                        index: index,
                        center: center,
                        maxR: maxR,
                        selected: area.id == selectedID || area.id == dragAreaID
                    )
                }

                hub(center: center, radius: hubR)

                if showCapsules {
                    ForEach(Array(areas.enumerated()), id: \.element.id) { index, area in
                        capsuleLabel(area: area, index: index, center: center, radius: labelR)
                    }
                }

                ringNumbers(center: center, maxR: maxR)
            }
            .contentShape(Circle())
            .gesture(interactive ? dragGesture(center: center, maxR: maxR) : nil)
            .onTapGesture { location in
                guard interactive, let area = area(at: location, center: center) else { return }
                onSelect?(area)
            }
        }
        .onAppear {
            if animated {
                withAnimation(.spring(response: 1.05, dampingFraction: 0.78)) {
                    reveal = 1
                }
            } else {
                reveal = 1
            }
        }
        .onChange(of: areas.map(\.score)) { _, _ in
            if reveal < 1 { reveal = 1 }
        }
    }

    // MARK: - Layers

    private func gridLayer(center: CGPoint, maxR: CGFloat) -> some View {
        Canvas { ctx, _ in
            let n = areas.count
            guard n > 0 else { return }
            let seg = 2 * Double.pi / Double(n)

            for ring in 1...10 {
                let r = maxR * CGFloat(ring) / 10
                var path = Path()
                path.addEllipse(in: CGRect(
                    x: center.x - r,
                    y: center.y - r,
                    width: r * 2,
                    height: r * 2
                ))
                let opacity: Double = ring == 10 ? 0.35 : (ring % 2 == 0 ? 0.18 : 0.10)
                ctx.stroke(
                    path,
                    with: .color(AppTheme.grid.opacity(opacity)),
                    lineWidth: ring == 10 ? 1.4 : 0.7
                )
            }

            for i in 0..<n {
                let a = seg * Double(i) - Double.pi / 2
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(
                    x: center.x + CGFloat(cos(a)) * maxR,
                    y: center.y + CGFloat(sin(a)) * maxR
                ))
                ctx.stroke(path, with: .color(AppTheme.grid.opacity(0.28)), lineWidth: 0.8)
            }
        }
    }

    private func segmentFill(
        area: LifeArea,
        index: Int,
        center: CGPoint,
        maxR: CGFloat,
        selected: Bool
    ) -> some View {
        let n = max(areas.count, 1)
        let seg = 2 * Double.pi / Double(n)
        let gap = 0.012
        let start = seg * Double(index) - Double.pi / 2 + gap
        let end = seg * Double(index + 1) - Double.pi / 2 - gap
        let score = area.score / 10.0 * reveal
        let r = max(2, CGFloat(score) * maxR)

        return SegmentShape(center: center, radius: r, start: start, end: end)
            .fill(
                AngularGradient(
                    colors: [
                        area.color.opacity(selected ? 0.95 : 0.78),
                        area.color.opacity(selected ? 0.72 : 0.55)
                    ],
                    center: .center,
                    startAngle: .radians(start),
                    endAngle: .radians(end)
                )
            )
            .overlay(
                SegmentShape(center: center, radius: r, start: start, end: end)
                    .stroke(area.color.opacity(selected ? 1 : 0.9), lineWidth: selected ? 2.5 : 1.5)
            )
            .shadow(color: selected ? area.color.opacity(0.35) : .clear, radius: selected ? 10 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: area.score)
            .animation(.easeOut(duration: 0.2), value: selected)
    }

    private func hub(center: CGPoint, radius: CGFloat) -> some View {
        let avg = areas.isEmpty ? 0 : areas.map(\.score).reduce(0, +) / Double(areas.count)

        return ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: radius * 2.2, height: radius * 2.2)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)

            Circle()
                .stroke(AppTheme.grid.opacity(0.35), lineWidth: 1)
                .frame(width: radius * 2.2, height: radius * 2.2)

            VStack(spacing: 0) {
                Text(String(format: "%.1f", avg))
                    .font(.system(size: radius * 0.85, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .contentTransition(.numericText())
                Text("avg")
                    .font(.system(size: max(8, radius * 0.28), weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.mutedInk)
                    .textCase(.uppercase)
            }
        }
        .position(center)
    }

    private func capsuleLabel(area: LifeArea, index: Int, center: CGPoint, radius: CGFloat) -> some View {
        let angle = midAngle(index: index)
        let rotation = angle + Double.pi / 2
        let selected = area.id == selectedID || area.id == dragAreaID

        return Text(area.name)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(area.color)
                    .shadow(color: area.color.opacity(selected ? 0.45 : 0.25), radius: selected ? 6 : 3, y: 1)
            )
            .scaleEffect(selected ? 1.08 : 1)
            .rotationEffect(.radians(rotation))
            .position(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            .onTapGesture {
                guard interactive else { return }
                onSelect?(area)
            }
            .animation(.spring(response: 0.3), value: selected)
    }

    private func ringNumbers(center: CGPoint, maxR: CGFloat) -> some View {
        // Numbers along the first radial line for orientation (like the reference).
        ForEach(1...10, id: \.self) { n in
            let r = maxR * CGFloat(n) / 10
            Text("\(n)")
                .font(.system(size: 7, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.mutedInk.opacity(0.55))
                .position(
                    x: center.x + 6,
                    y: center.y - r
                )
        }
    }

    // MARK: - Interaction

    private func dragGesture(center: CGPoint, maxR: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let area = area(at: value.location, center: center) else { return }
                dragAreaID = area.id
                onSelect?(area)

                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                let dist = sqrt(dx * dx + dy * dy)
                let raw = min(10, max(0, (dist / maxR) * 10))
                let score = raw.rounded()

                if Int(score) != lastHapticScore {
                    lastHapticScore = Int(score)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                onScoreChange?(area, score)
            }
            .onEnded { _ in
                dragAreaID = nil
                lastHapticScore = -1
            }
    }

    private func area(at point: CGPoint, center: CGPoint) -> LifeArea? {
        let n = areas.count
        guard n > 0 else { return nil }
        let dx = point.x - center.x
        let dy = point.y - center.y
        var angle = atan2(dy, dx) + Double.pi / 2
        if angle < 0 { angle += 2 * Double.pi }
        let seg = 2 * Double.pi / Double(n)
        let index = Int(angle / seg) % n
        return areas[index]
    }

    private func midAngle(index: Int) -> Double {
        let seg = 2 * Double.pi / Double(max(areas.count, 1))
        return seg * Double(index) + seg / 2 - Double.pi / 2
    }
}

private struct SegmentShape: Shape {
    var center: CGPoint
    var radius: CGFloat
    var start: Double
    var end: Double

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in _: CGRect) -> Path {
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .radians(start),
            endAngle: .radians(end),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}
