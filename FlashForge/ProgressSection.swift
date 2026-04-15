
import SwiftUI

struct ProgressSectionView: View {
    var tracker = ReviewTracker.shared

    var body: some View {
        let total = totalReviews()
        let streak = currentStreak()

        VStack(alignment: .leading, spacing: 14) {
            HeatmapView()

            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: 36, height: 36)
                        Image(systemName: "book.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total Reviews")
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))

                        Text("\(total)")
                            .font(.title3.bold())
                            .foregroundStyle(Color(.label))
                            .contentTransition(.numericText())
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )

                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(.tertiarySystemBackground))
                            .frame(width: 36, height: 36)
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.accentColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Streak")
                            .font(.caption)
                            .foregroundStyle(Color(.secondaryLabel))

                        Text("\(streak) days")
                            .font(.title3.bold())
                            .foregroundStyle(Color(.label))
                            .contentTransition(.numericText())
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(.tertiarySystemBackground))
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: total)
        .animation(.easeInOut(duration: 0.2), value: streak)
    }

    private func totalReviews() -> Int {
        tracker.dailyReviews.values.reduce(0, +)
    }

    private func currentStreak() -> Int {
        var streak = 0

        for offset in 0..<365 {
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            if tracker.reviews(for: date) > 0 {
                streak += 1
            } else {
                break
            }
        }

        return streak
    }
}

#Preview {
    ProgressSectionView()
        .preferredColorScheme(.light)
        .padding()
        .background(Color(.systemGroupedBackground))
}
