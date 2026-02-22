import SwiftUI

struct ItemDetailView: View {
    let item: ClipboardItem
    let onDismiss: () -> Void

    private var summary: TextSummary? {
        guard let text = item.textContent else { return nil }
        return TextSummarizer.shared.summarize(text)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Item Details")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.primary.opacity(0.06)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            ScrollView {
                VStack(spacing: 16) {
                    if let summary {
                        // Stats grid
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 12) {
                            StatBubble(label: "Characters", value: "\(summary.stats.characterCount)")
                            StatBubble(label: "Words", value: "\(summary.stats.wordCount)")
                            StatBubble(label: "Lines", value: "\(summary.stats.lineCount)")
                            StatBubble(label: "Sentences", value: "\(summary.stats.sentenceCount)")
                            StatBubble(label: "Paragraphs", value: "\(summary.stats.paragraphCount)")
                            StatBubble(label: "Reading", value: summary.stats.estimatedReadingTime)
                        }

                        if !summary.keyPhrases.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Key Phrases")
                                    .font(.subheadline.weight(.semibold))
                                FlowLayout(spacing: 6) {
                                    ForEach(summary.keyPhrases, id: \.self) { phrase in
                                        Text(phrase)
                                            .font(.system(size: 11))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background {
                                                Capsule()
                                                    .fill(Color.accentColor.opacity(0.1))
                                            }
                                    }
                                }
                            }
                        }

                        Rectangle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 0.5)

                        // Summary
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Summary")
                                .font(.subheadline.weight(.semibold))
                            Text(summary.oneLiner)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // OCR text
                    if let ocrText = item.ocrText, !ocrText.isEmpty {
                        Rectangle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 0.5)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Extracted Text (OCR)")
                                .font(.subheadline.weight(.semibold))
                            Text(ocrText)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxHeight: 100)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Sensitive data
                    if let types = item.sensitiveDataTypes, !types.isEmpty {
                        Rectangle()
                            .fill(Color.primary.opacity(0.06))
                            .frame(height: 0.5)
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Sensitive Data Detected", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)
                            ForEach(types, id: \.self) { typeRaw in
                                if let type = SensitiveDataType(rawValue: typeRaw) {
                                    Label(type.displayName, systemImage: type.iconSystemName)
                                        .font(.system(size: 11))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Workspace
                    if let workspace = item.workspaceName {
                        HStack {
                            Image(systemName: "folder")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(workspace)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// MARK: - Helpers

private struct StatBubble: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
