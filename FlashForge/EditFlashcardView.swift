
import SwiftUI
import PhotosUI
import UIKit

struct EditFlashcardView: View {
    @Binding var card: Flashcard
    @Environment(\.dismiss) private var dismiss

    @State private var editedQuestion: String = ""
    @State private var editedAnswer: String = ""
    @State private var editedColorIndex: Int? = nil
    @State private var editedImageData: Data? = nil
    @State private var selectedPhotoItem: PhotosPickerItem?

    private let cardColors: [Color] = [
        Color(.systemBlue),
        Color(.systemIndigo),
        Color(.systemTeal),
        Color(.systemMint),
        Color(.systemOrange),
        Color(.systemPink)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(.secondaryLabel))

                        TextField("Edit Question", text: $editedQuestion)
                            .themedTextField()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Answer")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(.secondaryLabel))

                        TextField("Edit Answer", text: $editedAnswer)
                            .themedTextField()
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Card Color")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(.secondaryLabel))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                Button {
                                    editedColorIndex = nil
                                } label: {
                                    Text("Auto")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(editedColorIndex == nil ? Color.white : Color(.label))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 9)
                                        .background(
                                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                                .fill(editedColorIndex == nil ? Color.accentColor : Color(.secondarySystemBackground))
                                        )
                                }
                                .buttonStyle(PressFeedbackButtonStyle())

                                ForEach(cardColors.indices, id: \.self) { index in
                                    Button {
                                        editedColorIndex = index
                                    } label: {
                                        Circle()
                                            .fill(cardColors[index])
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        editedColorIndex == index
                                                            ? Color(.label)
                                                            : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    }
                                    .buttonStyle(PressFeedbackButtonStyle())
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Card Image")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(.secondaryLabel))

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Choose Photo", systemImage: "photo.on.rectangle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(.label))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color(.secondarySystemBackground))
                                )
                        }
                        .buttonStyle(PressFeedbackButtonStyle())

                        if let data = editedImageData,
                           let image = UIImage(data: data) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 160)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                                Button {
                                    editedImageData = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundStyle(Color.white.opacity(0.95))
                                        .padding(8)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .gradientBackground()
            .navigationTitle("Edit Flashcard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        card.question = editedQuestion
                        card.answer = editedAnswer
                        card.cardColorIndex = editedColorIndex
                        card.imageData = editedImageData
                        dismiss()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        }
        .onAppear {
            editedQuestion = card.question
            editedAnswer = card.answer
            editedColorIndex = card.cardColorIndex
            editedImageData = card.imageData
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        editedImageData = data
                    }
                }
            }
        }
    }
}

#Preview {
    EditFlashcardView(
        card: .constant(
            Flashcard(question: "Edit Question",
                      answer: "Edit Answer")
        )
    )
    .preferredColorScheme(.light)
}
