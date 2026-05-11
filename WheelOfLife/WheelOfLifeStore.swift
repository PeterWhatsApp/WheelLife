import SwiftUI
import Foundation
import Combine

struct LifeArea: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var score: Double
    var notes: String = ""
    var colorHex: String
    var icon: String

    var color: Color { Color(hex: colorHex) }

    static let defaults: [LifeArea] = [
        LifeArea(name: "Health",        score: 5, colorHex: "#FF6B6B", icon: "heart.fill"),
        LifeArea(name: "Career",        score: 5, colorHex: "#4ECDC4", icon: "briefcase.fill"),
        LifeArea(name: "Finance",       score: 5, colorHex: "#45B7D1", icon: "dollarsign.circle.fill"),
        LifeArea(name: "Relationships", score: 5, colorHex: "#96CEB4", icon: "person.2.fill"),
        LifeArea(name: "Growth",        score: 5, colorHex: "#A29BFE", icon: "book.fill"),
        LifeArea(name: "Fun",           score: 5, colorHex: "#FD79A8", icon: "gamecontroller.fill"),
        LifeArea(name: "Environment",   score: 5, colorHex: "#55EFC4", icon: "house.fill"),
        LifeArea(name: "Family",        score: 5, colorHex: "#FDCB6E", icon: "person.3.fill"),
    ]
}

struct Assessment: Identifiable, Codable {
    var id = UUID()
    var date: Date = Date()
    var areas: [LifeArea]

    var averageScore: Double {
        guard !areas.isEmpty else { return 0 }
        return areas.map(\.score).reduce(0, +) / Double(areas.count)
    }
}

@MainActor
class WheelStore: ObservableObject {
    @Published var currentAreas: [LifeArea]
    @Published var assessments: [Assessment]

    private let areasKey = "wol_lifeAreas_v1"
    private let assessmentsKey = "wol_assessments_v1"

    init() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "wol_lifeAreas_v1"),
           let areas = try? decoder.decode([LifeArea].self, from: data) {
            self.currentAreas = areas
        } else {
            self.currentAreas = LifeArea.defaults
        }
        if let data = UserDefaults.standard.data(forKey: "wol_assessments_v1"),
           let saved = try? decoder.decode([Assessment].self, from: data) {
            self.assessments = saved
        } else {
            self.assessments = []
        }
    }

    func updateScore(for area: LifeArea, to score: Double) {
        guard let idx = currentAreas.firstIndex(where: { $0.id == area.id }) else { return }
        currentAreas[idx].score = score
        persist()
    }

    func updateNotes(for area: LifeArea, to notes: String) {
        guard let idx = currentAreas.firstIndex(where: { $0.id == area.id }) else { return }
        currentAreas[idx].notes = notes
        persist()
    }

    func saveAssessment() {
        assessments.insert(Assessment(areas: currentAreas), at: 0)
        persist()
    }

    func deleteAssessments(at offsets: IndexSet) {
        assessments.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(currentAreas) {
            UserDefaults.standard.set(data, forKey: areasKey)
        }
        if let data = try? encoder.encode(assessments) {
            UserDefaults.standard.set(data, forKey: assessmentsKey)
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8)  & 0xFF) / 255
        let b = Double( value        & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
