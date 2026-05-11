import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var store: WheelStore

    var body: some View {
        NavigationStack {
            Group {
                if store.assessments.isEmpty {
                    ContentUnavailableView(
                        "No Assessments Yet",
                        systemImage: "chart.pie.fill",
                        description: Text("Save your first assessment on the Rate tab.")
                    )
                } else {
                    List {
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
            }
            .navigationTitle("History")
        }
    }
}

struct AssessmentRow: View {
    let assessment: Assessment

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(assessment.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
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
        if score < 4 { return .red }
        if score < 7 { return .orange }
        return .green
    }
}

struct AssessmentDetailView: View {
    let assessment: Assessment

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WheelChartView(areas: assessment.areas, animated: true)
                    .frame(height: 320)
                    .padding(.horizontal)

                VStack(spacing: 10) {
                    ForEach(assessment.areas.sorted(by: { $0.score > $1.score })) { area in
                        HStack(spacing: 12) {
                            Image(systemName: area.icon)
                                .foregroundStyle(area.color)
                                .frame(width: 20)
                            Text(area.name)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ProgressView(value: area.score / 10)
                                .tint(area.color)
                                .frame(width: 100)
                            Text("\(Int(area.score))")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(area.color)
                                .frame(width: 20, alignment: .trailing)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.06), radius: 8)
                )
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .navigationTitle(assessment.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
}
