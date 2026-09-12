import SwiftUI

/// Confirm sheet for logging a catalog rule: quantity, optional note, running total.
struct LogSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    let rule: Rule
    let kind: EntryKind

    @State private var quantity = 1
    @State private var note = ""

    private var total: Double { (rule.amount * Double(quantity) * 100).rounded() / 100 }
    private var overdrawn: Bool { kind == .spend && total > store.balance }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Text(rule.emoji).font(.system(size: 40))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(rule.title).font(.headline)
                            Text("\(Format.mb(rule.amount)) MB · \(Format.usd(rule.amount, rate: store.rate)) each")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Stepper(value: $quantity, in: 1...99) {
                        HStack {
                            Text("How many")
                            Spacer()
                            Text("\(quantity)")
                                .font(.body.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                    TextField("Note (optional)", text: $note)
                        .textInputAutocapitalization(.sentences)
                }

                Section {
                    HStack {
                        Text(kind == .earn ? "Adding" : "Spending")
                        Spacer()
                        Text("\(Format.signedMB(total, kind: kind)) MB · \(Format.usd(total, rate: store.rate))")
                            .font(.body.weight(.bold).monospacedDigit())
                            .foregroundStyle(kind == .earn ? Color.accentColor : Color.orange)
                    }
                } footer: {
                    if overdrawn {
                        Text("That is more than the current balance of \(Format.mb(store.balance)) MB. You can still log it — the balance will go negative.")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle(kind == .earn ? "Add Mills Bucks" : "Spend Mills Bucks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(kind == .earn ? "Add" : "Spend") {
                        store.add(kind: kind, title: rule.title, amount: total,
                                  emoji: rule.emoji, note: note.trimmingCharacters(in: .whitespaces),
                                  ruleID: rule.id)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// One-off entry that is not in the catalog.
struct CustomEntrySheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    let kind: EntryKind

    @State private var title = ""
    @State private var amountText = ""

    private var amount: Double? {
        guard let v = Double(amountText.replacingOccurrences(of: ",", with: ".")), v > 0, v.isFinite else { return nil }
        return (v * 100).rounded() / 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("What for?") {
                    TextField(kind == .earn ? "e.g. helped a neighbour" : "e.g. bought a skateboard",
                              text: $title)
                        .textInputAutocapitalization(.sentences)
                }
                Section("Mills Bucks") {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                if let amount = amount {
                    Section {
                        HStack {
                            Text(kind == .earn ? "Adding" : "Spending")
                            Spacer()
                            Text("\(Format.signedMB(amount, kind: kind)) MB · \(Format.usd(amount, rate: store.rate))")
                                .font(.body.weight(.bold).monospacedDigit())
                                .foregroundStyle(kind == .earn ? Color.accentColor : Color.orange)
                        }
                    }
                }
            }
            .navigationTitle(kind == .earn ? "Custom Earn" : "Custom Spend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount = amount else { return }
                        let name = title.trimmingCharacters(in: .whitespaces)
                        store.add(kind: kind,
                                  title: name.isEmpty ? (kind == .earn ? "Bonus" : "Reward") : name,
                                  amount: amount,
                                  emoji: kind == .earn ? "⭐️" : "🎁")
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(amount == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// Edit the note on, or delete, an existing ledger line.
struct EntryDetailSheet: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    let entry: LedgerEntry
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        Text(entry.emoji).font(.system(size: 40))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title).font(.headline)
                            Text("\(entry.kind == .earn ? "Earned" : "Spent") \(Format.mb(entry.amount)) MB · \(Format.usd(entry.amount, rate: store.rate))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(Format.dayLabel(entry.date)) · \(Format.time(entry.date))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Note") {
                    TextField("Optional", text: $note)
                }
                Section {
                    Button(role: .destructive) {
                        store.delete(entryID: entry.id)
                        dismiss()
                    } label: {
                        Label("Delete this entry", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setNote(note.trimmingCharacters(in: .whitespaces), for: entry.id)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear { note = entry.note }
        }
        .presentationDetents([.medium, .large])
    }
}
