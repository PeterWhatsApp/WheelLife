import SwiftUI

let appVersion = "1.0c"

struct ContentView: View {
    @StateObject private var store = WheelStore()

    var body: some View {
        TabView {
            WheelTab()
                .tabItem { Label("Wheel", systemImage: "chart.pie.fill") }
            AssessmentView()
                .tabItem { Label("Rate", systemImage: "slider.horizontal.3") }
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .environmentObject(store)
    }
}

struct WheelTab: View {
    @EnvironmentObject var store: WheelStore

    private var average: Double {
        guard !store.currentAreas.isEmpty else { return 0 }
        return store.currentAreas.map(\.score).reduce(0, +) / Double(store.currentAreas.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    WheelChartView(areas: store.currentAreas)
                        .frame(height: 340)
                        .padding(.horizontal, 8)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 4),
                        spacing: 12
                    ) {
                        ForEach(store.currentAreas) { area in
                            VStack(spacing: 4) {
                                Image(systemName: area.icon)
                                    .foregroundStyle(area.color)
                                Text("\(Int(area.score))")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundStyle(area.color)
                                Text(area.name)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(area.color.opacity(0.12))
                            )
                        }
                    }
                    .padding(.horizontal)

                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .stroke(.quaternary, lineWidth: 8)
                            Circle()
                                .trim(from: 0, to: average / 10)
                                .stroke(
                                    AngularGradient(
                                        gradient: Gradient(colors: [.red, .orange, .yellow, .green, .cyan]),
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 1.0), value: average)
                        }
                        .frame(width: 80, height: 80)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Overall Balance")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1f / 10", average))
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text(balanceLabel(average))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.background)
                            .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Wheel of Life")
        }
    }

    private func balanceLabel(_ score: Double) -> String {
        if score < 3 { return "Needs significant attention" }
        if score < 5 { return "Room to grow" }
        if score < 7 { return "On the right track" }
        if score < 9 { return "Living well" }
        return "Exceptional balance"
    }
}

#Preview {
    ContentView()
}
