
import SwiftUI
import FoundationModels

@Observable
final class AIStudyService {
    var questions: [String] = []
    var isLoading = false
    var errorMessage: String?

    private let session: LanguageModelSession

    private var canUseOnDeviceModel: Bool {
        SystemLanguageModel.default.isAvailable
    }

    init() {
        self.session = LanguageModelSession(model: SystemLanguageModel.default)
    }

    func generateQuestions(from topic: String) async {
        guard topic.count > 2 else {
            questions = []
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if canUseOnDeviceModel {
            let prompt = """
            Topic: \(topic)

            Generate exactly 5 concise study questions directly related to this topic.

            Requirements:
            - 1 sentence each
            - Under 20 words
            - Keep each question specific to the provided topic
            - Include at least 1 average/worst-case time complexity question
            - Include at least 1 space complexity or trade-off question
            - If the topic has subtopics, include at least 1 subtopic-focused question
            - Numbered list only
            - No extra text
            """
 
            do {
                var fullResponse = ""

                for try await chunk in session.streamResponse(to: prompt) {
                    fullResponse += chunk.content
                }

                let parsed = parseQuestions(from: fullResponse)
                if !parsed.isEmpty {
                    questions = Array(parsed.prefix(5))
                    return
                }
            } catch {
            }
        }

        questions = fallbackQuestions(for: topic)
        if questions.isEmpty {
            errorMessage = "Failed to generate questions."
        }
    }

    func generateAnswer(for question: String) async -> String {
        if canUseOnDeviceModel {
            let prompt = """
            This is a Data Structures exam question:

            \(question)

            Provide 4 concise answer points directly related to this question.

            Rules:
            - Exactly 4 bullet points which should include defination , time and space complexity if applicable , one read life example , one disadvantage
            - Bullet points only
            - Each under 22 words
            - Mention relevant data structure
            - Include time complexity if applicable
            - Use declarative answer statements only
            - Do not ask any follow-up questions
            - Do not use question marks
            - No storytelling
            - No extra text
            """

            do {
                var fullResponse = ""

                for try await chunk in session.streamResponse(to: prompt) {
                    fullResponse += chunk.content
                }

                if let normalized = normalizedAnswer(from: fullResponse) {
                    return normalized
                }
            } catch {
            }
        }

        return fallbackAnswer(for: question)
    }

    private func parseQuestions(from response: String) -> [String] {
        response
            .split(whereSeparator: \.isNewline)
            .map { line in
                line.replacingOccurrences(
                    of: #"^\s*([\-•*]|\d+[\.)])\s*"#,
                    with: "",
                    options: .regularExpression
                )
                .trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }

    private func fallbackQuestions(for topic: String) -> [String] {
        let cleanTopic = cleanedTopic(topic)
        let subtopics = extractedSubtopics(from: cleanTopic)

        var generated = [
            "What is \(cleanTopic), and which operations are fundamental to it?",
            "What are the average and worst-case time complexities of \(cleanTopic)?",
            "What space complexity trade-offs should be considered for \(cleanTopic)?",
            "Which implementation choices most affect \(cleanTopic) performance?"
        ]

        if subtopics.count >= 2 {
            generated.append("How do \(subtopics[0]) and \(subtopics[1]) differ in complexity and use cases?")
        } else if let firstSubtopic = subtopics.first {
            generated.append("How does \(firstSubtopic) relate to \(cleanTopic), and when is it preferred?")
        } else {
            generated.append("Which real-world problems are best solved using \(cleanTopic)?")
        }

        generated.append("What are common pitfalls in \(cleanTopic), and how can they be avoided?")

        return deduplicated(generated).prefix(5).map { $0 }
    }

    private func fallbackAnswer(for question: String) -> String {
        let lower = question.lowercased()
        var points: [String] = []

        points.append("Define the core concept directly and keep scope limited.")

        if lower.contains("implementation") || lower.contains("memory") {
            points.append("Describe node/array layout and key fields used internally.")
        } else {
            points.append("List the main operations and expected behavior.")
        }

        if lower.contains("time") || lower.contains("complexity") {
            points.append("State average and worst-case complexity with short justification.")
        } else {
            points.append("Mention operation cost impact for insertion, deletion, and lookup.")
        }

        if lower.contains("compare") {
            points.append("Contrast advantages, trade-offs, and practical selection criteria.")
        } else {
            points.append("Include one realistic use case where this structure is preferred.")
        }

        return points.prefix(4).map { "• \($0)" }.joined(separator: "\n")
    }

    private func normalizedAnswer(from response: String) -> String? {
        let cleanedLines = response
            .split(whereSeparator: \.isNewline)
            .map { line in
                line.replacingOccurrences(
                    of: #"^\s*([\-•*]|\d+[\.)])\s*"#,
                    with: "",
                    options: .regularExpression
                )
                .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { !$0.isEmpty }

        let statementLines = cleanedLines
            .map(normalizeAnswerLine(_:))
            .filter { line in
                !line.isEmpty && !isQuestionLike(line)
            }

        guard statementLines.count >= 3 else { return nil }

        return statementLines
            .prefix(4)
            .map { "• \($0)" }
            .joined(separator: "\n")
    }

    private func normalizeAnswerLine(_ line: String) -> String {
        var value = line
            .replacingOccurrences(of: "?", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if !value.isEmpty,
            !value.hasSuffix("."),
            !value.hasSuffix("!"),
            !value.hasSuffix(":") {
            value.append(".")
        }

        return value
    }

    private func isQuestionLike(_ line: String) -> Bool {
        let lowered = line.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if lowered.contains("?") {
            return true
        }

        let questionPrefixes = [
            "what ", "how ", "why ", "when ", "which ", "who ",
            "where ", "can ", "could ", "should ", "would ",
            "is ", "are ", "do ", "does ", "did "
        ]

        return questionPrefixes.contains { lowered.hasPrefix($0) }
    }

    private func cleanedTopic(_ topic: String) -> String {
        let trimmed = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "this topic" : trimmed
    }

    private func extractedSubtopics(from topic: String) -> [String] {
        let normalized = topic
            .replacingOccurrences(
                of: #"(?i)\s+vs\.?\s+"#,
                with: ",",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?i)\s+and\s+"#,
                with: ",",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: #"(?i)\s+or\s+"#,
                with: ",",
                options: .regularExpression
            )
            .replacingOccurrences(of: "/", with: ",")
            .replacingOccurrences(of: "&", with: ",")
            .replacingOccurrences(of: ";", with: ",")
            .replacingOccurrences(of: ":", with: ",")

        let pieces = normalized
            .split(separator: ",")
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines.union(.punctuationCharacters)
                )
            }
            .filter { !$0.isEmpty }

        guard pieces.count > 1 else { return [] }
        return deduplicated(pieces)
    }

    private func deduplicated(_ values: [String]) -> [String] {
        var seen: Set<String> = []
        return values.filter { value in
            let key = value.lowercased()
            if seen.contains(key) {
                return false
            }
            seen.insert(key)
            return true
        }
    }
}
