import WidgetKit
import SwiftUI

@main
struct WheelOfLifeWidgetBundle: WidgetBundle {
    var body: some Widget {
        WheelBalanceWidget()
    }
}

struct WheelBalanceWidget: Widget {
    let kind = "WheelBalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WheelTimelineProvider()) { entry in
            WheelWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(widgetHex: "#F4F6FA"),
                            Color(widgetHex: "#E8EDF5")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Wheel of Life")
        .description("See your balance average and focus area at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WheelTimelineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct WheelTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WheelTimelineEntry {
        WheelTimelineEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (WheelTimelineEntry) -> Void) {
        completion(WheelTimelineEntry(date: Date(), snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WheelTimelineEntry>) -> Void) {
        let entry = WheelTimelineEntry(date: Date(), snapshot: WidgetSnapshot.load())
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct WheelWidgetEntryView: View {
    var entry: WheelTimelineEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumLayout
        default:
            smallLayout
        }
    }

    private var smallLayout: some View {
        VStack(spacing: 6) {
            MiniWheelView(areas: entry.snapshot.areas)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                Text(String(format: "%.1f", entry.snapshot.average))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Spacer()
                Text(entry.snapshot.focus)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
    }

    private var mediumLayout: some View {
        HStack(spacing: 16) {
            MiniWheelView(areas: entry.snapshot.areas)
                .frame(width: 120, height: 120)

            VStack(alignment: .leading, spacing: 8) {
                Text("Balance")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f", entry.snapshot.average))
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Label(entry.snapshot.focus, systemImage: "arrow.down.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(widgetHex: "#E53935"))
                    .lineLimit(1)

                Label(entry.snapshot.strength, systemImage: "arrow.up.right.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(widgetHex: "#43A047"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
    }
}

struct MiniWheelView: View {
    let areas: [WidgetAreaSnapshot]

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxR = min(size.width, size.height) * 0.46
            let n = max(areas.count, 1)
            let seg = 2 * Double.pi / Double(n)

            for ring in 1...5 {
                let r = maxR * CGFloat(ring) / 5
                var path = Path()
                path.addEllipse(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2))
                context.stroke(path, with: .color(.gray.opacity(0.2)), lineWidth: 0.6)
            }

            for (index, area) in areas.enumerated() {
                let start = seg * Double(index) - Double.pi / 2 + 0.02
                let end = seg * Double(index + 1) - Double.pi / 2 - 0.02
                let r = max(2, CGFloat(area.score / 10) * maxR)
                var fill = Path()
                fill.move(to: center)
                fill.addArc(
                    center: center,
                    radius: r,
                    startAngle: .radians(start),
                    endAngle: .radians(end),
                    clockwise: false
                )
                fill.closeSubpath()
                context.fill(fill, with: .color(Color(widgetHex: area.colorHex).opacity(0.8)))
            }

            let hub = maxR * 0.16
            var hubPath = Path()
            hubPath.addEllipse(in: CGRect(x: center.x - hub, y: center.y - hub, width: hub * 2, height: hub * 2))
            context.fill(hubPath, with: .color(.white.opacity(0.95)))
        }
    }
}

#Preview(as: .systemSmall) {
    WheelBalanceWidget()
} timeline: {
    WheelTimelineEntry(date: .now, snapshot: .placeholder)
}
