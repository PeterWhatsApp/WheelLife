import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: WheelStore

    var body: some View {
        NavigationStack {
            ZStack {
                AtmosphereBackground()

                Group {
                    if store.assessments.isEmpty {
                        ContentUnavailableView(
                            "No snapshots yet",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Save a wheel from the Wheel or Rate tab to track change over time.")
                        )
                    } else {
                        List {
                            if store.assessments.count >= 2 {
                                Section {
                                    TrendSummaryCard(
                                        latest: store.assessments[0],
                                        previous: store.assessments[1]
                                    )
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                    .listRowBackground(Color.clear)
                                }
                            }

                            Section("Snapshots") {
                                ForEach(store.assessments) { assessment in
                                    NavigationLink {
                                        AssessmentDetailView(assessment: assessment)
                                    } label: {
                                        AssessmentRow(assessment: assessment)
                                    }
                                }
                                .onDelete(perform: store.deleteAssessments)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct TrendSummaryCard: View {
    let latest: Assessment
    let previous: Assessment

    private var delta: Double { latest.averageScore - previous.averageScore }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Since last snapshot")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.mutedInk)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundStyle(delta >= 0 ? Color(hex: "#43A047") : Color(hex: "#E53935"))
                Text(String(format: "%+.1f average", delta))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(AppTheme.ink)
            }

            Text(balanceBlurb)
                .font(.subheadline)
                .foregroundStyle(AppTheme.mutedInk)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        )
    }

    private var balanceBlurb: String {
        let imbalanceDelta = latest.imbalance - previous.imbalance
        if abs(delta) < 0.15 && abs(imbalanceDelta) < 0.15 {
            return "Your wheel is holding steady."
        }
        if imbalanceDelta < -0.2 {
            return "Your life areas are evening out — smoother ride."
        }
        if delta > 0.2 {
            return "Overall satisfaction is climbing."
        }
        if delta < -0.2 {
            return "A few areas dipped — worth a closer look."
        }
        return "Small shifts — consistency compounds."
    }
}

struct AssessmentRow: View {
    let assessment: Assessment

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(assessment.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(.headline, design: .rounded))
                Text(assessment.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: assessment.averageScore / 10)
                    .stroke(
                        scoreColor(assessment.averageScore).gradient,
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.1f", assessment.averageScore))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .frame(width: 44, height: 44)
        }
        .padding(.vertical, 4)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score < 4 { return Color(hex: "#E53935") }
        if score < 7 { return Color(hex: "#FB8C00") }
        return Color(hex: "#43A047")
    }
}

struct AssessmentDetailView: View {
    let assessment: Assessment

    var body: some View {
        ZStack {
            AtmosphereBackground()

            ScrollView {
                VStack(spacing: 20) {
                    WheelChartView(areas: assessment.areas, animated: true, interactive: false)
                        .frame(height: 340)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(AppTheme.card)
                                .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
                        )

                    HStack(spacing: 12) {
                        miniStat(title: "Average", value: String(format: "%.1f", assessment.averageScore))
                        miniStat(
                            title: "Focus",
                            value: assessment.lowestAreas.first?.name ?? "—"
                        )
                        miniStat(
                            title: "Strength",
                            value: assessment.highestAreas.first?.name ?? "—"
                        )
                    }

                    VStack(spacing: 10) {
                        ForEach(assessment.areas.sorted(by: { $0.score > $1.score })) { area in
                            HStack(spacing: 12) {
                                Image(systemName: area.icon)
                                    .foregroundStyle(area.color)
                                    .frame(width: 20)
                                Text(area.name)
                                    .font(.system(.body, design: .rounded))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                ProgressView(value: area.score / 10)
                                    .tint(area.color)
                                    .frame(width: 90)
                                Text("\(Int(area.score))")
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundStyle(area.color)
                                    .frame(width: 22, alignment: .trailing)
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppTheme.card)
                            .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
                    )
                }
                .padding(20)
            }
        }
        .navigationTitle(assessment.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func miniStat(title: String, value: String) -> some View {
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
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.card)
        )
    }
}
