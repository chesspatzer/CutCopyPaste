import Foundation
import AppKit

protocol QuickAction: Identifiable {
    var id: String { get }
    var name: String { get }
    var iconSystemName: String { get }

    func canApply(to item: ClipboardItem) -> Bool
    func execute(item: ClipboardItem) -> String?
}

final class QuickActionService {
    static let shared = QuickActionService()

    private let actions: [any QuickAction] = [
        OpenInBrowserAction(),
        StripTrackingParamsAction(),
        ExtractDomainAction(),
        JSONValidateAction(),
        JSONExtractKeysAction(),
        RegenerateUUIDAction(),
        EpochToHumanAction(),
        ISOToHumanAction(),
        ExtractEmailsAction(),
        FormatPhoneAction(),
    ]

    func applicableActions(for item: ClipboardItem) -> [any QuickAction] {
        actions.filter { $0.canApply(to: item) }
    }
}

// MARK: - URL Actions

struct OpenInBrowserAction: QuickAction {
    let id = "open_in_browser"
    let name = "Open in Browser"
    let iconSystemName = "safari"

    func canApply(to item: ClipboardItem) -> Bool {
        item.contentType == .link
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent,
              let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        NSWorkspace.shared.open(url)
        return nil
    }
}

struct StripTrackingParamsAction: QuickAction {
    let id = "strip_tracking"
    let name = "Strip Tracking Params"
    let iconSystemName = "eye.slash"

    func canApply(to item: ClipboardItem) -> Bool {
        guard item.contentType == .link, let text = item.textContent else { return false }
        return text.contains("utm_") || text.contains("fbclid") || text.contains("gclid")
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent,
              var components = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        let trackingPrefixes = ["utm_", "fbclid", "gclid", "mc_", "ref", "source", "medium", "campaign"]
        components.queryItems = components.queryItems?.filter { qItem in
            !trackingPrefixes.contains(where: { qItem.name.hasPrefix($0) || qItem.name == $0 })
        }
        if components.queryItems?.isEmpty == true { components.queryItems = nil }
        return components.url?.absoluteString
    }
}

struct ExtractDomainAction: QuickAction {
    let id = "extract_domain"
    let name = "Extract Domain"
    let iconSystemName = "globe"

    func canApply(to item: ClipboardItem) -> Bool {
        item.contentType == .link
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent,
              let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        return url.host
    }
}

// MARK: - JSON Actions

struct JSONValidateAction: QuickAction {
    let id = "json_validate"
    let name = "Validate JSON"
    let iconSystemName = "checkmark.circle"

    func canApply(to item: ClipboardItem) -> Bool {
        guard let text = item.textContent else { return false }
        let signatures = ContentAnalyzer.analyze(text)
        return signatures.contains(.json)
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent,
              let data = text.data(using: .utf8) else { return "Invalid: not UTF-8" }
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return "Valid JSON"
        } catch {
            return "Invalid: \(error.localizedDescription)"
        }
    }
}

struct JSONExtractKeysAction: QuickAction {
    let id = "json_extract_keys"
    let name = "Extract JSON Keys"
    let iconSystemName = "key"

    func canApply(to item: ClipboardItem) -> Bool {
        guard let text = item.textContent else { return false }
        let signatures = ContentAnalyzer.analyze(text)
        return signatures.contains(.json)
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent,
              let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json.keys.sorted().joined(separator: "\n")
    }
}

// MARK: - UUID Actions

struct RegenerateUUIDAction: QuickAction {
    let id = "regenerate_uuid"
    let name = "Regenerate UUID"
    let iconSystemName = "arrow.triangle.2.circlepath"

    func canApply(to item: ClipboardItem) -> Bool {
        guard let text = item.textContent else { return false }
        return UUID(uuidString: text.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func execute(item: ClipboardItem) -> String? {
        UUID().uuidString
    }
}

// MARK: - Timestamp Actions

struct EpochToHumanAction: QuickAction {
    let id = "epoch_to_human"
    let name = "Epoch → Human Date"
    let iconSystemName = "calendar"

    func canApply(to item: ClipboardItem) -> Bool {
        guard let text = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return text.range(of: "^\\d{10,13}$", options: .regularExpression) != nil
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines),
              let epoch = Double(text) else { return nil }
        let interval = text.count > 10 ? epoch / 1000 : epoch
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .long
        return formatter.string(from: date)
    }
}

struct ISOToHumanAction: QuickAction {
    let id = "iso_to_human"
    let name = "ISO Date → Human"
    let iconSystemName = "calendar"

    func canApply(to item: ClipboardItem) -> Bool {
        guard let text = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        return text.range(of: "\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}", options: .regularExpression) != nil
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent?.trimmingCharacters(in: .whitespacesAndNewlines) else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: text) ?? ISO8601DateFormatter().date(from: text) else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Email/Phone Actions

struct ExtractEmailsAction: QuickAction {
    let id = "extract_emails"
    let name = "Extract Emails"
    let iconSystemName = "envelope"

    func canApply(to item: ClipboardItem) -> Bool {
        guard let text = item.textContent else { return false }
        return ContentAnalyzer.analyze(text).contains(.email)
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent else { return nil }
        let pattern = "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let emails = matches.compactMap { match -> String? in
            guard let range = Range(match.range, in: text) else { return nil }
            return String(text[range])
        }
        return emails.joined(separator: "\n")
    }
}

struct FormatPhoneAction: QuickAction {
    let id = "format_phone"
    let name = "Format Phone Number"
    let iconSystemName = "phone"

    func canApply(to item: ClipboardItem) -> Bool {
        guard let text = item.textContent else { return false }
        return ContentAnalyzer.analyze(text).contains(.phoneNumber)
    }

    func execute(item: ClipboardItem) -> String? {
        guard let text = item.textContent else { return nil }
        let digits = text.filter(\.isNumber)
        guard digits.count >= 10 else { return nil }
        if digits.count == 10 {
            let area = digits.prefix(3)
            let mid = digits.dropFirst(3).prefix(3)
            let last = digits.suffix(4)
            return "(\(area)) \(mid)-\(last)"
        } else if digits.count == 11 && digits.first == "1" {
            let rest = digits.dropFirst()
            let area = rest.prefix(3)
            let mid = rest.dropFirst(3).prefix(3)
            let last = rest.suffix(4)
            return "+1 (\(area)) \(mid)-\(last)"
        }
        return "+\(digits)"
    }
}
