
import SwiftUI
import AVFoundation
import UIKit

struct FlashcardDetailSheet: View {
    @Binding var card: Flashcard
    @State private var isFlipped = false
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss

    private let synthesizer = AVSpeechSynthesizer()

    @State private var cardAppeared = false

    private var questionTone: Color {
        let tones: [Color] = [
            Color(.systemBlue),
            Color(.systemIndigo),
            Color(.systemTeal),
            Color(.systemMint),
            Color(.systemOrange),
            Color(.systemPink)
        ]
        if let customIndex = card.cardColorIndex {
            return tones[customIndex % tones.count]
        }
        let total = card.id.uuidString.unicodeScalars.reduce(into: 0) { partialResult, scalar in
            partialResult += Int(scalar.value)
        }
        return tones[total % tones.count]
    }

    private var questionImage: UIImage? {
        guard let data = card.imageData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(.secondaryLabel))
                        .padding(10)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Circle())
                }

                Spacer()

                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Spacer(minLength: 0)

            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [questionTone.opacity(0.2), Color(.secondarySystemBackground)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ZStack {
                                if let questionImage {
                                    Image(uiImage: questionImage)
                                        .resizable()
                                        .scaledToFill()
                                        .opacity(0.25)
                                }

                                VStack(spacing: 12) {
                                    Image(systemName: "questionmark.circle")
                                        .font(.title3)
                                        .foregroundStyle(questionTone)

                                    Text(card.question)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(Color(.label))
                                        .padding(.horizontal)
                                        .multilineTextAlignment(.center)
                                        .minimumScaleFactor(0.7)
                                }
                            }
                        )
                        .clipped()
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(questionTone.opacity(0.28), lineWidth: 0.9)
                        )
                        .opacity(isFlipped ? 0 : 1)

                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle")
                                    .font(.title3)
                                    .foregroundStyle(Color(.tertiaryLabel))

                                Text(card.answer)
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(Color(.label))
                                    .padding(.horizontal)
                                    .multilineTextAlignment(.center)
                                    .minimumScaleFactor(0.7)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color(.separator).opacity(0.2), lineWidth: 0.8)
                        )
                        .opacity(isFlipped ? 1 : 0)
                        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 248)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.55
                )
                .animation(.easeInOut(duration: 0.35), value: isFlipped)
                .shadow(color: Color.black.opacity(0.08), radius: 14, x: 0, y: 7)
                .onTapGesture {
                    isFlipped.toggle()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        Button {
                            speakCurrentSide()
                        } label: {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.accentColor)
                                .padding(12)
                                .background(Color(.systemBackground).opacity(0.95))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 3)
                        }
                        .padding(14)
                    }
                }
                .frame(height: 248)
            }
            .padding(.horizontal, 16)
            .scaleEffect(cardAppeared ? 1 : 0.97)
            .opacity(cardAppeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.28)) {
                    cardAppeared = true
                }
            }

            Text("Tap card to flip")
                .font(.caption)
                .foregroundStyle(Color(.secondaryLabel))

            VStack(spacing: 14) {
                Toggle(isOn: Binding(
                    get: { card.reminderFrequency == .custom },
                    set: { newValue in
                        if newValue {
                            card.reminderFrequency = .custom
                            if card.customReminderDate == nil {
                                card.customReminderDate = Date().addingTimeInterval(3600)
                            }
                        } else {
                            card.reminderFrequency = .none
                            card.customReminderDate = nil
                        }
                    }
                )) {
                    Label("Enable Reminder", systemImage: "bell.badge")
                        .foregroundStyle(Color(.label))
                }
                .tint(.accentColor)

                if card.reminderFrequency == .custom,
                   let customDate = card.customReminderDate {
                    DatePicker(
                        "Select Date",
                        selection: Binding(
                            get: { customDate },
                            set: { card.customReminderDate = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(.accentColor)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 18)
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .onAppear {
            ReviewTracker.shared.recordReview()
        }
        .gradientBackground()
        .sheet(isPresented: $isEditing) {
            EditFlashcardView(card: $card)
                .presentationDetents([.medium, .large])
        }
    }

    private func speakCurrentSide() {
        let text = isFlipped ? card.answer : card.question

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5

        synthesizer.speak(utterance)
    }
}

#Preview {
    FlashcardDetailSheet(
        card: .constant(
            Flashcard(
                question: "What is SwiftUI?",
                answer: "A declarative framework for building UI across Apple platforms."
            )
        )
    )
    .preferredColorScheme(.light)
}
