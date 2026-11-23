import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: Store

    @State private var rateText = ""
    @State private var editingKid: Kid?
    @State private var addingKid = false
    @State private var exporting = false
    @State private var importing = false
    @State private var importError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("1 Mills Buck")
                        Spacer()
                        TextField("2.25", text: $rateText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                            .onSubmit(commitRate)
                        Text("USD").foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Exchange rate")
                } footer: {
                    Text("What one Mills Buck is worth in dollars. Saved as you type.")
                }

                Section("Kids") {
                    ForEach(store.kids) { kid in
                        Button { editingKid = kid } label: {
                            HStack(spacing: 12) {
                                Text(kid.emoji).font(.title2).frame(width: 32)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(kid.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(Color.primary)
                                    Text("\(store.entryCount(for: kid)) entries · \(Format.mb(store.balance(for: kid))) MB")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Button { addingKid = true } label: {
                        Label("Add a kid", systemImage: "person.badge.plus")
                    }
                }

                Section("Reward catalog") {
                    NavigationLink {
                        RuleListView(kind: .earn)
                    } label: {
                        Label("Earning rules (\(store.rules(.earn).count))", systemImage: "star")
                    }
                    NavigationLink {
                        RuleListView(kind: .spend)
                    } label: {
                        Label("Spending rules (\(store.rules(.spend).count))", systemImage: "gift")
                    }
                }

                Section {
                    Button { exporting = true } label: {
                        Label("Export backup", systemImage: "square.and.arrow.up")
                    }
                    Button { importing = true } label: {
                        Label("Import backup", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Data")
                } footer: {
                    Text("Everything is stored on this device only — nothing is uploaded anywhere. Export a backup before switching phones.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { rateText = Format.mb(store.rate) }
            .onChange(of: rateText) { _ in commitRate() }
            .sheet(item: $editingKid) { kid in KidEditor(kid: kid) }
            .sheet(isPresented: $addingKid) { KidEditor(kid: nil) }
            .fileExporter(isPresented: $exporting,
                          document: BackupDocument(data: store.exportJSON()),
                          contentType: .json,
                          defaultFilename: "mills-bucks-\(Self.stamp())") { _ in }
            .fileImporter(isPresented: $importing,
                          allowedContentTypes: [.json]) { result in
                do {
                    let url = try result.get()
                    let scoped = url.startAccessingSecurityScopedResource()
                    defer { if scoped { url.stopAccessingSecurityScopedResource() } }
                    try store.importJSON(try Data(contentsOf: url))
                    rateText = Format.mb(store.rate)
                } catch {
                    importError = "That file could not be read as a Mills Bucks backup."
                }
            }
            .alert("Import failed", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } })) {
                Button("OK") { importError = nil }
            } message: {
                Text(importError ?? "")
            }
        }
    }

    private func commitRate() {
        guard let value = Double(rateText.replacingOccurrences(of: ",", with: ".")),
              value > 0, value.isFinite else { return }
        store.setRate(value)
    }

    private static func stamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Kid editor

struct KidEditor: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    /// nil means "create a new kid".
    let kid: Kid?

    @State private var name = ""
    @State private var emoji = "⭐️"
    @State private var confirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("First name", text: $name)
                    TextField("Emoji", text: $emoji)
                }
                if let kid = kid, store.kids.count > 1 {
                    Section {
                        Button(role: .destructive) { confirmingDelete = true } label: {
                            Label("Remove \(kid.name) and all entries", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(kid == nil ? "Add a Kid" : "Edit Kid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold)
                }
            }
            .onAppear {
                if let kid = kid { name = kid.name; emoji = kid.emoji }
            }
            .confirmationDialog("Remove this kid?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Remove and delete every entry", role: .destructive) {
                    if let kid = kid { store.deleteKid(kid) }
                    dismiss()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
        if let existing = kid {
            var updated = existing
            updated.name = trimmedName.isEmpty ? "Kid" : trimmedName
            updated.emoji = trimmedEmoji.isEmpty ? "⭐️" : trimmedEmoji
            store.update(kid: updated)
        } else {
            store.addKid(name: trimmedName, emoji: trimmedEmoji)
        }
        dismiss()
    }
}

// MARK: - Catalog editor

struct RuleListView: View {
    @EnvironmentObject private var store: Store
    let kind: EntryKind

    @State private var editing: Rule?
    @State private var adding = false

    var body: some View {
        List {
            Section {
                ForEach(store.rules(kind)) { rule in
                    Button { editing = rule } label: { RuleRow(rule: rule, kind: kind) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    let rules = store.rules(kind)
                    for index in offsets { store.deleteRule(id: rules[index].id, kind: kind) }
                }
            } footer: {
                Text("Tap a rule to change what it is worth. Swipe to delete.")
            }
        }
        .navigationTitle(kind == .earn ? "Earning Rules" : "Spending Rules")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { adding = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(item: $editing) { rule in RuleEditor(rule: rule, kind: kind) }
        .sheet(isPresented: $adding) { RuleEditor(rule: nil, kind: kind) }
    }
}

struct RuleEditor: View {
    @EnvironmentObject private var store: Store
    @Environment(\.dismiss) private var dismiss

    /// nil means "create a new rule".
    let rule: Rule?
    let kind: EntryKind

    @State private var title = ""
    @State private var amountText = ""
    @State private var emoji = ""
    @State private var categoryID: String = ""

    private var amount: Double? {
        guard let v = Double(amountText.replacingOccurrences(of: ",", with: ".")), v > 0, v.isFinite else { return nil }
        return (v * 100).rounded() / 100
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("What earns it", text: $title)
                    TextField("Mills Bucks", text: $amountText)
                        .keyboardType(.decimalPad)
                    TextField("Emoji", text: $emoji)
                }
                if kind == .earn {
                    Section("Category") {
                        Picker("Category", selection: $categoryID) {
                            ForEach(store.data.categories) { c in
                                Text("\(c.emoji) \(c.name)").tag(c.id)
                            }
                        }
                        .labelsHidden()
                    }
                }
                if let amount = amount {
                    Section {
                        HStack {
                            Text("Worth")
                            Spacer()
                            Text(Format.usd(amount, rate: store.rate))
                                .font(.body.weight(.bold).monospacedDigit())
                        }
                    }
                }
            }
            .navigationTitle(rule == nil ? "New Rule" : "Edit Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(amount == nil)
                }
            }
            .onAppear {
                if let rule = rule {
                    title = rule.title
                    amountText = Format.mb(rule.amount)
                    emoji = rule.emoji
                    categoryID = rule.categoryID ?? store.data.categories.first?.id ?? ""
                } else {
                    emoji = kind == .earn ? "⭐️" : "🎁"
                    categoryID = store.data.categories.first?.id ?? ""
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func save() {
        guard let amount = amount else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)
        var updated = rule ?? Rule(title: "", amount: amount, emoji: "", categoryID: nil)
        updated.title = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle
        updated.amount = amount
        updated.emoji = trimmedEmoji.isEmpty ? (kind == .earn ? "⭐️" : "🎁") : trimmedEmoji
        updated.categoryID = kind == .earn ? categoryID : nil
        store.upsert(rule: updated, kind: kind)
        dismiss()
    }
}
