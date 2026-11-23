import SwiftUI

struct EarnView: View {
    @EnvironmentObject private var store: Store
    @State private var target: LogTarget?
    @State private var showCustom = false
    @State private var query = ""

    private func matches(_ rules: [Rule]) -> [Rule] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return rules }
        return rules.filter { $0.title.lowercased().contains(q) }
    }

    private var uncategorised: [Rule] {
        let known = Set(store.data.categories.map(\.id))
        return matches(store.data.earnRules.filter { $0.categoryID == nil || !known.contains($0.categoryID!) })
    }

    private var isEmpty: Bool {
        store.data.categories.allSatisfy { matches(store.rules(in: $0)).isEmpty } && uncategorised.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BalanceHeader(compact: true)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    Button { showCustom = true } label: {
                        Label("Custom amount", systemImage: "plus.circle")
                    }
                }

                ForEach(store.data.categories) { category in
                    let rules = matches(store.rules(in: category))
                    if !rules.isEmpty {
                        Section("\(category.emoji) \(category.name)") {
                            ForEach(rules) { rule in
                                Button { target = LogTarget(rule: rule, kind: .earn) } label: {
                                    RuleRow(rule: rule, kind: .earn)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                if !uncategorised.isEmpty {
                    Section("✨ Other") {
                        ForEach(uncategorised) { rule in
                            Button { target = LogTarget(rule: rule, kind: .earn) } label: {
                                RuleRow(rule: rule, kind: .earn)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if isEmpty {
                    Text("Nothing matches “\(query)”.")
                        .foregroundStyle(.secondary)
                }
            }
            .searchable(text: $query, prompt: "Search rewards")
            .navigationTitle("Earn")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $target) { t in LogSheet(rule: t.rule, kind: t.kind) }
        .sheet(isPresented: $showCustom) { CustomEntrySheet(kind: .earn) }
    }
}
