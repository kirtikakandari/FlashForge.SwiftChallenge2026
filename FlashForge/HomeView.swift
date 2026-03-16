import SwiftUI

struct HomeView: View {
    @Binding var flashcards: [Flashcard]
    @Binding var selectedTab: ContentView.RecallTab
    @Binding var weeklyEnabled: Bool
    @Binding var monthlyEnabled: Bool

    @State private var question = ""
    @State private var answer = ""
    @StateObject private var aiService = AIStudyService()

    @State private var headerOpacity: Double = 0
    @State private var formOpacity: Double = 0
    @FocusState private var focusedField: FocusField?

    private enum FocusField {
        case question
        case answer
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("FlashForge")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color(.label))

                        Text("Create a new card and keep your study flow going.")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                    .opacity(headerOpacity)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("New Flashcard")
                            .font(.headline)
                            .foregroundStyle(Color(.label))

                        TextField("Question or keyword", text: $question)
                            .themedTextField()
                            .focused($focusedField, equals: .question)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        focusedField == .question
                                            ? Color.accentColor.opacity(0.35)
                                            : Color.clear,
                                        lineWidth: 1.3
                                    )
                            )
                            .onChange(of: question) { _, newValue in
                                if newValue.count > 3 {
                                    Task {
                                        await aiService.generateQuestions(from: newValue)
                                    }
                                }
                            }

                        if aiService.isLoading {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.accentColor)
                                Text("Generating suggestions")
                                    .font(.footnote)
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                            .padding(.horizontal, 2)
                            .transition(.opacity)
                        }

                        if !aiService.questions.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Suggested Questions")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color(.secondaryLabel))

                                ForEach(Array(aiService.questions.enumerated()), id: \.offset) { _, suggestion in
                                    Button {
                                        Task {
                                            question = suggestion
                                            answer = await aiService.generateAnswer(for: suggestion)
                                        }
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: "sparkle")
                                                .foregroundStyle(Color.accentColor)

                                            Text(suggestion)
                                                .font(.subheadline)
                                                .foregroundStyle(Color(.label))
                                                .multilineTextAlignment(.leading)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color(.tertiaryLabel))
                                        }
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Color(.tertiarySystemBackground))
                                        )
                                    }
                                    .buttonStyle(PressFeedbackButtonStyle())
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .animation(.easeInOut(duration: 0.2), value: aiService.questions)
                        }

                        TextEditor(text: $answer)
                            .frame(minHeight: 120)
                            .padding(8)
                            .focused($focusedField, equals: .answer)
                            .scrollContentBackground(.hidden)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        focusedField == .answer
                                            ? Color.accentColor.opacity(0.35)
                                            : Color(.separator).opacity(0.2),
                                        lineWidth: focusedField == .answer ? 1.3 : 0.8
                                    )
                            )
                            .foregroundStyle(Color(.label))

                        Button(action: {
                            guard !question.isEmpty && !answer.isEmpty else { return }

                            let now = Date()

                            let newCard = Flashcard(
                                question: question,
                                answer: answer,
                                weeklyReminderDate: weeklyEnabled
                                    ? Calendar.current.date(byAdding: .day, value: 7, to: now)
                                    : nil,
                                monthlyReminderDate: monthlyEnabled
                                    ? Calendar.current.date(byAdding: .day, value: 29, to: now)
                                    : nil
                            )

                            flashcards.append(newCard)

                            question = ""
                            answer = ""

                            selectedTab = .flashcards
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Generate Flashcard")
                                    .fontWeight(.semibold)
                            }
                            .primaryButtonStyle(isDisabled: question.isEmpty || answer.isEmpty)
                        }
                        .buttonStyle(PressFeedbackButtonStyle())
                        .disabled(question.isEmpty || answer.isEmpty)
                    }
                    .padding(18)
                    .glassCard(cornerRadius: 20)
                    .opacity(formOpacity)

                    ProgressSectionView()
                        .glassCard(cornerRadius: 20)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .gradientBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.35)) {
                headerOpacity = 1
                formOpacity = 1
            }
        }
        .simulatorSafeSensoryFeedback(.selection, trigger: aiService.questions.count)
    }
}

#Preview {
    HomeView(
        flashcards: .constant([]),
        selectedTab: .constant(.home),
        weeklyEnabled: .constant(true),
        monthlyEnabled: .constant(true)
    )
    .preferredColorScheme(.light)
}
