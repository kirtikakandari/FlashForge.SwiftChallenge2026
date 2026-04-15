
import SwiftUI

@Observable
class ReviewTracker {
    
    static let shared = ReviewTracker()
    
    var dailyReviews: [String: Int] = [:]
    
    private let storageKey = "dailyReviewCounts"
    
    private init() {
        load()
    }
    
    func recordReview() {
        let todayKey = dateKey(for: Date())
        dailyReviews[todayKey, default: 0] += 1
        save()
    }
    
    func reviews(for date: Date) -> Int {
        let key = dateKey(for: date)
        return dailyReviews[key] ?? 0
    }
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func save() {
        UserDefaults.standard.set(dailyReviews, forKey: storageKey)
    }
    
    private func load() {
        if let saved = UserDefaults.standard.dictionary(forKey: storageKey) as? [String: Int] {
            dailyReviews = saved
        }
    }
}
