import SwiftUI

struct AssessmentView: View {
    @EnvironmentObject var store: WheelStore
    @State private var showBanner = false
    @State private var guidedMode = false

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        modePicker

                        if guidedMode {
                            GuidedRatingCarousel()
                        } else {
                            ForEach(store.activeAreas) { area in
                                AreaSliderCard(
                                    area: area,
                                    onScoreChange: { store.updateScore(for: area, to: $0) },
                                    onNotesChange: { store.updateNotes(for: area, to: $0) }
                                )
                            }
                        }

                        Button(action: save) {
                            Label("Save assessment", systemImage: "checkmark.circle.fill")
                                .font(.system(.headline, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#E91E8C"), Color(hex: "#8E24AA")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        .padding(.top, 6)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Rate")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .top) {
                if showBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Assessment saved")
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color(hex: "#43A047").gradient))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
                }
            }
            .animation(.spring(response: 0.4), value: showBanner)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $guidedMode) {
            Text("All areas").tag(false)
            Text("One at a time").tag(true)
        }
        .pickerStyle(.segmented)
    }

    private func save() {
        store.saveAssessment()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showBanner = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            showBanner = false
        }
    }
}

struct GuidedRatingCarousel: View {
    @EnvironmentObject var store: WheelStore
    @State private var index = 0

    private var areas: [LifeArea] { store.activeAreas }

    var body: some View {
        VStack(spacing: 16) {
            if areas.indices.contains(index) {
                let area = areas[index]

                Text("\(index + 1) of \(areas.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.mutedInk)

                AreaSliderCard(
                    area: area,
                    onScoreChange: { store.updateScore(for: area, to: $0) },
                    onNotesChange: { store.updateNotes(for: area, to: $0) }
                )
                .id(area.id)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                HStack {
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            index = max(0, index - 1)
                        }
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                    .disabled(index == 0)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            index = min(areas.count - 1, index + 1)
                        }
                    } label: {
                        Label(index == areas.count - 1 ? "Done" : "Next", systemImage: "chevron.right")
                            .labelStyle(.titleAndIcon)
                    }
                    .disabled(index >= areas.count - 1)
                    .buttonStyle(.borderedProminent)
                    .tint(area.color)
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .onChange(of: areas.count) { _, _ in
            index = min(index, max(0, areas.count - 1))
        }
    }
}

struct AreaSliderCard: View {
    let area: LifeArea
    let onScoreChange: (Double) -> Void
    let onNotesChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(area.name, systemImage: area.icon)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(area.color)
                Spacer()
                Text("\(Int(area.score))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(area.color)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: area.score)
            }

            // Score dots for a more tactile feel than a bare slider alone.
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { n in
                    Circle()
                        .fill(Double(n) <= area.score ? area.color : area.color.opacity(0.15))
                        .frame(height: 8)
                        .onTapGesture {
                            UISelectionFeedbackGenerator().selectionChanged()
                            onScoreChange(Double(n))
                        }
                }
            }

            Slider(
                value: Binding(get: { area.score }, set: onScoreChange),
                in: 0...10,
                step: 1
            )
            .tint(area.color)

            HStack {
                Text("Needs work").font(.caption2).foregroundStyle(.secondary)
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
            .lineLimit(2...5)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
        )
    }
}

#Preview {
    AssessmentView()
        .environmentObject(WheelStore())
}
