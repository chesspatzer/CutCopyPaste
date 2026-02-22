import SwiftUI

struct DiffView: View {
    let leftItem: ClipboardItem
    let rightItem: ClipboardItem
    let onDismiss: () -> Void
    @State private var diffResult: DiffResult?
    @State private var sideBySideRows: [SideBySideRow] = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Compare Clips")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
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
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Stats bar
            if let diff = diffResult {
                HStack(spacing: 12) {
                    statBadge(icon: "plus.circle.fill", count: diff.addedCount, color: .green)
                    statBadge(icon: "minus.circle.fill", count: diff.removedCount, color: .red)
                    statBadge(icon: "equal.circle.fill", count: diff.unchangedCount, color: .secondary)
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            // Column headers
            HStack(spacing: 0) {
                columnHeader(
                    label: leftItem.sourceAppName ?? "Left",
                    time: leftItem.createdAt.relativeFormatted()
                )
                Rectangle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 1)
                columnHeader(
                    label: rightItem.sourceAppName ?? "Right",
                    time: rightItem.createdAt.relativeFormatted()
                )
            }
            .frame(height: 28)
            .background(Color.primary.opacity(0.03))

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            // Side-by-side diff content
            if !sideBySideRows.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(sideBySideRows) { row in
                            sideBySideRowView(row)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else if diffResult != nil {
                Spacer()
                Text("No differences found")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                Spacer()
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { computeDiff() }
    }

    // MARK: - Compute

    private func computeDiff() {
        let oldText = leftItem.textContent ?? ""
        let newText = rightItem.textContent ?? ""
        let result = DiffEngine.diff(old: oldText, new: newText)
        diffResult = result
        sideBySideRows = buildSideBySideRows(from: result.lines)
    }

    // MARK: - Side-by-Side Row Builder

    private func buildSideBySideRows(from lines: [DiffLine]) -> [SideBySideRow] {
        var rows: [SideBySideRow] = []
        var i = 0

        while i < lines.count {
            let line = lines[i]

            switch line.type {
            case .unchanged:
                rows.append(SideBySideRow(
                    left: .init(lineNumber: line.leftLineNumber, content: line.content, type: .unchanged),
                    right: .init(lineNumber: line.rightLineNumber, content: line.content, type: .unchanged)
                ))
                i += 1

            case .removed:
                // Look ahead for a paired addition
                var removedLines: [DiffLine] = [line]
                var j = i + 1
                while j < lines.count && lines[j].type == .removed {
                    removedLines.append(lines[j])
                    j += 1
                }
                var addedLines: [DiffLine] = []
                while j < lines.count && lines[j].type == .added {
                    addedLines.append(lines[j])
                    j += 1
                }

                // Pair them up
                let maxCount = max(removedLines.count, addedLines.count)
                for k in 0..<maxCount {
                    let leftSide: SideBySideLine?
                    let rightSide: SideBySideLine?

                    if k < removedLines.count {
                        leftSide = .init(lineNumber: removedLines[k].leftLineNumber, content: removedLines[k].content, type: .removed)
                    } else {
                        leftSide = nil
                    }

                    if k < addedLines.count {
                        rightSide = .init(lineNumber: addedLines[k].rightLineNumber, content: addedLines[k].content, type: .added)
                    } else {
                        rightSide = nil
                    }

                    rows.append(SideBySideRow(left: leftSide, right: rightSide))
                }
                i = j

            case .added:
                // Standalone addition (no preceding removal)
                rows.append(SideBySideRow(
                    left: nil,
                    right: .init(lineNumber: line.rightLineNumber, content: line.content, type: .added)
                ))
                i += 1
            }
        }

        return rows
    }

    // MARK: - Row View

    private func sideBySideRowView(_ row: SideBySideRow) -> some View {
        HStack(spacing: 0) {
            // Left pane
            sidePane(line: row.left, side: .left, pairedContent: row.right?.content)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Divider
            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(width: 1)

            // Right pane
            sidePane(line: row.right, side: .right, pairedContent: row.left?.content)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func sidePane(line: SideBySideLine?, side: Side, pairedContent: String?) -> some View {
        if let line {
            HStack(alignment: .top, spacing: 0) {
                // Line number
                Text(line.lineNumber.map { "\($0)" } ?? "")
                    .frame(width: 28, alignment: .trailing)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.tertiary)

                // Indicator
                Text(indicator(line.type))
                    .frame(width: 14)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(typeColor(line.type))

                // Content with inline highlights
                if let paired = pairedContent, line.type != .unchanged {
                    inlineHighlightedText(line: line, pairedContent: paired, side: side)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                } else {
                    Text(line.content)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(line.type == .unchanged ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(typeBackground(line.type))
        } else {
            // Empty side (no corresponding line)
            HStack {
                Spacer()
            }
            .padding(.vertical, 2)
            .background(Color.primary.opacity(0.02))
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Inline Character Highlighting

    private func inlineHighlightedText(line: SideBySideLine, pairedContent: String, side: Side) -> some View {
        let segments: [(String, Bool)]
        if side == .left && line.type == .removed {
            segments = DiffEngine.inlineDiff(oldLine: line.content, newLine: pairedContent).old
        } else if side == .right && line.type == .added {
            segments = DiffEngine.inlineDiff(oldLine: pairedContent, newLine: line.content).new
        } else {
            segments = [(line.content, false)]
        }

        return Text(buildAttributedSegments(segments, type: line.type))
            .font(.system(size: 10.5, design: .monospaced))
            .fixedSize(horizontal: false, vertical: true)
    }

    private func buildAttributedSegments(_ segments: [(String, Bool)], type: DiffLineType) -> AttributedString {
        var result = AttributedString()
        let highlightColor: Color = type == .removed ? .red : .green

        for (text, isChanged) in segments {
            var segment = AttributedString(text)
            if isChanged {
                segment.foregroundColor = highlightColor
                segment.backgroundColor = highlightColor.opacity(0.15)
            } else {
                segment.foregroundColor = .primary.opacity(0.85)
            }
            result.append(segment)
        }
        return result
    }

    // MARK: - Helpers

    private func statBadge(icon: String, count: Int, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).foregroundStyle(color)
            Text("\(count)").foregroundStyle(color)
        }
    }

    private func columnHeader(label: String, time: String) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Text(time)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
    }

    private func indicator(_ type: DiffLineType) -> String {
        switch type {
        case .unchanged: return " "
        case .added: return "+"
        case .removed: return "-"
        }
    }

    private func typeColor(_ type: DiffLineType) -> Color {
        switch type {
        case .unchanged: return .secondary
        case .added: return .green
        case .removed: return .red
        }
    }

    private func typeBackground(_ type: DiffLineType) -> Color {
        switch type {
        case .unchanged: return .clear
        case .added: return .green.opacity(0.06)
        case .removed: return .red.opacity(0.06)
        }
    }
}

// MARK: - Models

private enum Side { case left, right }

private struct SideBySideLine {
    let lineNumber: Int?
    let content: String
    let type: DiffLineType
}

private struct SideBySideRow: Identifiable {
    let id = UUID()
    let left: SideBySideLine?
    let right: SideBySideLine?
}
