
import SwiftUI

struct ContentView: View {
    enum RecallTab: Hashable {
        case home
        case flashcards
        case reminders
    }

    @State private var flashcards: [Flashcard] = []
    @State private var selectedTab: RecallTab = .home

    @State private var isWeeklyReminderEnabled: Bool = false
    @State private var isMonthlyReminderEnabled: Bool = false
    @State private var hasLoadedFlashcards = false

    private let flashcardsStorageKey = "flashforge.flashcards.v1"

    private var upcomingCount: Int {
        let now = Date()
        return flashcards.filter { card in
            let frequencyMatches: Bool = {
                switch card.reminderFrequency {
                case .none:
                    return false
                case .custom:
                    if let date = card.customReminderDate { return date > now }
                    return false
                default:
                    return true
                }
            }()

            let hasFutureScheduledDates =
                (card.weeklyReminderDate?.timeIntervalSince(now) ?? -1) > 0 ||
                (card.monthlyReminderDate?.timeIntervalSince(now) ?? -1) > 0

            return frequencyMatches || hasFutureScheduledDates
        }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                flashcards: $flashcards,
                selectedTab: $selectedTab,
                weeklyEnabled: $isWeeklyReminderEnabled,
                monthlyEnabled: $isMonthlyReminderEnabled
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(RecallTab.home)

            FlashcardsView(
                flashcards: $flashcards
            )
            .tabItem {
                Label("Flashcards", systemImage: "square.stack.3d.up.fill")
            }
            .tag(RecallTab.flashcards)

            RemindersView(
                flashcards: $flashcards,
                weeklyEnabled: $isWeeklyReminderEnabled,
                monthlyEnabled: $isMonthlyReminderEnabled
            )
            .tabItem {
                Label("Reminders", systemImage: "bell.fill")
            }
            .badge(upcomingCount)
            .tag(RecallTab.reminders)
        }
        .tint(.accentColor)
        .preferredColorScheme(.light)
        .onAppear {
            loadFlashcardsIfNeeded()
        }
        .onChange(of: flashcards) { _, newCards in
            guard hasLoadedFlashcards else { return }
            saveFlashcards(newCards)
        }
    }

    private func loadFlashcardsIfNeeded() {
        guard !hasLoadedFlashcards else { return }
        defer { hasLoadedFlashcards = true }

        guard
            let data = UserDefaults.standard.data(forKey: flashcardsStorageKey),
            let decoded = try? JSONDecoder().decode([Flashcard].self, from: data)
        else {
            return
        }

        flashcards = decoded
    }

    private func saveFlashcards(_ cards: [Flashcard]) {
        guard let encoded = try? JSONEncoder().encode(cards) else { return }
        UserDefaults.standard.set(encoded, forKey: flashcardsStorageKey)
    }
}

#Preview {
    ContentView()
}
