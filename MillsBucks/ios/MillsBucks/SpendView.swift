import SwiftUI

struct SpendView: View {
    @EnvironmentObject private var store: Store
    @State private var target: LogTarget?
    @State private var showCustom = false

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
                        Label("Custom amount", systemImage: "gift")
                    }
                }

                Section {
                    ForEach(store.rules(.spend)) { rule in
                        Button { target = LogTarget(rule: rule, kind: .spend) } label: {
                            RuleRow(rule: rule, kind: .spend)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Rewards")
                } footer: {
                    Text("Cash-out uses the rate of \(Format.usd(1, rate: store.rate)) per Mills Buck. Change it in Settings.")
                }
            }
            .navigationTitle("Spend")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $target) { t in LogSheet(rule: t.rule, kind: t.kind) }
        .sheet(isPresented: $showCustom) { CustomEntrySheet(kind: .spend) }
    }
}
