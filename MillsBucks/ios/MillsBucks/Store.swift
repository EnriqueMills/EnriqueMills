import Combine
import Foundation

/// Single source of truth. Persists to a JSON file in Application Support
/// after every mutation — small data, no database needed.
final class Store: ObservableObject {

    @Published private(set) var data: AppData

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        let resolved: URL
        if let fileURL = fileURL {
            resolved = fileURL
        } else {
            let dir = (try? FileManager.default.url(for: .applicationSupportDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: nil,
                                                    create: true))
                ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            resolved = dir.appendingPathComponent("MillsBucks.json")
        }
        self.fileURL = resolved

        if let raw = try? Data(contentsOf: resolved),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = Catalog.starterData()
        }
        repair()
        save()
    }

    // MARK: - Derived state

    var rate: Double { data.rate }

    var kids: [Kid] { data.kids }

    var activeKid: Kid {
        data.kids.first { $0.id == data.activeKidID } ?? data.kids[0]
    }

    /// Ledger for the selected kid, newest first.
    var entries: [LedgerEntry] {
        data.entries
            .filter { $0.kidID == activeKid.id }
            .sorted { $0.date > $1.date }
    }

    var balance: Double {
        rounded(entries.reduce(0) { $0 + $1.signedAmount })
    }

    var lifetimeEarned: Double {
        rounded(entries.filter { $0.kind == .earn }.reduce(0) { $0 + $1.amount })
    }

    func total(_ kind: EntryKind, since date: Date) -> Double {
        rounded(entries.filter { $0.kind == kind && $0.date >= date }.reduce(0) { $0 + $1.amount })
    }

    func balance(for kid: Kid) -> Double {
        rounded(data.entries.filter { $0.kidID == kid.id }.reduce(0) { $0 + $1.signedAmount })
    }

    func entryCount(for kid: Kid) -> Int {
        data.entries.filter { $0.kidID == kid.id }.count
    }

    /// The rules this kid uses most, for the Home screen's quick-add list.
    func mostUsedEarnRules(limit: Int = 5) -> [Rule] {
        var counts: [String: Int] = [:]
        for entry in entries {
            if let id = entry.ruleID { counts[id, default: 0] += 1 }
        }
        let ranked = data.earnRules.enumerated().sorted { lhs, rhs in
            let l = counts[lhs.element.id] ?? 0
            let r = counts[rhs.element.id] ?? 0
            return l == r ? lhs.offset < rhs.offset : l > r
        }
        return ranked.prefix(limit).map(\.element)
    }

    func rules(_ kind: EntryKind) -> [Rule] {
        kind == .earn ? data.earnRules : data.spendRules
    }

    func rules(in category: RewardCategory) -> [Rule] {
        data.earnRules.filter { $0.categoryID == category.id }
    }

    // MARK: - Ledger

    @discardableResult
    func add(kind: EntryKind, title: String, amount: Double, emoji: String,
             note: String = "", ruleID: String? = nil) -> LedgerEntry {
        let entry = LedgerEntry(kidID: activeKid.id, kind: kind, title: title,
                                amount: rounded(amount), emoji: emoji, note: note, ruleID: ruleID)
        data.entries.append(entry)
        save()
        return entry
    }

    func delete(entryID: UUID) {
        data.entries.removeAll { $0.id == entryID }
        save()
    }

    func restore(_ entry: LedgerEntry) {
        data.entries.append(entry)
        save()
    }

    func setNote(_ note: String, for entryID: UUID) {
        guard let i = data.entries.firstIndex(where: { $0.id == entryID }) else { return }
        data.entries[i].note = note
        save()
    }

    // MARK: - Settings

    func setRate(_ value: Double) {
        guard value > 0, value.isFinite else { return }
        data.rate = rounded(value)
        save()
    }

    func select(kid: Kid) {
        data.activeKidID = kid.id
        save()
    }

    func addKid(name: String, emoji: String) {
        let kid = Kid(name: name.isEmpty ? "Kid" : name, emoji: emoji.isEmpty ? "⭐️" : emoji)
        data.kids.append(kid)
        data.activeKidID = kid.id
        save()
    }

    func update(kid: Kid) {
        guard let i = data.kids.firstIndex(where: { $0.id == kid.id }) else { return }
        data.kids[i] = kid
        save()
    }

    /// Removing a kid removes their ledger too. Refuses to remove the last kid.
    func deleteKid(_ kid: Kid) {
        guard data.kids.count > 1 else { return }
        data.kids.removeAll { $0.id == kid.id }
        data.entries.removeAll { $0.kidID == kid.id }
        if data.activeKidID == kid.id { data.activeKidID = data.kids.first?.id }
        save()
    }

    func upsert(rule: Rule, kind: EntryKind) {
        let path: WritableKeyPath<AppData, [Rule]> = kind == .earn ? \.earnRules : \.spendRules
        if let i = data[keyPath: path].firstIndex(where: { $0.id == rule.id }) {
            data[keyPath: path][i] = rule
        } else {
            data[keyPath: path].append(rule)
        }
        save()
    }

    func deleteRule(id: String, kind: EntryKind) {
        if kind == .earn {
            data.earnRules.removeAll { $0.id == id }
        } else {
            data.spendRules.removeAll { $0.id == id }
        }
        save()
    }

    // MARK: - Backup

    func exportJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return (try? encoder.encode(data)) ?? Data()
    }

    enum ImportError: Error { case unreadable }

    func importJSON(_ raw: Data) throws {
        let decoder = JSONDecoder()
        guard let decoded = try? decoder.decode(AppData.self, from: raw) else {
            // Fall back to the web app's export, which encodes dates as ISO-8601.
            decoder.dateDecodingStrategy = .iso8601
            guard let iso = try? decoder.decode(AppData.self, from: raw) else {
                throw ImportError.unreadable
            }
            data = iso
            repair()
            save()
            return
        }
        data = decoded
        repair()
        save()
    }

    func eraseAll() {
        data = Catalog.starterData()
        repair()
        save()
    }

    // MARK: - Internals

    private func rounded(_ v: Double) -> Double { (v * 100).rounded() / 100 }

    /// Guarantees the invariants every view relies on: at least one kid, a valid
    /// selection, a sane rate, and a non-empty catalog.
    private func repair() {
        if data.kids.isEmpty { data.kids = [Kid(name: "My Kid")] }
        if data.activeKidID == nil || !data.kids.contains(where: { $0.id == data.activeKidID }) {
            data.activeKidID = data.kids[0].id
        }
        if !(data.rate > 0) || !data.rate.isFinite { data.rate = Catalog.defaultRate }
        if data.earnRules.isEmpty { data.earnRules = Catalog.earnRules }
        if data.spendRules.isEmpty { data.spendRules = Catalog.spendRules }
        if data.categories.isEmpty { data.categories = Catalog.categories }
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let raw = try? encoder.encode(data) else { return }
        try? raw.write(to: fileURL, options: .atomic)
    }
}
