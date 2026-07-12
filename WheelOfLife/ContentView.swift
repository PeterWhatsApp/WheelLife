import SwiftUI

let appVersion = "1.0"

struct ContentView: View {
    @StateObject private var store = WheelStore()
    @StateObject private var reminders = ReminderScheduler.shared

    var body: some View {
        Group {
            if store.hasCompletedOnboarding {
                mainTabs
            } else {
                OnboardingView()
            }
        }
        .environmentObject(store)
        .environmentObject(reminders)
        .tint(Color(hex: "#E91E8C"))
        .task {
            await reminders.refreshAuthorization()
            await reminders.rescheduleIfNeeded()
        }
    }

    private var mainTabs: some View {
        TabView {
            WheelHomeView()
                .tabItem { Label("Wheel", systemImage: "circle.grid.cross.fill") }

            AssessmentView()
                .tabItem { Label("Rate", systemImage: "slider.horizontal.3") }

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

struct WheelHomeView: View {
    @EnvironmentObject var store: WheelStore
    @State private var showSaved = false
    @State private var shareImage: ShareImage?

    private var focusAreas: [LifeArea] {
        guard let min = store.activeAreas.map(\.score).min() else { return [] }
        return store.activeAreas.filter { $0.score == min }
    }

    private var strengthAreas: [LifeArea] {
        guard let max = store.activeAreas.map(\.score).max() else { return [] }
        return store.activeAreas.filter { $0.score == max }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        wheelCard
                        selectedEditor
                        insightRow
                        saveButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Life Planning Wheel")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(AppTheme.ink)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if let shareImage {
                        ShareLink(
                            item: shareImage,
                            preview: SharePreview("My Life Planning Wheel", image: Image(uiImage: shareImage.image))
                        ) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            prepareShare()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
            .task(id: store.activeAreas) {
                prepareShare()
            }
            .overlay(alignment: .top) {
                if showSaved {
                    toast("Snapshot saved")
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: showSaved)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text("Drag any segment to rate. Tap a label to focus.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var wheelCard: some View {
        VStack(spacing: 0) {
            WheelChartView(
                areas: store.activeAreas,
                selectedID: store.selectedAreaID,
                interactive: true,
                onSelect: { store.selectArea($0) },
                onScoreChange: { area, score in
                    store.updateScore(for: area, to: score)
                }
            )
            .frame(height: 380)
            .padding(.vertical, 8)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Overall balance")
                        .font(.caption)
                        .foregroundStyle(AppTheme.mutedInk)
                    Text(String(format: "%.1f", store.average))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .contentTransition(.numericText())
                }
                Spacer()
                Text(store.balanceLabel(store.average))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(AppTheme.hub))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.06), radius: 20, y: 8)
        )
    }

    @ViewBuilder
    private var selectedEditor: some View {
        if let area = store.selectedArea {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: area.icon)
                        .foregroundStyle(area.color)
                    Text(area.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                    Spacer()
                    Text("\(Int(area.score))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(area.color)
                        .contentTransition(.numericText())
                }

                Slider(
                    value: Binding(
                        get: { area.score },
                        set: { store.updateScore(for: area, to: $0) }
                    ),
                    in: 0...10,
                    step: 1
                )
                .tint(area.color)

                TextField(
                    "What’s true for \(area.name.lowercased()) right now?",
                    text: Binding(
                        get: { area.notes },
                        set: { store.updateNotes(for: area, to: $0) }
                    ),
                    axis: .vertical
                )
                .font(.subheadline)
                .lineLimit(2...4)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: .black.opacity(0.05), radius: 14, y: 6)
            )
        }
    }

    private var insightRow: some View {
        HStack(spacing: 12) {
            insightCard(
                title: "Focus",
                subtitle: focusAreas.map(\.name).prefix(2).joined(separator: ", "),
                tint: focusAreas.first?.color ?? .orange,
                icon: "arrow.down.right.circle.fill"
            )
            insightCard(
                title: "Strength",
                subtitle: strengthAreas.map(\.name).prefix(2).joined(separator: ", "),
                tint: strengthAreas.first?.color ?? .green,
                icon: "arrow.up.right.circle.fill"
            )
        }
    }

    private func insightCard(title: String, subtitle: String, tint: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(subtitle.isEmpty ? "—" : subtitle)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
        )
    }

    private var saveButton: some View {
        Button {
            store.saveAssessment()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showSaved = true
            Task {
                try? await Task.sleep(for: .seconds(1.8))
                showSaved = false
            }
        } label: {
            Label("Save snapshot", systemImage: "checkmark.circle.fill")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#E91E8C"), Color(hex: "#8E24AA")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func toast(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text(text)
        }
        .font(.subheadline.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(Capsule().fill(Color(hex: "#43A047").gradient))
    }

    private func prepareShare() {
        guard let image = WheelShareRenderer.render(
            areas: store.activeAreas,
            average: store.average,
            focus: store.focusName,
            strength: store.strengthName
        ) else { return }
        shareImage = ShareImage(image: image)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }
}

#Preview {
    ContentView()
}
