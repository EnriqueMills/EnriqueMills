import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            EarnView()
                .tabItem { Label("Earn", systemImage: "plus.circle.fill") }
            SpendView()
                .tabItem { Label("Spend", systemImage: "gift.fill") }
            HistoryView()
                .tabItem { Label("History", systemImage: "list.bullet.rectangle.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

// MARK: - Shared pieces

/// Chip row for switching kids. Hidden entirely when there is only one.
struct KidPicker: View {
    @EnvironmentObject private var store: Store

    var body: some View {
        if store.kids.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.kids) { kid in
                        let selected = kid.id == store.activeKid.id
                        Button {
                            store.select(kid: kid)
                        } label: {
                            Text("\(kid.emoji) \(kid.name)")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(selected ? Color.accentColor : Color(.secondarySystemBackground),
                                            in: Capsule())
                                .foregroundStyle(selected ? Color.white : Color.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct BalanceHeader: View {
    @EnvironmentObject private var store: Store
    var compact = false

    private var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    }

    var body: some View {
        VStack(spacing: compact ? 2 : 6) {
            KidPicker()
                .padding(.bottom, compact ? 4 : 8)

            Text(Format.mb(store.balance))
                .font(.system(size: compact ? 36 : 54, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(store.balance < 0 ? Color.red : Color.primary)

            Text("MILLS BUCKS")
                .font(.caption2.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(.secondary)

            Text("\(Format.usd(store.balance, rate: store.rate)) value")
                .font(compact ? .subheadline : .headline)
                .foregroundStyle(.secondary)

            if !compact {
                HStack(spacing: 8) {
                    StatTile(value: "+" + Format.mb(store.total(.earn, since: monthStart)),
                             label: "earned this month")
                    StatTile(value: "−" + Format.mb(store.total(.spend, since: monthStart)),
                             label: "spent this month")
                    StatTile(value: Format.mb(store.lifetimeEarned),
                             label: "earned all time")
                }
                .padding(.top, 10)
                .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 10 : 14)
    }
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
            Text(label)
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// A catalog rule shown as a tappable row.
struct RuleRow: View {
    @EnvironmentObject private var store: Store
    let rule: Rule
    let kind: EntryKind

    var body: some View {
        HStack(spacing: 12) {
            Text(rule.emoji).font(.title2).frame(width: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(rule.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(Format.usd(rule.amount, rate: store.rate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(Format.signedMB(rule.amount, kind: kind))
                .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(kind == .earn ? Color.accentColor : Color.orange)
        }
        .contentShape(Rectangle())
    }
}

/// A ledger line.
struct EntryRow: View {
    let entry: LedgerEntry

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.emoji).font(.title2).frame(width: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text(entry.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(Format.signedMB(entry.amount, kind: entry.kind))
                .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(entry.kind == .earn ? Color.accentColor : Color.orange)
        }
        .contentShape(Rectangle())
    }

    private var subtitle: String {
        var parts = [Format.dayLabel(entry.date), Format.time(entry.date)]
        if !entry.note.isEmpty { parts.append(entry.note) }
        return parts.joined(separator: " · ")
    }
}
