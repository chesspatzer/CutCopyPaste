import SwiftUI

struct DiffView: View {
    let leftItem: ClipboardItem
    let rightItem: ClipboardItem
    let onDismiss: () -> Void
    @State private var diffResult: DiffResult?
    @State private var diffMode: DiffMode = .sideBySide

    enum DiffMode: String, CaseIterable {
        case sideBySide = "Side by Side"
        case unified = "Unified"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Compare Clips")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Picker("", selection: $diffMode) {
                    ForEach(DiffMode.allCases, id: \.self) { Text($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
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
            .padding(.top, 16)
            .padding(.bottom, 10)

            // Stats bar
            if let diff = diffResult {
                HStack(spacing: 12) {
                    Label("\(diff.addedCount) added", systemImage: "plus.circle")
                        .foregroundStyle(.green)
                    Label("\(diff.removedCount) removed", systemImage: "minus.circle")
                        .foregroundStyle(.red)
                    Label("\(diff.unchangedCount) unchanged", systemImage: "equal.circle")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.06))
                .frame(height: 0.5)

            // Diff content
            if let diff = diffResult {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(diff.lines) { line in
                            diffLineView(line)
                        }
                    }
                    .padding(8)
                }
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .frame(width: 500, height: 380)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
        .onAppear { computeDiff() }
    }

    private func computeDiff() {
        let oldText = leftItem.textContent ?? ""
        let newText = rightItem.textContent ?? ""
        diffResult = DiffEngine.diff(old: oldText, new: newText)
    }

    @ViewBuilder
    private func diffLineView(_ line: DiffLine) -> some View {
        HStack(spacing: 0) {
            Text(line.leftLineNumber.map(String.init) ?? "")
                .frame(width: 35, alignment: .trailing)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)
            Text(line.rightLineNumber.map(String.init) ?? "")
                .frame(width: 35, alignment: .trailing)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.tertiary)

            Text(lineIndicator(line.type))
                .frame(width: 20)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(lineColor(line.type))

            Text(line.content)
                .font(.system(size: 11, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .background(lineBackground(line.type))
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
