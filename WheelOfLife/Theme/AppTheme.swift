import SwiftUI

enum AppTheme {
    static let backgroundTop = Color(hex: "#F4F6FA")
    static let backgroundBottom = Color(hex: "#E8EDF5")
    static let ink = Color(hex: "#1A1F2E")
    static let mutedInk = Color(hex: "#6B7285")
    static let card = Color.white
    static let grid = Color(hex: "#9AA3B5")
    static let hub = Color(hex: "#EEF1F6")

    static var pageBackground: some View {
        LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct AtmosphereBackground: View {
    var body: some View {
        ZStack {
            AppTheme.pageBackground

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#FF6B9D").opacity(0.12),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 420, height: 420)
                .offset(x: -90, y: -180)
                .blur(radius: 8)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#4C8DFF").opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 240
                    )
                )
                .frame(width: 460, height: 460)
                .offset(x: 120, y: 260)
                .blur(radius: 10)
        }
    }
}
