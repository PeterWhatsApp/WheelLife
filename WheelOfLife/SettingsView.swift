import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: WheelStore
    @State private var showResetConfirm = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "chart.pie.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.tint)
                            Text("Wheel of Life")
                                .font(.title2.bold())
                            Text("Version \(appVersion)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(.quaternary))
                        }
                        .padding(.vertical, 12)
                        Spacer()
                    }
                }

                Section("Life Areas") {
                    ForEach(store.currentAreas) { area in
                        HStack {
                            Image(systemName: area.icon)
                                .foregroundStyle(area.color)
                                .frame(width: 24)
                            Text(area.name)
                            Spacer()
                            Text("\(Int(area.score)) / 10")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showResetConfirm = true
                    } label: {
                        Label("Reset All Scores", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Reset all scores to 5?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    for area in store.currentAreas {
                        store.updateScore(for: area, to: 5)
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WheelStore())
}
