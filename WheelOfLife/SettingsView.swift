import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: WheelStore
    @EnvironmentObject var reminders: ReminderScheduler
    @State private var showResetConfirm = false
    @State private var showTemplateConfirm: WheelTemplate?
    @State private var reminderTime = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                List {
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "#E91E8C"), Color(hex: "#3949AB")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 72, height: 72)
                                    Image(systemName: "circle.grid.cross.fill")
                                        .font(.system(size: 30))
                                        .foregroundStyle(.white)
                                }
                                Text("Wheel of Life")
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                Text("Version \(appVersion)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(.quaternary))
                            }
                            .padding(.vertical, 8)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    }

                    Section {
                        Toggle("Reassessment reminders", isOn: Binding(
                            get: { reminders.isEnabled },
                            set: { newValue in
                                reminders.isEnabled = newValue
                                Task { await reminders.applySettings() }
                            }
                        ))

                        if reminders.isEnabled {
                            Picker("Frequency", selection: $reminders.frequency) {
                                ForEach(ReminderFrequency.allCases) { frequency in
                                    Text(frequency.title).tag(frequency)
                                }
                            }
                            .onChange(of: reminders.frequency) { _, _ in
                                Task { await reminders.applySettings() }
                            }

                            if reminders.frequency != .monthly {
                                Picker("Day", selection: $reminders.weekday) {
                                    ForEach(1...7, id: \.self) { day in
                                        Text(weekdayName(day)).tag(day)
                                    }
                                }
                                .onChange(of: reminders.weekday) { _, _ in
                                    Task { await reminders.applySettings() }
                                }
                            }

                            DatePicker(
                                "Time",
                                selection: $reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .onChange(of: reminderTime) { _, newValue in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                reminders.hour = components.hour ?? 10
                                reminders.minute = components.minute ?? 0
                                Task { await reminders.applySettings() }
                            }
                        }
                    } header: {
                        Text("Reminders")
                    } footer: {
                        Text("Optional nudges to re-rate your wheel. Notifications stay on-device.")
                    }

                    Section {
                        ForEach(WheelTemplate.allCases) { template in
                            Button {
                                showTemplateConfirm = template
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.rawValue)
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .foregroundStyle(AppTheme.ink)
                                    Text(template.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.mutedInk)
                                }
                            }
                        }
                    } header: {
                        Text("Templates")
                    } footer: {
                        Text("Switching templates replaces your current categories and scores.")
                    }

                    Section("Life areas") {
                        ForEach(store.currentAreas) { area in
                            Toggle(isOn: Binding(
                                get: { area.isEnabled },
                                set: { store.setEnabled($0, for: area) }
                            )) {
                                HStack {
                                    Image(systemName: area.icon)
                                        .foregroundStyle(area.color)
                                        .frame(width: 24)
                                    Text(area.name)
                                    Spacer()
                                    Text("\(Int(area.score))")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline.monospacedDigit())
                                }
                            }
                            .tint(area.color)
                        }
                    }

                    Section {
                        Label("Add the Home Screen widget from today view for a live balance glance.", systemImage: "rectangle.on.rectangle")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.mutedInk)
                    } header: {
                        Text("Widget")
                    }

                    Section {
                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            Label("Reset scores to 5", systemImage: "arrow.counterclockwise")
                        }
                    }

                    Section("About") {
                        LabeledContent("Privacy", value: "On-device only")
                        LabeledContent("Built with", value: "SwiftUI + WidgetKit")
                        Text("Your ratings never leave this iPhone — no account, no cloud.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .onAppear {
                var components = DateComponents()
                components.hour = reminders.hour
                components.minute = reminders.minute
                reminderTime = Calendar.current.date(from: components) ?? Date()
            }
            .confirmationDialog(
                "Reset all scores to 5?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    store.resetScores(to: 5)
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog(
                "Apply \(showTemplateConfirm?.rawValue ?? "template")?",
                isPresented: Binding(
                    get: { showTemplateConfirm != nil },
                    set: { if !$0 { showTemplateConfirm = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Replace categories", role: .destructive) {
                    if let template = showTemplateConfirm {
                        store.applyTemplate(template)
                    }
                    showTemplateConfirm = nil
                }
                Button("Cancel", role: .cancel) {
                    showTemplateConfirm = nil
                }
            } message: {
                Text("This replaces your current life areas and scores.")
            }
        }
    }

    private func weekdayName(_ day: Int) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = max(0, min(symbols.count - 1, day - 1))
        return symbols[index]
    }
}

#Preview {
    SettingsView()
        .environmentObject(WheelStore())
        .environmentObject(ReminderScheduler.shared)
}
