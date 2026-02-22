import SwiftUI

struct DiffView: View {
    let leftItem: ClipboardItem
    let rightItem: ClipboardItem
    let onDismiss: () -> Void
    @State private var diffResult: DiffResult?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Compare Clips")
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
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Stats bar
            if let diff = diffResult {
                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(diff.addedCount)")
                            .foregroundStyle(.green)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(.red)
                        Text("\(diff.removedCount)")
                            .foregroundStyle(.red)
                    }
                    HStack(spacing: 3) {
                        Image(systemName: "equal.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("\(diff.unchangedCount)")
                            .foregroundStyle(.secondary)
                    }
                }
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            // Diff content
            if let diff = diffResult {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(diff.lines) { line in
                            diffLineView(line)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                }
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

    private func computeDiff() {
        let oldText = leftItem.textContent ?? ""
        let newText = rightItem.textContent ?? ""
        diffResult = DiffEngine.diff(old: oldText, new: newText)
    }

    @ViewBuilder
    private func diffLineView(_ line: DiffLine) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Single compact line number
            Text(lineNumber(line))
                .frame(width: 28, alignment: .trailing)
                .font(.system(size: 9, design: .monospaced))
                .foregroundStyle(.quaternary)

            // +/- indicator
            Text(lineIndicator(line.type))
                .frame(width: 16)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(lineColor(line.type))

            // Content — wraps instead of overflowing
            Text(line.content)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(line.type == .unchanged ? .secondary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 1.5)
        .background(lineBackground(line.type))
    }

    private func lineNumber(_ line: DiffLine) -> String {
        if let n = line.leftLineNumber { return "\(n)" }
        if let n = line.rightLineNumber { return "\(n)" }
        return ""
    }

    private func lineIndicator(_ type: DiffLineType) -> String {
        switch type {
        case .unchanged: return " "
        case .added: return "+"
        case .removed: return "-"
        }
    }

    private func lineColor(_ type: DiffLineType) -> Color {
        switch type {
        case .unchanged: return .secondary
        case .added: return .green
        case .removed: return .red
        }
    }

    private func lineBackground(_ type: DiffLineType) -> Color {
        switch type {
        case .unchanged: return .clear
        case .added: return .green.opacity(0.08)
        case .removed: return .red.opacity(0.08)
        }
    }
}
