import SwiftUI
import Foundation
import Combine
import WidgetKit

struct LifeArea: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var score: Double
    var notes: String
    var colorHex: String
    var icon: String
    var isEnabled: Bool

    var color: Color { Color(hex: colorHex) }

    init(
        id: UUID = UUID(),
        name: String,
        score: Double = 5,
        notes: String = "",
        colorHex: String,
        icon: String,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.score = score
        self.notes = notes
        self.colorHex = colorHex
        self.icon = icon
        self.isEnabled = isEnabled
    }

    /// Full-spectrum set inspired by classic coaching wheels (10 areas).
    static let fullSpectrum: [LifeArea] = [
        LifeArea(name: "Health", score: 6, colorHex: "#E91E8C", icon: "heart.fill"),
        LifeArea(name: "Work", score: 5, colorHex: "#E53935", icon: "briefcase.fill"),
        LifeArea(name: "Family", score: 7, colorHex: "#FB8C00", icon: "house.fill"),
        LifeArea(name: "Friends", score: 6, colorHex: "#FDD835", icon: "person.2.fill"),
        LifeArea(name: "Romance", score: 5, colorHex: "#C0CA33", icon: "heart.circle.fill"),
        LifeArea(name: "Intimacy", score: 5, colorHex: "#43A047", icon: "flame.fill"),
        LifeArea(name: "Creativity", score: 6, colorHex: "#00897B", icon: "paintbrush.fill"),
        LifeArea(name: "Learning", score: 7, colorHex: "#1E88E5", icon: "book.fill"),
        LifeArea(name: "Finances", score: 4, colorHex: "#3949AB", icon: "dollarsign.circle.fill"),
        LifeArea(name: "Spirit", score: 5, colorHex: "#8E24AA", icon: "sparkles"),
    ]

    /// Compact classic coaching set (8 areas).
    static let classicEight: [LifeArea] = [
        LifeArea(name: "Health", score: 5, colorHex: "#E53935", icon: "heart.fill"),
        LifeArea(name: "Career", score: 5, colorHex: "#00897B", icon: "briefcase.fill"),
        LifeArea(name: "Money", score: 5, colorHex: "#3949AB", icon: "dollarsign.circle.fill"),
        LifeArea(name: "Love", score: 5, colorHex: "#E91E8C", icon: "heart.circle.fill"),
        LifeArea(name: "Family & Friends", score: 5, colorHex: "#FB8C00", icon: "person.3.fill"),
        LifeArea(name: "Growth", score: 5, colorHex: "#1E88E5", icon: "book.fill"),
        LifeArea(name: "Fun", score: 5, colorHex: "#C0CA33", icon: "gamecontroller.fill"),
        LifeArea(name: "Contribution", score: 5, colorHex: "#43A047", icon: "globe.americas.fill"),
    ]

    static let defaults = fullSpectrum
}

struct Assessment: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var areas: [LifeArea]
    var note: String

    init(id: UUID = UUID(), date: Date = Date(), areas: [LifeArea], note: String = "") {
        self.id = id
        self.date = date
        self.areas = areas
        self.note = note
    }

    var averageScore: Double {
        guard !areas.isEmpty else { return 0 }
        return areas.map(\.score).reduce(0, +) / Double(areas.count)
    }

    var lowestAreas: [LifeArea] {
        let minScore = areas.map(\.score).min() ?? 0
        return areas.filter { $0.score == minScore }.sorted { $0.name < $1.name }
    }

    var highestAreas: [LifeArea] {
        let maxScore = areas.map(\.score).max() ?? 0
        return areas.filter { $0.score == maxScore }.sorted { $0.name < $1.name }
    }

    /// Lower = more balanced (0 = perfectly even).
    var imbalance: Double {
        guard areas.count > 1 else { return 0 }
        let avg = averageScore
        let variance = areas.map { pow($0.score - avg, 2) }.reduce(0, +) / Double(areas.count)
        return sqrt(variance)
    }
}

enum WheelTemplate: String, CaseIterable, Identifiable {
    case fullSpectrum = "Full Spectrum"
    case classicEight = "Classic 8"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .fullSpectrum: return "10 vivid life areas — coaching classic"
        case .classicEight: return "8 focused spheres — clean & actionable"
        }
    }

    var areas: [LifeArea] {
        switch self {
        case .fullSpectrum: return LifeArea.fullSpectrum
        case .classicEight: return LifeArea.classicEight
        }
    }
}

@MainActor
final class WheelStore: ObservableObject {
    @Published var currentAreas: [LifeArea]
    @Published var assessments: [Assessment]
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedAreaID: UUID?

    private let areasKey = "wol_lifeAreas_v2"
    private let assessmentsKey = "wol_assessments_v2"
    private let onboardingKey = "wol_onboarding_v1"

    var activeAreas: [LifeArea] {
        currentAreas.filter(\.isEnabled)
    }

    var average: Double {
        guard !activeAreas.isEmpty else { return 0 }
        return activeAreas.map(\.score).reduce(0, +) / Double(activeAreas.count)
    }

    var selectedArea: LifeArea? {
        guard let selectedAreaID else { return activeAreas.first }
        return activeAreas.first(where: { $0.id == selectedAreaID }) ?? activeAreas.first
    }

    init() {
        let decoder = JSONDecoder()

        if let data = UserDefaults.standard.data(forKey: areasKey),
           let areas = try? decoder.decode([LifeArea].self, from: data) {
            self.currentAreas = areas
        } else if let data = UserDefaults.standard.data(forKey: "wol_lifeAreas_v1"),
                  let legacy = try? decoder.decode([LegacyLifeArea].self, from: data) {
            self.currentAreas = legacy.map {
                LifeArea(
                    id: $0.id,
                    name: $0.name,
                    score: $0.score,
                    notes: $0.notes,
                    colorHex: $0.colorHex,
                    icon: $0.icon,
                    isEnabled: true
                )
            }
        } else {
            self.currentAreas = LifeArea.defaults
        }

        if let data = UserDefaults.standard.data(forKey: assessmentsKey),
           let saved = try? decoder.decode([Assessment].self, from: data) {
            self.assessments = saved
        } else if let data = UserDefaults.standard.data(forKey: "wol_assessments_v1"),
                  let legacy = try? decoder.decode([LegacyAssessment].self, from: data) {
            self.assessments = legacy.map {
                Assessment(
                    id: $0.id,
                    date: $0.date,
                    areas: $0.areas.map {
                        LifeArea(
                            id: $0.id,
                            name: $0.name,
                            score: $0.score,
                            notes: $0.notes,
                            colorHex: $0.colorHex,
                            icon: $0.icon,
                            isEnabled: true
                        )
                    }
                )
            }
        } else {
            self.assessments = []
        }

        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: onboardingKey)
        self.selectedAreaID = currentAreas.first(where: \.isEnabled)?.id
        publishWidgetSnapshot()
    }

    var focusName: String {
        guard let min = activeAreas.map(\.score).min() else { return "—" }
        return activeAreas.first(where: { $0.score == min })?.name ?? "—"
    }

    var strengthName: String {
        guard let max = activeAreas.map(\.score).max() else { return "—" }
        return activeAreas.first(where: { $0.score == max })?.name ?? "—"
    }

    func selectArea(_ area: LifeArea) {
        selectedAreaID = area.id
    }

    func updateScore(for area: LifeArea, to score: Double) {
        guard let idx = currentAreas.firstIndex(where: { $0.id == area.id }) else { return }
        let clamped = min(10, max(0, score.rounded()))
        guard currentAreas[idx].score != clamped else { return }
        currentAreas[idx].score = clamped
        persist()
    }

    func updateNotes(for area: LifeArea, to notes: String) {
        guard let idx = currentAreas.firstIndex(where: { $0.id == area.id }) else { return }
        currentAreas[idx].notes = notes
        persist()
    }

    func setEnabled(_ enabled: Bool, for area: LifeArea) {
        guard let idx = currentAreas.firstIndex(where: { $0.id == area.id }) else { return }
        let enabledCount = currentAreas.filter(\.isEnabled).count
        if !enabled && enabledCount <= 3 { return }
        currentAreas[idx].isEnabled = enabled
        if selectedAreaID == area.id {
            selectedAreaID = activeAreas.first?.id
        }
        persist()
    }

    func applyTemplate(_ template: WheelTemplate) {
        currentAreas = template.areas
        selectedAreaID = currentAreas.first?.id
        persist()
    }

    func resetScores(to value: Double = 5) {
        for i in currentAreas.indices where currentAreas[i].isEnabled {
            currentAreas[i].score = value
        }
        persist()
    }

    func saveAssessment(note: String = "") {
        let snapshot = activeAreas
        assessments.insert(Assessment(areas: snapshot, note: note), at: 0)
        persist()
    }

    func deleteAssessments(at offsets: IndexSet) {
        assessments.remove(atOffsets: offsets)
        persist()
    }

    func completeOnboarding(with template: WheelTemplate) {
        applyTemplate(template)
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
    }

    func balanceLabel(_ score: Double) -> String {
        switch score {
        case ..<3: return "Needs attention"
        case ..<5: return "Room to grow"
        case ..<7: return "On track"
        case ..<9: return "Living well"
        default: return "Exceptional"
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(currentAreas) {
            UserDefaults.standard.set(data, forKey: areasKey)
        }
        if let data = try? encoder.encode(assessments) {
            UserDefaults.standard.set(data, forKey: assessmentsKey)
        }
        publishWidgetSnapshot()
    }

    private func publishWidgetSnapshot() {
        let snapshot = WidgetSnapshot(
            average: average,
            focus: focusName,
            strength: strengthName,
            areas: activeAreas.map {
                WidgetAreaSnapshot(id: $0.id, name: $0.name, score: $0.score, colorHex: $0.colorHex)
            },
            updatedAt: Date()
        )
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Legacy migration

private struct LegacyLifeArea: Codable {
    var id: UUID
    var name: String
    var score: Double
    var notes: String
    var colorHex: String
    var icon: String
}

private struct LegacyAssessment: Codable {
    var id: UUID
    var date: Date
    var areas: [LegacyLifeArea]
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
