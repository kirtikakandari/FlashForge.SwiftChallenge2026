
import SwiftUI
import Combine

struct FlashcardsView: View {
    @Binding var flashcards: [Flashcard]

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @StateObject private var quizProgressStore = QuizProgressStore()
    @State private var selectedCard: Flashcard?
    @State private var selectedFolder: SelectedFolder?
    @State private var activeQuiz: QuizSession?
    @State private var selectedIndexForDeletion: Int?
    @State private var showDeleteAlert = false
    @State private var showQuizLauncher = false
    @State private var showQuizAlert = false
    @State private var quizAlertMessage = ""

    @State private var isGroupingMode = false
    @State private var selectedForGrouping: Set<UUID> = []

    @State private var groupCreatedFeedbackToken = 0
    @State private var folderNameInput = ""
    @State private var folderNameTargetID: UUID?
    @State private var showFolderNamePrompt = false
    @State private var folderNamePromptTitle = "Name Folder"

    private var columns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: minimumTileWidth, maximum: maximumTileWidth),
                spacing: 14
            )
        ]
    }

    private var minimumTileWidth: CGFloat {
        if dynamicTypeSize.isAccessibilitySize {
            return 280
        }
        return horizontalSizeClass == .regular ? 210 : 156
    }

    private var maximumTileWidth: CGFloat {
        horizontalSizeClass == .regular ? 300 : 230
    }

    private var tileHeight: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 186 : 164
    }

    private var displayItems: [DisplayItem] {
        var items: [DisplayItem] = []
        var seenGroups: Set<UUID> = []

        let groupCounts = Dictionary(
            grouping: flashcards.compactMap(\.groupID),
            by: { $0 }
        ).mapValues(\.count)

        for card in flashcards {
            if let groupID = card.groupID {
                if seenGroups.insert(groupID).inserted {
                    items.append(
                        DisplayItem(
                            id: "folder-\(groupID.uuidString)",
                            kind: .folder(
                                groupID: groupID,
                                name: folderName(for: groupID),
                                count: groupCounts[groupID] ?? 0,
                                preview: card.question,
                                colorIndex: card.cardColorIndex
                            )
                        )
                    )
                }
            } else {
                items.append(
                    DisplayItem(
                        id: "card-\(card.id.uuidString)",
                        kind: .card(cardID: card.id)
                    )
                )
            }
        }

        return items
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if flashcards.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(.tertiaryLabel))
                            .padding(.top, 72)

                        Text("No Flashcards Yet")
                            .font(.title3.bold())
                            .foregroundStyle(Color(.label))

                        Text("Create your first flashcard from the Home tab")
                            .font(.subheadline)
                            .foregroundStyle(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        if isGroupingMode {
                            Label(
                                "Select at least 2 cards to make a folder",
                                systemImage: "folder.badge.plus"
                            )
                            .font(.footnote)
                            .foregroundStyle(Color(.secondaryLabel))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                            .padding(.horizontal, 16)
                        }

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(displayItems, id: \.id) { item in
                                switch item.kind {
                                case .card(let cardID):
                                    if let index = flashcards.firstIndex(where: { $0.id == cardID }) {
                                        let card = flashcards[index]
                                        let isSelected = selectedForGrouping.contains(card.id)
                                        let palette = palette(for: card.id, customIndex: card.cardColorIndex)

                                        Button {
                                            if isGroupingMode {
                                                toggleGroupingSelection(for: card)
                                            } else {
                                                selectedCard = card
                                            }
                                        } label: {
                                            flashcardTile(
                                                question: card.question,
                                                isSelected: isSelected,
                                                isGroupingMode: isGroupingMode,
                                                palette: palette
                                            )
                                        }
                                        .buttonStyle(InteractiveCardButtonStyle())
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                if let deleteIndex = flashcards.firstIndex(where: { $0.id == card.id }) {
                                                    selectedIndexForDeletion = deleteIndex
                                                    showDeleteAlert = true
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }

                                            Button {
                                                isGroupingMode = true
                                                toggleGroupingSelection(for: card)
                                            } label: {
                                                Label("Group", systemImage: "folder.badge.plus")
                                            }
                                        }
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }

                                case .folder(let groupID, let name, let count, let preview, let colorIndex):
                                    let palette = palette(for: groupID, customIndex: colorIndex)
                                    Button {
                                        if !isGroupingMode {
                                            selectedFolder = SelectedFolder(id: groupID)
                                        }
                                    } label: {
                                        folderTile(
                                            folderName: name,
                                            cardCount: count,
                                            preview: preview,
                                            isDisabled: isGroupingMode,
                                            palette: palette
                                        )
                                    }
                                    .buttonStyle(InteractiveCardButtonStyle())
                                    .contextMenu {
                                        Button {
                                            selectedFolder = SelectedFolder(id: groupID)
                                        } label: {
                                            Label("Open Folder", systemImage: "folder")
                                        }

                                        Button {
                                            ungroupFolder(groupID)
                                        } label: {
                                            Label("Ungroup Folder", systemImage: "folder.badge.minus")
                                        }

                                        Button {
                                            beginFolderNaming(for: groupID, title: "Rename Folder")
                                        } label: {
                                            Label("Rename Folder", systemImage: "pencil")
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.22), value: displayItems.map(\.id))
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
            }
            .gradientBackground()
            .navigationTitle("Flashcards")
            .toolbar {
                if isGroupingMode && selectedForGrouping.count > 1 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            if let groupID = createGroup() {
                                beginFolderNaming(for: groupID, title: "Name Folder")
                            }
                        } label: {
                            Text("Create Folder")
                                .fontWeight(.semibold)
                        }
                    }
                } else if !isGroupingMode {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showQuizLauncher = true
                        } label: {
                            Label("Quiz", systemImage: "plus.circle")
                        }
                    }
                }

                if isGroupingMode {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            cancelGrouping()
                        } label: {
                            Text("Cancel")
                        }
                    }
                }
            }
        }
        .onChange(of: flashcards) { _, newCards in
            let validIDs = Set(newCards.map(\.id))
            selectedForGrouping = selectedForGrouping.intersection(validIDs)
        }
        .sheet(item: $selectedCard) { card in
            if let index = flashcards.firstIndex(where: { $0.id == card.id }) {
                FlashcardDetailSheet(card: $flashcards[index])
            }
        }
        .sheet(item: $selectedFolder) { folder in
            GroupFolderSheet(groupID: folder.id, flashcards: $flashcards)
        }
        .sheet(isPresented: $showQuizLauncher) {
            QuizLauncherSheet(
                flashcards: flashcards,
                progressStore: quizProgressStore
            ) { period in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    startQuiz(for: period)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $activeQuiz) { session in
            QuizSessionSheet(
                session: session,
                allFlashcards: flashcards
            ) { score, total in
                quizProgressStore.record(score: score, total: total, for: session.period)
            }
            .presentationDetents([.large])
        }
        .alert(
            "Delete Flashcard?",
            isPresented: $showDeleteAlert,
            presenting: selectedIndexForDeletion
        ) { index in
            Button("Delete", role: .destructive) {
                flashcards.remove(at: index)
            }

            Button("Cancel", role: .cancel) { }
        } message: { _ in
            Text("This action cannot be undone.")
        }
        .alert("Quiz Not Available", isPresented: $showQuizAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(quizAlertMessage)
        }
        .alert(folderNamePromptTitle, isPresented: $showFolderNamePrompt) {
            TextField("Folder Name", text: $folderNameInput)

            Button("Save") {
                applyFolderName()
            }

            Button("Cancel", role: .cancel) {
                folderNameTargetID = nil
            }
        }
        .simulatorSafeSensoryFeedback(.selection, trigger: selectedForGrouping.count)
        .simulatorSafeSensoryFeedback(.success, trigger: groupCreatedFeedbackToken)
    }
}

extension FlashcardsView {
    private func toggleGroupingSelection(for card: Flashcard) {
        if selectedForGrouping.contains(card.id) {
            selectedForGrouping.remove(card.id)
        } else {
            selectedForGrouping.insert(card.id)
        }
    }

    @discardableResult
    private func createGroup() -> UUID? {
        guard selectedForGrouping.count > 1 else {
            return nil
        }

        let newGroupID = UUID()
        let defaultName = makeDefaultFolderName()

        for index in flashcards.indices {
            if selectedForGrouping.contains(flashcards[index].id) {
                flashcards[index].groupID = newGroupID
                flashcards[index].groupName = defaultName
            }
        }

        selectedForGrouping.removeAll()
        isGroupingMode = false
        groupCreatedFeedbackToken += 1
        return newGroupID
    }

    private func cancelGrouping() {
        selectedForGrouping.removeAll()
        isGroupingMode = false
    }

    private func ungroupFolder(_ groupID: UUID) {
        for index in flashcards.indices where flashcards[index].groupID == groupID {
            flashcards[index].groupID = nil
            flashcards[index].groupName = nil
        }
    }

    private func beginFolderNaming(for groupID: UUID, title: String) {
        folderNameTargetID = groupID
        folderNamePromptTitle = title
        folderNameInput = folderName(for: groupID)
        showFolderNamePrompt = true
    }

    private func applyFolderName() {
        guard let groupID = folderNameTargetID else { return }
        setFolderName(folderNameInput, for: groupID)
        folderNameTargetID = nil
    }

    private func folderName(for groupID: UUID) -> String {
        let candidate = flashcards.first { $0.groupID == groupID }?.groupName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let candidate, !candidate.isEmpty {
            return candidate
        }
        return makeDefaultFolderName()
    }

    private func setFolderName(_ rawName: String, for groupID: UUID) {
        let normalized = normalizedFolderName(rawName)
        for index in flashcards.indices where flashcards[index].groupID == groupID {
            flashcards[index].groupName = normalized
        }
    }

    private func normalizedFolderName(_ rawName: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? makeDefaultFolderName() : trimmed
    }

    private func makeDefaultFolderName() -> String {
        "Study Folder"
    }

    private func startQuiz(for period: QuizPeriod) {
        let filtered = filteredFlashcards(for: period)

        guard !filtered.isEmpty else {
            quizAlertMessage = "No \(period.title.lowercased()) flashcards available yet."
            showQuizAlert = true
            return
        }

        activeQuiz = QuizSession(
            period: period,
            cards: randomQuizCards(from: filtered, count: 10)
        )
    }

    private func filteredFlashcards(for period: QuizPeriod) -> [Flashcard] {
        let now = Date()
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -period.dayRange, to: now) else {
            return flashcards
        }

        return flashcards.filter { $0.createdAt >= cutoff }
    }

    private func randomQuizCards(from pool: [Flashcard], count: Int) -> [Flashcard] {
        guard !pool.isEmpty else { return [] }

        if pool.count >= count {
            return Array(pool.shuffled().prefix(count))
        }

        var result = pool.shuffled()
        while result.count < count {
            if let random = pool.randomElement() {
                result.append(random)
            } else {
                break
            }
        }

        return result.shuffled()
    }

    private func palette(for id: UUID, customIndex: Int? = nil) -> CardPalette {
        let palettes: [CardPalette] = [
            CardPalette(background: Color(.systemBlue), accent: Color(.systemBlue), chip: Color(.systemBlue)),
            CardPalette(background: Color(.systemIndigo), accent: Color(.systemIndigo), chip: Color(.systemIndigo)),
            CardPalette(background: Color(.systemTeal), accent: Color(.systemTeal), chip: Color(.systemTeal)),
            CardPalette(background: Color(.systemMint), accent: Color(.systemMint), chip: Color(.systemMint)),
            CardPalette(background: Color(.systemOrange), accent: Color(.systemOrange), chip: Color(.systemOrange)),
            CardPalette(background: Color(.systemPink), accent: Color(.systemPink), chip: Color(.systemPink))
        ]

        let index = customIndex ?? stableColorIndex(for: id, paletteCount: palettes.count)
        return palettes[index % palettes.count]
    }

    private func stableColorIndex(for id: UUID, paletteCount: Int) -> Int {
        let scalarTotal = id.uuidString.unicodeScalars.reduce(into: 0) { total, scalar in
            total += Int(scalar.value)
        }
        return scalarTotal % max(paletteCount, 1)
    }

    private func flashcardTile(
        question: String,
        isSelected: Bool,
        isGroupingMode: Bool,
        palette: CardPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(palette.chip)
                    .frame(width: 9, height: 9)
                Spacer()

                if isGroupingMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? palette.accent : Color(.tertiaryLabel))
                        .font(.body)
                }
            }

            Spacer(minLength: 0)

            Text(question)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(.label))
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(palette.accent.opacity(0.7))
                .frame(height: 3)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: tileHeight)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.background.opacity(0.18), Color(.secondarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    isSelected ? palette.accent : Color(.separator).opacity(0.15),
                    lineWidth: isSelected ? 2 : 0.8
                )
        )
        .shadow(
            color: isSelected ? palette.accent.opacity(0.16) : Color.black.opacity(0.05),
            radius: isSelected ? 12 : 8,
            x: 0,
            y: 4
        )
    }

    private func folderTile(
        folderName: String,
        cardCount: Int,
        preview: String,
        isDisabled: Bool,
        palette: CardPalette
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(palette.chip.opacity(0.25))
                        .frame(width: 30, height: 24)
                    Image(systemName: "folder.fill")
                        .foregroundStyle(palette.accent)
                        .font(.system(size: 14, weight: .semibold))
                }

                Text(folderName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(.label))

                Spacer()

                Text("\(cardCount)")
                    .font(.caption.bold())
                    .foregroundStyle(palette.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(palette.chip.opacity(0.32))
                    .clipShape(Capsule())
            }

            Text(preview)
                .font(.subheadline)
                .foregroundStyle(Color(.secondaryLabel))
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("Open folder")
                    .font(.footnote)
                    .foregroundStyle(Color(.secondaryLabel))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .frame(height: tileHeight)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.background.opacity(0.18), Color(.secondarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.accent.opacity(0.24), lineWidth: 0.9)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
        .opacity(isDisabled ? 0.65 : 1)
    }
}

extension FlashcardsView {
    fileprivate enum QuizPeriod: String, CaseIterable, Identifiable, Codable {
        case weekly
        case monthly
        case yearly

        var id: String { rawValue }

        var title: String {
            switch self {
            case .weekly: return "Weekly"
            case .monthly: return "Monthly"
            case .yearly: return "Yearly"
            }
        }

        var symbol: String {
            switch self {
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar"
            case .yearly: return "calendar.circle"
            }
        }

        var dayRange: Int {
            switch self {
            case .weekly: return 7
            case .monthly: return 30
            case .yearly: return 365
            }
        }
    }

    fileprivate struct QuizSession: Identifiable {
        let id = UUID()
        let period: QuizPeriod
        let cards: [Flashcard]
    }

    private struct CardPalette {
        let background: Color
        let accent: Color
        let chip: Color
    }

    private struct SelectedFolder: Identifiable {
        let id: UUID
    }

    private struct DisplayItem: Identifiable {
        let id: String
        let kind: Kind

        enum Kind {
            case card(cardID: UUID)
            case folder(groupID: UUID, name: String, count: Int, preview: String, colorIndex: Int?)
        }
    }

    private typealias InteractiveCardButtonStyle = PressFeedbackButtonStyle
}

private struct GroupFolderSheet: View {
    let groupID: UUID
    @Binding var flashcards: [Flashcard]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCard: Flashcard?
    @State private var folderNameInput = ""
    @State private var showRenameFolderPrompt = false

    private var groupedIndices: [Int] {
        flashcards.indices.filter { flashcards[$0].groupID == groupID }
    }

    private var folderName: String {
        let candidate = groupedIndices
            .compactMap { flashcards[$0].groupName?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty })

        return candidate ?? "Study Folder"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(groupedIndices, id: \.self) { index in
                        let tone = rowColor(for: flashcards[index].id)

                        Button {
                            selectedCard = flashcards[index]
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "rectangle.stack.fill")
                                    .foregroundStyle(tone)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(flashcards[index].question)
                                        .font(.body)
                                        .foregroundStyle(Color(.label))
                                        .lineLimit(1)

                                    Text(flashcards[index].answer)
                                        .font(.caption)
                                        .foregroundStyle(Color(.secondaryLabel))
                                        .lineLimit(1)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(tone.opacity(0.75))
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(tone.opacity(0.06))
                        .contextMenu {
                            Button {
                                flashcards[index].groupID = nil
                                flashcards[index].groupName = nil
                            } label: {
                                Label("Remove from Folder", systemImage: "folder.badge.minus")
                            }

                            Button(role: .destructive) {
                                flashcards.remove(at: index)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text("\(groupedIndices.count) Cards")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(folderName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if !groupedIndices.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Rename") {
                            folderNameInput = folderName
                            showRenameFolderPrompt = true
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Ungroup All") {
                            ungroupAll()
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedCard) { card in
            if let index = flashcards.firstIndex(where: { $0.id == card.id }) {
                FlashcardDetailSheet(card: $flashcards[index])
            }
        }
        .onChange(of: groupedIndices.count) { _, count in
            if count == 0 {
                dismiss()
            }
        }
        .alert("Rename Folder", isPresented: $showRenameFolderPrompt) {
            TextField("Folder Name", text: $folderNameInput)

            Button("Save") {
                renameFolder()
            }

            Button("Cancel", role: .cancel) { }
        }
    }

    private func ungroupAll() {
        for index in flashcards.indices where flashcards[index].groupID == groupID {
            flashcards[index].groupID = nil
            flashcards[index].groupName = nil
        }
    }

    private func renameFolder() {
        let trimmed = folderNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.isEmpty ? "Study Folder" : trimmed

        for index in flashcards.indices where flashcards[index].groupID == groupID {
            flashcards[index].groupName = normalized
        }
    }

    private func rowColor(for cardID: UUID) -> Color {
        let tones: [Color] = [
            Color(.systemBlue),
            Color(.systemIndigo),
            Color(.systemTeal),
            Color(.systemMint),
            Color(.systemOrange),
            Color(.systemPink)
        ]
        let total = cardID.uuidString.unicodeScalars.reduce(into: 0) { partialResult, scalar in
            partialResult += Int(scalar.value)
        }
        return tones[total % tones.count]
    }
}

private struct QuizStats: Codable {
    var lastScore: Int = 0
    var bestScore: Int = 0
    var attempts: Int = 0
}

private final class QuizProgressStore: ObservableObject {
    @Published private(set) var stats: [String: QuizStats] = [:]

    private let storageKey = "flashforge.quiz.progress.v1"

    init() {
        load()
    }

    func stats(for period: FlashcardsView.QuizPeriod) -> QuizStats {
        stats[period.rawValue] ?? QuizStats()
    }

    func record(score: Int, total: Int, for period: FlashcardsView.QuizPeriod) {
        var current = stats[period.rawValue] ?? QuizStats()
        let normalized = max(0, min(score, total))
        current.lastScore = normalized
        current.bestScore = max(current.bestScore, normalized)
        current.attempts += 1
        stats[period.rawValue] = current
        save()
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([String: QuizStats].self, from: data)
        else {
            return
        }
        stats = decoded
    }
}

private struct QuizLauncherSheet: View {
    let flashcards: [Flashcard]
    @ObservedObject var progressStore: QuizProgressStore
    let onStartQuiz: (FlashcardsView.QuizPeriod) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Choose Quiz Type") {
                    ForEach(FlashcardsView.QuizPeriod.allCases) { period in
                        Button {
                            onStartQuiz(period)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(period.title, systemImage: period.symbol)
                                        .font(.headline)
                                        .foregroundStyle(Color(.label))

                                    Spacer()

                                    Text("\(availableCount(for: period)) cards")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color(.secondaryLabel))
                                }

                                let stats = progressStore.stats(for: period)
                                if stats.attempts > 0 {
                                    ProgressView(value: Double(stats.lastScore), total: 10)
                                        .tint(.accentColor)

                                    Text("Last: \(stats.lastScore)/10  •  Best: \(stats.bestScore)/10  •  Attempts: \(stats.attempts)")
                                        .font(.caption)
                                        .foregroundStyle(Color(.secondaryLabel))
                                } else {
                                    Text("No quiz attempts yet")
                                        .font(.caption)
                                        .foregroundStyle(Color(.secondaryLabel))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PressFeedbackButtonStyle())
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Start Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func availableCount(for period: FlashcardsView.QuizPeriod) -> Int {
        let now = Date()
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -period.dayRange, to: now) else {
            return flashcards.count
        }
        return flashcards.filter { $0.createdAt >= cutoff }.count
    }
}

private struct QuizSessionSheet: View {
    let session: FlashcardsView.QuizSession
    let allFlashcards: [Flashcard]
    let onFinish: (Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var questions: [QuizQuestion] = []
    @State private var currentIndex = 0
    @State private var selectedAnswer: String?
    @State private var score = 0
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if showResult {
                    VStack(spacing: 14) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.accentColor)

                        Text("Quiz Completed")
                            .font(.title2.bold())

                        Text("Your Score: \(score)/\(questions.count)")
                            .font(.headline)
                            .foregroundStyle(Color(.secondaryLabel))

                        ProgressView(value: Double(score), total: Double(max(questions.count, 1)))
                            .tint(.accentColor)

                        Button("Save & Close") {
                            onFinish(score, questions.count)
                            dismiss()
                        }
                        .buttonStyle(PressFeedbackButtonStyle())
                        .padding(.top, 10)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 20)
                } else if !questions.isEmpty {
                    let question = questions[currentIndex]

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(session.period.title) Quiz")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(.secondaryLabel))
                            Spacer()
                            Text("Q\(currentIndex + 1)/\(questions.count)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color(.secondaryLabel))
                        }

                        ProgressView(value: Double(currentIndex), total: Double(max(questions.count, 1)))
                            .tint(.accentColor)

                        Text(question.prompt)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color(.label))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .glassCard(cornerRadius: 20)

                    VStack(spacing: 10) {
                        ForEach(question.options, id: \.self) { option in
                            Button {
                                guard selectedAnswer == nil else { return }
                                selectedAnswer = option
                                if option == question.correctAnswer {
                                    score += 1
                                }
                            } label: {
                                HStack {
                                    Text(option)
                                        .font(.subheadline)
                                        .foregroundStyle(Color(.label))
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    if selectedAnswer == option {
                                        Image(systemName: option == question.correctAnswer ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(option == question.correctAnswer ? Color(.systemGreen) : Color(.systemRed))
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(backgroundForOption(option, question: question))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(borderForOption(option, question: question), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PressFeedbackButtonStyle())
                        }
                    }

                    Button(currentIndex == questions.count - 1 ? "Finish Quiz" : "Next Question") {
                        guard selectedAnswer != nil else { return }

                        if currentIndex == questions.count - 1 {
                            showResult = true
                        } else {
                            currentIndex += 1
                            selectedAnswer = nil
                        }
                    }
                    .buttonStyle(PressFeedbackButtonStyle())
                    .primaryButtonStyle(isDisabled: selectedAnswer == nil)
                    .disabled(selectedAnswer == nil)
                }
            }
            .padding(16)
            .gradientBackground()
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            if questions.isEmpty {
                questions = buildQuestions()
            }
        }
    }

    private func buildQuestions() -> [QuizQuestion] {
        let allAnswers = allFlashcards.map(\.answer)

        return session.cards.map { card in
            let distractors = allAnswers
                .filter { $0 != card.answer }
                .shuffled()
            var options = Array(([card.answer] + distractors).prefix(4))
            options = Array(Set(options))

            if options.isEmpty {
                options = [card.answer]
            } else if !options.contains(card.answer) {
                options.append(card.answer)
            }

            return QuizQuestion(
                prompt: card.question,
                correctAnswer: card.answer,
                options: options.shuffled()
            )
        }
    }

    private func backgroundForOption(_ option: String, question: QuizQuestion) -> Color {
        guard let selectedAnswer else {
            return Color(.secondarySystemBackground)
        }

        if option == question.correctAnswer {
            return Color(.systemGreen).opacity(0.16)
        }
        if option == selectedAnswer {
            return Color(.systemRed).opacity(0.12)
        }
        return Color(.secondarySystemBackground)
    }

    private func borderForOption(_ option: String, question: QuizQuestion) -> Color {
        guard let selectedAnswer else {
            return Color(.separator).opacity(0.2)
        }

        if option == question.correctAnswer {
            return Color(.systemGreen).opacity(0.42)
        }
        if option == selectedAnswer {
            return Color(.systemRed).opacity(0.38)
        }
        return Color(.separator).opacity(0.2)
    }
}

private struct QuizQuestion {
    let prompt: String
    let correctAnswer: String
    let options: [String]
}

#Preview {
    FlashcardsPreviewWrapper()
        .preferredColorScheme(.light)
}

struct FlashcardsPreviewWrapper: View {
    @State var flashcards: [Flashcard] = [
        Flashcard(
            question: "What is SwiftUI?",
            answer: "Declarative UI framework",
            groupID: nil
        ),
        Flashcard(
            question: "Explain OOP principles",
            answer: "Encapsulation, Abstraction, Inheritance, Polymorphism",
            groupID: UUID()
        )
    ]

    var body: some View {
        FlashcardsView(
            flashcards: $flashcards
        )
    }
}
