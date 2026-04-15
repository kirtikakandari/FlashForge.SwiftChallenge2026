
import Foundation

enum RecallTab: Hashable {
    case home
    case flashcards
    case reminders
}

enum ReminderFrequency: String, CaseIterable, Codable {
    case none
    case weekly
    case monthly
    case custom
}

struct Flashcard: Identifiable, Equatable, Codable {

    let id: UUID
    var question: String
    var answer: String
    var createdAt: Date
    var cardColorIndex: Int?
    var imageData: Data?

    var groupID: UUID?
    var groupName: String?

    var reminderFrequency: ReminderFrequency
    var customReminderDate: Date?
    var weeklyReminderDate: Date?
    var monthlyReminderDate: Date?

    init(
        id: UUID = UUID(),
        question: String,
        answer: String,
        createdAt: Date = Date(),
        cardColorIndex: Int? = nil,
        imageData: Data? = nil,
        groupID: UUID? = nil,
        groupName: String? = nil,
        reminderFrequency: ReminderFrequency = .none,
        customReminderDate: Date? = nil,
        weeklyReminderDate: Date? = nil,
        monthlyReminderDate: Date? = nil
    ) {
        self.id = id
        self.question = question
        self.answer = answer
        self.createdAt = createdAt
        self.cardColorIndex = cardColorIndex
        self.imageData = imageData
        self.groupID = groupID
        self.groupName = groupName
        self.reminderFrequency = reminderFrequency
        self.customReminderDate = customReminderDate
        self.weeklyReminderDate = weeklyReminderDate
        self.monthlyReminderDate = monthlyReminderDate
    }
}
