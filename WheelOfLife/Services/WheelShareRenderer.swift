import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct WheelShareCard: View {
    let areas: [LifeArea]
    let average: Double
    let focus: String
    let strength: String

    var body: some View {
        VStack(spacing: 18) {
            Text("Life Planning Wheel")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            WheelChartView(
                areas: areas,
                animated: false,
                interactive: false,
                showCapsules: true
            )
            .frame(height: 340)

            HStack(spacing: 16) {
                shareStat(title: "Average", value: String(format: "%.1f", average))
                shareStat(title: "Focus", value: focus)
                shareStat(title: "Strength", value: strength)
            }

            Text(Date.now.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(24)
        .frame(width: 390, height: 520)
        .background(
            LinearGradient(
                colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private func shareStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppTheme.card.opacity(0.9))
        )
    }
}

enum WheelShareRenderer {
    @MainActor
    static func render(
        areas: [LifeArea],
        average: Double,
        focus: String,
        strength: String
    ) -> UIImage? {
        let card = WheelShareCard(
            areas: areas,
            average: average,
            focus: focus,
            strength: strength
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage
    }
}

struct ShareImage: Transferable {
    let image: UIImage

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { share in
            share.image.pngData() ?? Data()
        }
    }
}
