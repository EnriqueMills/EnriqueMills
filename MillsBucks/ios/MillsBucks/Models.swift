import Foundation

enum EntryKind: String, Codable, CaseIterable, Identifiable {
    case earn, spend

    var id: String { rawValue }
}

/// Identifies which rule a sheet is logging, so `.sheet(item:)` can drive it.
struct LogTarget: Identifiable {
    let rule: Rule
    let kind: EntryKind

    var id: String { kind.rawValue + "-" + rule.id }
}

/// One line in the ledger. `amount` is always positive; `kind` carries the direction.
struct LedgerEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var kidID: UUID
    var date = Date()
    var kind: EntryKind
    var title: String
    var amount: Double
    var emoji: String
    var note: String = ""
    var ruleID: String?

    var signedAmount: Double { kind == .earn ? amount : -amount }
}

struct Kid: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var emoji: String = "⭐️"
}

struct RewardCategory: Identifiable, Codable, Hashable {
    var id: String
    var name: String
    var emoji: String
}

/// A reusable entry in the catalog — "A on a test", "Cash out 5 Mills Bucks".
struct Rule: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString
    var title: String
    var amount: Double
    var emoji: String
    var categoryID: String?
}

struct AppData: Codable {
    var version = 1
    var rate: Double = 2.25
    var kids: [Kid] = []
    var activeKidID: UUID?
    var entries: [LedgerEntry] = []
    var earnRules: [Rule] = []
    var spendRules: [Rule] = []
    var categories: [RewardCategory] = []
}

// MARK: - Formatting

enum Format {
    private static let mbFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    private static let usdFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.locale = Locale(identifier: "en_US")
        return f
    }()

    /// "1", "1.5", "0.75", "110.5" — never "1.00".
    static func mb(_ value: Double) -> String {
        mbFormatter.string(from: NSNumber(value: value)) ?? "0"
    }

    /// Signed for display in a ledger: "+4", "−22".
    static func signedMB(_ value: Double, kind: EntryKind) -> String {
        (kind == .earn ? "+" : "−") + mb(value)
    }

    static func usd(_ millsBucks: Double, rate: Double) -> String {
        usdFormatter.string(from: NSNumber(value: millsBucks * rate)) ?? "$0.00"
    }

    static func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = cal.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "EEE, MMM d" : "MMM d, yyyy"
        return f.string(from: date)
    }

    static func time(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }
}
