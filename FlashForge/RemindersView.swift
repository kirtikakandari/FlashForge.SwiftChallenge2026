
import SwiftUI

struct RemindersView: View {
    @Binding var flashcards: [Flashcard]
    @Binding var weeklyEnabled: Bool
    @Binding var monthlyEnabled: Bool

    @State private var selectedIndex: Int?

    enum ReminderType {
        case weekly
        case monthly
        case custom
    }

    private var weeklyIndices: [Int] {
        let now = Date()
        return flashcards.indices
            .filter { index in
                weeklyEnabled &&
                    (flashcards[index].weeklyReminderDate?.timeIntervalSince(now) ?? -1) > 0
            }
            .sorted {
                (flashcards[$0].weeklyReminderDate ?? .distantFuture) <
                    (flashcards[$1].weeklyReminderDate ?? .distantFuture)
            }
    }

    private var monthlyIndices: [Int] {
        let now = Date()
        return flashcards.indices
            .filter { index in
                monthlyEnabled &&
                    (flashcards[index].monthlyReminderDate?.timeIntervalSince(now) ?? -1) > 0
            }
            .sorted {
                (flashcards[$0].monthlyReminderDate ?? .distantFuture) <
                    (flashcards[$1].monthlyReminderDate ?? .distantFuture)
            }
    }

    private var customIndices: [Int] {
        let now = Date()
        return flashcards.indices
            .filter { index in
                flashcards[index].reminderFrequency == .custom &&
                    (flashcards[index].customReminderDate?.timeIntervalSince(now) ?? -1) > 0
            }
            .sorted {
                (flashcards[$0].customReminderDate ?? .distantFuture) <
                    (flashcards[$1].customReminderDate ?? .distantFuture)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 0) {
                        toggleRow(
                            title: "Weekly Revision",
                            subtitle: "Review every 7 days",
                            icon: "calendar.badge.clock",
                            color: .accentColor,
                            isOn: $weeklyEnabled
                        )
                        .onChange(of: weeklyEnabled) { _, newValue in
                            let now = Date()
                            if newValue {
                                for index in flashcards.indices {
                                    if flashcards[index].weeklyReminderDate == nil {
                                        flashcards[index].weeklyReminderDate =
                                            Calendar.current.date(byAdding: .day, value: 7, to: now)
                                    }
                                }
                            } else {
                                for index in flashcards.indices {
                                    flashcards[index].weeklyReminderDate = nil
                                }
                            }
                        }

                        Divider()

                        toggleRow(
                            title: "Monthly Revision",
                            subtitle: "Review every 29 days",
                            icon: "calendar",
                            color: .accentColor,
                            isOn: $monthlyEnabled
                        )
                        .onChange(of: monthlyEnabled) { _, newValue in
                            let now = Date()
                            if newValue {
                                for index in flashcards.indices {
                                    if flashcards[index].monthlyReminderDate == nil {
                                        flashcards[index].monthlyReminderDate =
                                            Calendar.current.date(byAdding: .day, value: 29, to: now)
                                    }
                                }
                            } else {
                                for index in flashcards.indices {
                                    flashcards[index].monthlyReminderDate = nil
                                }
                            }
                        }
                    }
                    .glassCard(cornerRadius: 18)

                    reminderSection(
                        title: "Weekly Reminders",
                        icon: "clock.arrow.circlepath",
                        color: .accentColor,
                        gradient: AppTheme.primaryGradient,
                        indices: weeklyIndices,
                        emptyText: "No weekly reminders",
                        type: .weekly
                    ) { index in
                        flashcards[index].weeklyReminderDate
                    }

                    reminderSection(
                        title: "Monthly Reminders",
                        icon: "calendar.circle",
                        color: .accentColor,
                        gradient: AppTheme.primaryGradient,
                        indices: monthlyIndices,
                        emptyText: "No monthly reminders",
                        type: .monthly
                    ) { index in
                        flashcards[index].monthlyReminderDate
                    }

                    reminderSection(
                        title: "Custom Reminders",
                        icon: "star.circle",
                        color: .accentColor,
                        gradient: AppTheme.primaryGradient,
                        indices: customIndices,
                        emptyText: "No custom reminders",
                        type: .custom
                    ) { index in
                        flashcards[index].customReminderDate
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .gradientBackground()
            .navigationTitle("Reminders")
            .sheet(isPresented: Binding(
                get: { selectedIndex != nil },
                set: { if !$0 { selectedIndex = nil } }
            )) {
                if let index = selectedIndex {
                    FlashcardDetailSheet(card: $flashcards[index])
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    private func toggleRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color(.label))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.accentColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func reminderSection(
        title: String,
        icon: String,
        color: Color,
        gradient: LinearGradient,
        indices: [Int],
        emptyText: String,
        type: ReminderType,
        dateFor: @escaping (Int) -> Date?
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color(.label))

                Spacer()

                Text("\(indices.count)")
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }

            if indices.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "tray")
                            .font(.title3)
                            .foregroundStyle(Color(.tertiaryLabel))
                        Text(emptyText)
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(indices, id: \.self) { index in
                    reminderRow(
                        index: index,
                        date: dateFor(index),
                        color: color,
                        gradient: gradient,
                        type: type
                    )
                }
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    private func reminderRow(
        index: Int,
        date: Date?,
        color: Color,
        gradient: LinearGradient,
        type: ReminderType
    ) -> some View {
        Button {
            switch type {
            case .weekly:
                flashcards[index].weeklyReminderDate = nil
            case .monthly:
                flashcards[index].monthlyReminderDate = nil
            case .custom:
                break
            }

            selectedIndex = index
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(gradient)
                    .frame(width: 3, height: 36)

                Text(flashcards[index].question)
                    .font(.subheadline)
                    .foregroundStyle(Color(.label))
                    .lineLimit(2)

                Spacer()

                if let date = date {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundStyle(color)

                        Text(date, style: .time)
                            .font(.caption2)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.tertiarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(selectedIndex == index ? 0.97 : 1)
        .animation(.easeInOut(duration: 0.15), value: selectedIndex)
    }
}
