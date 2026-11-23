import Foundation

/// Starter catalog. Generated from scoring.json — edit that file and re-run
/// tools/gen_catalog.py rather than hand-editing this one.
enum Catalog {

    static let defaultRate: Double = 2.25

    static let categories: [RewardCategory] = [
        RewardCategory(id: "reading", name: "Reading", emoji: "📚"),
        RewardCategory(id: "academics", name: "School", emoji: "🎓"),
        RewardCategory(id: "sports", name: "Sports & Activities", emoji: "⚽"),
        RewardCategory(id: "home", name: "Home & Character", emoji: "🏡"),
    ]

    static let earnRules: [Rule] = [
        Rule(id: "r_story", title: "Read a short storybook", amount: 1, emoji: "📖", categoryID: "reading"),
        Rule(id: "r_readaloud", title: "Read aloud 20 minutes", amount: 1, emoji: "🗣️", categoryID: "reading"),
        Rule(id: "r_chapter", title: "Read a chapter book chapter", amount: 1.5, emoji: "📗", categoryID: "reading"),
        Rule(id: "r_finishbook", title: "Finish a chapter book", amount: 5, emoji: "🏁", categoryID: "reading"),
        Rule(id: "r_bookreport", title: "Write a book report", amount: 3, emoji: "✍️", categoryID: "reading"),
        Rule(id: "a_assign_a", title: "A on an assignment", amount: 1.5, emoji: "🅰️", categoryID: "academics"),
        Rule(id: "a_assign_b", title: "B on an assignment", amount: 0.75, emoji: "🅱️", categoryID: "academics"),
        Rule(id: "a_test_a", title: "A on a test", amount: 4, emoji: "📝", categoryID: "academics"),
        Rule(id: "a_test_b", title: "B on a test", amount: 2, emoji: "📄", categoryID: "academics"),
        Rule(id: "a_homework", title: "Homework all week, no nagging", amount: 3, emoji: "✅", categoryID: "academics"),
        Rule(id: "a_practice", title: "Study/math practice 20 min", amount: 1, emoji: "✏️", categoryID: "academics"),
        Rule(id: "a_report_a", title: "A on report card (per subject)", amount: 10, emoji: "🌟", categoryID: "academics"),
        Rule(id: "a_attendance", title: "Perfect attendance (term)", amount: 8, emoji: "📅", categoryID: "academics"),
        Rule(id: "s_practice", title: "Attend practice", amount: 0.5, emoji: "🏃", categoryID: "sports"),
        Rule(id: "s_game", title: "Play a game", amount: 1, emoji: "🥅", categoryID: "sports"),
        Rule(id: "s_win", title: "Win a game", amount: 2, emoji: "💪", categoryID: "sports"),
        Rule(id: "s_mvp", title: "Game ball / team MVP", amount: 10, emoji: "🏅", categoryID: "sports"),
        Rule(id: "s_tournament", title: "Win a tournament", amount: 25, emoji: "🥈", categoryID: "sports"),
        Rule(id: "s_championship", title: "Win a championship", amount: 100, emoji: "🏆", categoryID: "sports"),
        Rule(id: "h_chores", title: "Chores all week, no reminders", amount: 2, emoji: "🧹", categoryID: "home"),
        Rule(id: "h_room", title: "Room clean all week", amount: 1.5, emoji: "🛏️", categoryID: "home"),
        Rule(id: "h_helping", title: "Helped without being asked", amount: 1, emoji: "🤝", categoryID: "home"),
        Rule(id: "h_kindness", title: "Caught being kind", amount: 1, emoji: "❤️", categoryID: "home"),
    ]

    static let spendRules: [Rule] = [
        Rule(id: "p_cash1", title: "Cash out 1 Mills Buck", amount: 1, emoji: "💵", categoryID: nil),
        Rule(id: "p_cash5", title: "Cash out 5 Mills Bucks", amount: 5, emoji: "💰", categoryID: nil),
        Rule(id: "p_screen30", title: "30 min extra screen time", amount: 1, emoji: "📱", categoryID: nil),
        Rule(id: "p_screen60", title: "1 hour extra screen time", amount: 2, emoji: "🎮", categoryID: nil),
        Rule(id: "p_dinner", title: "Pick dinner", amount: 2, emoji: "🍕", categoryID: nil),
        Rule(id: "p_movie", title: "Pick movie night", amount: 2, emoji: "🎬", categoryID: nil),
        Rule(id: "p_latenight", title: "Stay up 30 min late", amount: 2, emoji: "🌙", categoryID: nil),
        Rule(id: "p_treat", title: "Ice cream / treat run", amount: 3, emoji: "🍦", categoryID: nil),
        Rule(id: "p_outing", title: "Park / arcade trip", amount: 6, emoji: "🎡", categoryID: nil),
        Rule(id: "p_smalltoy", title: "Small toy (~$20)", amount: 9, emoji: "🧸", categoryID: nil),
        Rule(id: "p_bigtoy", title: "Big toy / game (~$50)", amount: 22, emoji: "🎁", categoryID: nil),
        Rule(id: "p_dayout", title: "Day out, kid's choice", amount: 30, emoji: "🌞", categoryID: nil),
    ]

    static func starterData() -> AppData {
        let kid = Kid(name: "My Kid")
        return AppData(rate: defaultRate,
                       kids: [kid],
                       activeKidID: kid.id,
                       entries: [],
                       earnRules: earnRules,
                       spendRules: spendRules,
                       categories: categories)
    }
}
