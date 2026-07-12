import Foundation
import SwiftUI

enum AppGroup {
    static let suiteName = "group.Crimson.WheelOfLife"
    static let snapshotKey = "widget_snapshot_v1"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}

struct WidgetAreaSnapshot: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var score: Double
    var colorHex: String

    init(id: UUID = UUID(), name: String, score: Double, colorHex: String) {
        self.id = id
        self.name = name
        self.score = score
        self.colorHex = colorHex
    }
}

struct WidgetSnapshot: Codable, Hashable {
    var average: Double
    var focus: String
    var strength: String
    var areas: [WidgetAreaSnapshot]
    var updatedAt: Date

    static let placeholder = WidgetSnapshot(
        average: 6.2,
        focus: "Finances",
        strength: "Family",
        areas: [
            WidgetAreaSnapshot(name: "Health", score: 7, colorHex: "#E91E8C"),
            WidgetAreaSnapshot(name: "Work", score: 5, colorHex: "#E53935"),
            WidgetAreaSnapshot(name: "Family", score: 8, colorHex: "#FB8C00"),
            WidgetAreaSnapshot(name: "Friends", score: 6, colorHex: "#FDD835"),
            WidgetAreaSnapshot(name: "Romance", score: 5, colorHex: "#C0CA33"),
            WidgetAreaSnapshot(name: "Intimacy", score: 5, colorHex: "#43A047"),
            WidgetAreaSnapshot(name: "Creativity", score: 6, colorHex: "#00897B"),
            WidgetAreaSnapshot(name: "Learning", score: 7, colorHex: "#1E88E5"),
            WidgetAreaSnapshot(name: "Finances", score: 4, colorHex: "#3949AB"),
            WidgetAreaSnapshot(name: "Spirit", score: 6, colorHex: "#8E24AA"),
        ],
        updatedAt: Date()
    )

    static func load() -> WidgetSnapshot {
        guard let data = AppGroup.defaults.data(forKey: AppGroup.snapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppGroup.defaults.set(data, forKey: AppGroup.snapshotKey)
    }
}

extension Color {
    init(widgetHex hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
