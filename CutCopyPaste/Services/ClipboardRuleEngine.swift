import Foundation
import SwiftData
import os

@ModelActor
actor ClipboardRuleEngine {
    private let logger = Logger(subsystem: "com.cutcopypaste.app", category: "RuleEngine")

    // MARK: - CRUD

    func fetchRules() -> [ClipboardRule] {
        let descriptor = FetchDescriptor<ClipboardRule>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func saveRule(_ rule: ClipboardRule) {
        modelContext.insert(rule)
        try? modelContext.save()
    }

    func updateRule(_ ruleID: UUID, name: String, isEnabled: Bool, sourceBundleID: String?,
                    contentTypeFilter: String?, transformType: ClipboardTransformType,
                    regexPattern: String?, regexReplacement: String?) {
        guard let rule = fetchByID(ruleID) else { return }
        rule.name = name
        rule.isEnabled = isEnabled
        rule.sourceBundleID = sourceBundleID
        rule.contentTypeFilter = contentTypeFilter
        rule.transformType = transformType.rawValue
        rule.regexPattern = regexPattern
        rule.regexReplacement = regexReplacement
        try? modelContext.save()
    }

    func deleteRule(_ ruleID: UUID) {
        guard let rule = fetchByID(ruleID) else { return }
        modelContext.delete(rule)
        try? modelContext.save()
    }

    func toggleRule(_ ruleID: UUID) {
        guard let rule = fetchByID(ruleID) else { return }
        rule.isEnabled.toggle()
        try? modelContext.save()
    }

    // MARK: - Rule Application

    func applyRules(to text: String, contentType: ClipboardItemType, sourceBundleID: String?) -> String {
        let rules = fetchRules().filter { $0.isEnabled }
        var result = text

        for rule in rules {
            // Check source app filter
            if let ruleBundleID = rule.sourceBundleID, !ruleBundleID.isEmpty {
                guard sourceBundleID == ruleBundleID else { continue }
            }

            // Check content type filter
            if let typeFilter = rule.contentTypeFilter, !typeFilter.isEmpty {
                guard typeFilter == contentType.rawValue else { continue }
            }

            // Apply transform
            guard let transformType = rule.transformTypeEnum else { continue }
            result = applyTransform(transformType, to: result, rule: rule)
        }

        return result
    }

    private func applyTransform(_ type: ClipboardTransformType, to text: String, rule: ClipboardRule) -> String {
        switch type {
        case .stripAnsi:
            return text.replacingOccurrences(
                of: "\\x1b\\[[0-9;]*[A-Za-z]|\\x1b\\]\\d*;[^\\x07]*\\x07",
                with: "",
                options: .regularExpression
            )

        case .prettifyJson:
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data),
                  let pretty = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                  let result = String(data: pretty, encoding: .utf8) else {
                return text
            }
            return result

        case .stripTrackingParams:
            guard var components = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return text
            }
            let trackingPrefixes = ["utm_", "fbclid", "gclid", "mc_"]
            components.queryItems = components.queryItems?.filter { item in
                !trackingPrefixes.contains(where: { item.name.hasPrefix($0) || item.name == $0 })
            }
            if components.queryItems?.isEmpty == true { components.queryItems = nil }
            return components.url?.absoluteString ?? text

        case .regexReplace:
            guard let pattern = rule.regexPattern,
                  let replacement = rule.regexReplacement,
                  let regex = try? NSRegularExpression(pattern: pattern) else {
                return text
            }
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)

        case .trimWhitespace:
            return text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

        case .lowercaseAll:
            return text.lowercased()

        case .uppercaseAll:
            return text.uppercased()
        }
    }

    // MARK: - Seeding

    func seedDefaultRules() {
        let existing = fetchRules()
        guard existing.isEmpty else { return }

        let defaults: [(String, String?, ClipboardTransformType, Bool)] = [
            ("Strip Terminal Colors", "com.apple.Terminal", .stripAnsi, true),
            ("Strip iTerm Colors", "com.googlecode.iterm2", .stripAnsi, true),
            ("Clean URL Tracking", nil, .stripTrackingParams, false),
        ]

        for (index, (name, bundleID, type, enabled)) in defaults.enumerated() {
            let rule = ClipboardRule(
                name: name,
                isEnabled: enabled,
                sourceBundleID: bundleID,
                transformType: type,
                sortOrder: index
            )
            modelContext.insert(rule)
        }
        try? modelContext.save()
        logger.info("Seeded \(defaults.count) default rules")
    }

    // MARK: - Helpers

    private func fetchByID(_ id: UUID) -> ClipboardRule? {
        let descriptor = FetchDescriptor<ClipboardRule>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? modelContext.fetch(descriptor))?.first
    }
}
