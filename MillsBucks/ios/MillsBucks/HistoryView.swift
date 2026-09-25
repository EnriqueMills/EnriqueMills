import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: Store
    @State private var filter: Filter = .all
    @State private var detail: LedgerEntry?

    enum Filter: String, CaseIterable {
        case all = "All", earned = "Earned", spent = "Spent"

        func keeps(_ entry: LedgerEntry) -> Bool {
            switch self {
            case .all:     return true
            case .earned:  return entry.kind == .earn
            case .spent:   return entry.kind == .spend
            }
        }
    }

    struct DayGroup: Identifiable {
        let day: String
        let entries: [LedgerEntry]

        var id: String { day }
    }

    /// Entries bucketed by day, newest day first, preserving the store's ordering.
    private var groups: [DayGroup] {
        var order: [String] = []
        var buckets: [String: [LedgerEntry]] = [:]
        for entry in store.entries where filter.keeps(entry) {
            let key = Format.dayLabel(entry.date)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(entry)
        }
        return order.map { DayGroup(day: $0, entries: buckets[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                }

                if groups.isEmpty {
                    Section {
                        Text("Nothing here yet.")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(groups) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            Button { detail = entry } label: { EntryRow(entry: entry) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            for index in offsets { store.delete(entryID: group.entries[index].id) }
                        }
                    } header: {
                        HStack {
                            Text(group.day)
                            Spacer()
                            Text(net(group.entries))
                                .monospacedDigit()
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { EditButton() } }
        }
        .sheet(item: $detail) { e in EntryDetailSheet(entry: e) }
    }

    private func net(_ entries: [LedgerEntry]) -> String {
        let total = entries.reduce(0) { $0 + $1.signedAmount }
        return (total < 0 ? "−" : "+") + Format.mb(abs(total)) + " MB"
    }
}
