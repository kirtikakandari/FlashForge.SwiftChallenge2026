
import SwiftUI

struct HeatmapView: View {
    var tracker = ReviewTracker.shared

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.subheadline)

                Text("Insights")
                    .font(.headline)
                    .foregroundStyle(Color(.label))
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(last30Days().enumerated()), id: \.element) { index, date in
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color(for: tracker.reviews(for: date)))
                        .frame(height: 20)
                        .opacity(appeared ? 1 : 0.2)
                        .scaleEffect(appeared ? 1 : 0.8)
                        .animation(.easeInOut(duration: 0.22).delay(Double(index) * 0.015), value: appeared)
                }
            }

            HStack(spacing: 4) {
                Text("Less")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(.secondaryLabel))

                ForEach([0, 1, 3, 6], id: \.self) { count in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(color(for: count))
                        .frame(width: 12, height: 12)
                }

                Text("More")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.25)) {
                appeared = true
            }
        }
    }

    private func last30Days() -> [Date] {
        (0..<30).map { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
        }.reversed()
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0:
            return Color(.systemGray5)
        case 1...2:
            return Color.accentColor.opacity(0.35)
        case 3...5:
            return Color.accentColor.opacity(0.6)
        default:
            return Color.accentColor.opacity(0.85)
        }
    }
}

#Preview {
    HeatmapView()
        .preferredColorScheme(.light)
        .padding()
        .background(Color(.systemGroupedBackground))
}
