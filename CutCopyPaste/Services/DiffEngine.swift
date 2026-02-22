import Foundation

enum DiffLineType {
    case unchanged
    case added
    case removed
}

struct DiffLine: Identifiable {
    let id = UUID()
    let type: DiffLineType
    let leftLineNumber: Int?
    let rightLineNumber: Int?
    let content: String
}

struct DiffResult {
    let lines: [DiffLine]
    let addedCount: Int
    let removedCount: Int
    let unchangedCount: Int
}

final class DiffEngine {
    static func diff(old: String, new: String) -> DiffResult {
        let oldLines = old.components(separatedBy: .newlines)
        let newLines = new.components(separatedBy: .newlines)

        let lcs = computeLCS(oldLines, newLines)
        let diffLines = buildDiffLines(oldLines: oldLines, newLines: newLines, lcs: lcs)

        let added = diffLines.filter { $0.type == .added }.count
        let removed = diffLines.filter { $0.type == .removed }.count
        let unchanged = diffLines.filter { $0.type == .unchanged }.count

        return DiffResult(
            lines: diffLines,
            addedCount: added,
            removedCount: removed,
            unchangedCount: unchanged
        )
    }

    // MARK: - LCS (Longest Common Subsequence)

    private static func computeLCS(_ a: [String], _ b: [String]) -> [[Int]] {
        let m = a.count
        let n = b.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1...m {
            for j in 1...n {
                if a[i - 1] == b[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        return dp
    }

    private static func buildDiffLines(oldLines: [String], newLines: [String], lcs: [[Int]]) -> [DiffLine] {
        var result: [DiffLine] = []
        var i = oldLines.count
        var j = newLines.count
        var tempResult: [DiffLine] = []

        while i > 0 || j > 0 {
            if i > 0 && j > 0 && oldLines[i - 1] == newLines[j - 1] {
                tempResult.append(DiffLine(
                    type: .unchanged,
                    leftLineNumber: i,
                    rightLineNumber: j,
                    content: oldLines[i - 1]
                ))
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || lcs[i][j - 1] >= lcs[i - 1][j]) {
                tempResult.append(DiffLine(
                    type: .added,
                    leftLineNumber: nil,
                    rightLineNumber: j,
                    content: newLines[j - 1]
                ))
                j -= 1
            } else if i > 0 {
                tempResult.append(DiffLine(
                    type: .removed,
                    leftLineNumber: i,
                    rightLineNumber: nil,
                    content: oldLines[i - 1]
                ))
                i -= 1
            }
        }

        result = tempResult.reversed()
        return result
    }

    // MARK: - Character-level diff for inline highlighting

    static func inlineDiff(oldLine: String, newLine: String) -> (old: [(String, Bool)], new: [(String, Bool)]) {
        let oldChars = Array(oldLine)
        let newChars = Array(newLine)

        let m = oldChars.count
        let n = newChars.count
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)

        for i in 1...max(1, m) {
            for j in 1...max(1, n) {
                guard i <= m && j <= n else { continue }
                if oldChars[i - 1] == newChars[j - 1] {
                    dp[i][j] = dp[i - 1][j - 1] + 1
                } else {
                    dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])
                }
            }
        }

        // Backtrack to find common characters
        var commonOld = Set<Int>()
        var commonNew = Set<Int>()
        var ci = m, cj = n
        while ci > 0 && cj > 0 {
            if oldChars[ci - 1] == newChars[cj - 1] {
                commonOld.insert(ci - 1)
                commonNew.insert(cj - 1)
                ci -= 1
                cj -= 1
            } else if dp[ci][cj - 1] >= dp[ci - 1][cj] {
                cj -= 1
            } else {
                ci -= 1
            }
        }

        // Build segments: (text, isChanged)
        var oldSegments: [(String, Bool)] = []
        var newSegments: [(String, Bool)] = []

        var currentOld = ""
        var currentOldChanged = false
        for (idx, ch) in oldChars.enumerated() {
            let changed = !commonOld.contains(idx)
            if changed != currentOldChanged && !currentOld.isEmpty {
                oldSegments.append((currentOld, currentOldChanged))
                currentOld = ""
            }
            currentOldChanged = changed
            currentOld.append(ch)
        }
        if !currentOld.isEmpty { oldSegments.append((currentOld, currentOldChanged)) }

        var currentNew = ""
        var currentNewChanged = false
        for (idx, ch) in newChars.enumerated() {
            let changed = !commonNew.contains(idx)
            if changed != currentNewChanged && !currentNew.isEmpty {
                newSegments.append((currentNew, currentNewChanged))
                currentNew = ""
            }
            currentNewChanged = changed
            currentNew.append(ch)
        }
        if !currentNew.isEmpty { newSegments.append((currentNew, currentNewChanged)) }

        return (oldSegments, newSegments)
    }
}
