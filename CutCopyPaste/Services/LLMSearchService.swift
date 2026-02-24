import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Generable Output Type (macOS 26+)

#if canImport(FoundationModels)

@available(macOS 26, *)
@Generable
struct LLMSearchIntentOutput {
    @Guide(description: "The core text to search for after extracting filters. Null if the query is purely a filter with no text search.")
    var textQuery: String?

    @Guide(description: "Content type filter: text, richText, image, file, link. Null if not specified.")
    var contentType: String?

    @Guide(description: "Relative date range: today, yesterday, this_week, last_week, last_month, or relative like 3_days_ago, 2_hours_ago, 30_minutes_ago. Null if not specified.")
    var dateRange: String?

    @Guide(description: "Source application name to filter by, e.g. Safari, Xcode, Chrome, Terminal. Null if not specified.")
    var sourceApp: String?
}

#endif

// MARK: - LLM Search Service

@available(macOS 26, *)
final class LLMSearchService: @unchecked Sendable {
    static let shared = LLMSearchService()

    private let systemInstructions = """
        You are a search query parser for a clipboard manager app. \
        Given a user's natural language search query, extract structured search filters.

        The clipboard contains items of types: text, richText, image, file, link.
        Items have: text content, source app name, creation date, content type.

        Extract:
        - textQuery: the core search terms after removing filter phrases. Keep it concise.
        - contentType: only if the user asks for a specific type (images/photos, links/URLs, code/text, files/documents, rich text)
        - dateRange: only if the user specifies a time constraint (today, yesterday, this_week, last_week, last_month, or N_units_ago like 3_days_ago)
        - sourceApp: only if the user explicitly mentions a specific application name (Safari, Chrome, Xcode, Terminal, VSCode, Slack, etc.)

        Important:
        - Only extract sourceApp when the user explicitly says "from [app]" or "in [app]" or names an app as the source.
        - Do not infer sourceApp from the search content itself.
        - If the entire query is a filter with no text to search, set textQuery to null.
        """

    #if canImport(FoundationModels)

    func parseIntent(from query: String) async -> SearchIntent? {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return nil }

        do {
            let session = LanguageModelSession(instructions: systemInstructions)
            let response = try await session.respond(
                to: query,
                generating: LLMSearchIntentOutput.self
            )
            return convertToSearchIntent(response.content)
        } catch {
            return nil
        }
    }

    private func convertToSearchIntent(_ output: LLMSearchIntentOutput) -> SearchIntent {
        var intent = SearchIntent()

        intent.textQuery = output.textQuery

        if let ct = output.contentType?.lowercased() {
            switch ct {
            case "text":     intent.contentTypeFilter = .text
            case "richtext": intent.contentTypeFilter = .richText
            case "image":    intent.contentTypeFilter = .image
            case "file":     intent.contentTypeFilter = .file
            case "link":     intent.contentTypeFilter = .link
            default: break
            }
        }

        if let dateStr = output.dateRange?.lowercased() {
            intent.dateRange = resolveDateRange(dateStr)
        }

        intent.sourceAppFilter = output.sourceApp

        return intent
    }

    private func resolveDateRange(_ description: String) -> (start: Date, end: Date)? {
        let now = Date()
        let calendar = Calendar.current

        switch description {
        case "today":
            return (calendar.startOfDay(for: now), now)
        case "yesterday":
            guard let y = calendar.date(byAdding: .day, value: -1, to: now) else { return nil }
            return (calendar.startOfDay(for: y), calendar.startOfDay(for: now))
        case "this_week", "this week":
            guard let w = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return nil }
            return (w, now)
        case "last_week", "last week":
            guard let w = calendar.date(byAdding: .weekOfYear, value: -1, to: now) else { return nil }
            return (w, now)
        case "last_month", "last month":
            guard let m = calendar.date(byAdding: .month, value: -1, to: now) else { return nil }
            return (m, now)
        default:
            return parseRelativeDate(description)
        }
    }

    private func parseRelativeDate(_ description: String) -> (start: Date, end: Date)? {
        let normalized = description.replacingOccurrences(of: "_", with: " ")
        let parts = normalized.components(separatedBy: " ")
        guard parts.count >= 3,
              let number = Int(parts[0]),
              parts.last == "ago" else { return nil }

        let unit = parts[1]
        let component: Calendar.Component
        if unit.hasPrefix("day") { component = .day }
        else if unit.hasPrefix("hour") { component = .hour }
        else if unit.hasPrefix("min") { component = .minute }
        else { return nil }

        let now = Date()
        guard let past = Calendar.current.date(byAdding: component, value: -number, to: now) else { return nil }
        return (past, now)
    }

    #else

    func parseIntent(from query: String) async -> SearchIntent? {
        return nil
    }

    #endif
}
