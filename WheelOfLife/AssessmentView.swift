import SwiftUI

struct AssessmentView: View {
    @EnvironmentObject var store: WheelStore
    @State private var showBanner = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(store.currentAreas) { area in
                        AreaSliderCard(
                            area: area,
                            onScoreChange: { store.updateScore(for: area, to: $0) },
                            onNotesChange: { store.updateNotes(for: area, to: $0) }
                        )
                    }

                    Button(action: save) {
                        Label("Save Assessment", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.accentColor.gradient)
                            )
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("Rate Your Life")
            .overlay(alignment: .top) {
                if showBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Assessment saved!")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.green.gradient))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 4)
                }
            }
            .animation(.spring(response: 0.4), value: showBanner)
        }
    }

    private func save() {
        store.saveAssessment()
        showBanner = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showBanner = false
        }
    }
}

#Preview {
    AssessmentView()
        .environmentObject(WheelStore())
}

struct AreaSliderCard: View {
    let area: LifeArea
    let onScoreChange: (Double) -> Void
    let onNotesChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(area.name, systemImage: area.icon)
                    .font(.headline)
                    .foregroundStyle(area.color)
                Spacer()
                Text("\(Int(area.score))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(area.color)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: area.score)
            }

            Slider(
                value: Binding(get: { area.score }, set: onScoreChange),
                in: 0...10,
                step: 1
            )
            .tint(area.color)

            HStack {
                Text("Needs Work").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Thriving").font(.caption2).foregroundStyle(.secondary)
            }

            Divider()

            TextField(
                "Add a note…",
                text: Binding(get: { area.notes }, set: onNotesChange),
                axis: .vertical
            )
            .font(.subheadline)
            .foregroundStyle(.primary)
            .lineLimit(2...5)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}
