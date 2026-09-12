import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: Store
    @State private var target: LogTarget?
    @State private var customKind: EntryKind?
    @State private var detail: LedgerEntry?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BalanceHeader()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Quick add") {
                    ForEach(store.mostUsedEarnRules()) { rule in
                        Button { target = LogTarget(rule: rule, kind: .earn) } label: {
                            RuleRow(rule: rule, kind: .earn)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section {
                    Button { customKind = .earn } label: {
                        Label("Custom earn", systemImage: "plus.circle")
                    }
                    Button { customKind = .spend } label: {
                        Label("Custom spend", systemImage: "gift")
                    }
                }

                Section("Recent") {
                    let recent = Array(store.entries.prefix(6))
                    if recent.isEmpty {
                        Text("No Mills Bucks logged yet. Tap something above to start.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ForEach(recent) { entry in
                            Button { detail = entry } label: { EntryRow(entry: entry) }
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Mills Bucks")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $target) { t in LogSheet(rule: t.rule, kind: t.kind) }
        .sheet(item: $customKind) { k in CustomEntrySheet(kind: k) }
        .sheet(item: $detail) { e in EntryDetailSheet(entry: e) }
    }
}
