import Foundation

/// OB（狙撃地点）の 1 つ分を表す値オブジェクト。
struct OBEntry: Equatable {
    /// ラベル（例: "HIGH", "MID", "LOW", "MAIN" など）
    let label: String
    /// 価格水準
    let price: Double
}

/// weekly_attack_report.md から抽出される事前戦略情報。
struct WeeklyAttackReport {
    /// 日米金利差・実需・IMMポジション偏りから算出された合成スコア。
    let totalDistortionScore: Double
    /// OB（狙撃地点）の一覧。例: [("HIGH", 150.200), ("MID", 149.850), ("LOW", 149.500)]
    let obEntries: [OBEntry]
}

/// weekly_attack_report.md のパース時に発生しうるエラー。
enum WeeklyReportParserError: Error {
    /// ファイルが見つからない、もしくは iCloud コンテナに到達できない場合。
    case fileNotFound(URL)
    /// 期待するキー（total_distortion_score など）が見つからない、またはフォーマット不正な場合。
    case invalidFormat(String)
}

/// `STRATEGY/weekly_attack_report.md` から FACT ベースのスコアと OB を抽出するパーサ。
struct WeeklyReportParser {
    
    /// Markdown テキストから `WeeklyAttackReport` を生成する。
    /// - Parameter markdown: weekly_attack_report.md の内容（UTF-8 文字列）
    /// - Throws: `WeeklyReportParserError.invalidFormat`（total_distortion_score が見つからない等）
    func parse(markdown: String) throws -> WeeklyAttackReport {
        guard let score = parseTotalDistortionScore(from: markdown) else {
            throw WeeklyReportParserError.invalidFormat("total_distortion_score not found in weekly_attack_report.md")
        }
        let obEntries = parseOBEntries(from: markdown)
        return WeeklyAttackReport(totalDistortionScore: score, obEntries: obEntries)
    }
    
    /// 任意の URL から weekly_attack_report.md をロードしてパースする。
    /// - Parameter url: ファイルの URL
    /// - Throws: ファイル I/O エラー、または `WeeklyReportParserError`
    func loadReport(from url: URL) throws -> WeeklyAttackReport {
        let data = try Data(contentsOf: url)
        guard let markdown = String(data: data, encoding: .utf8) else {
            throw WeeklyReportParserError.invalidFormat("weekly_attack_report.md is not valid UTF-8 text")
        }
        return try parse(markdown: markdown)
    }
    
    /// iCloud Drive 上の `STRATEGY/weekly_attack_report.md` を読み込んでパースする。
    ///
    /// - Parameter ubiquityContainerIdentifier:
    ///   iCloud コンテナ ID。デフォルトコンテナを使う場合は `nil`。
    /// - Throws: `WeeklyReportParserError.fileNotFound` または `WeeklyReportParserError.invalidFormat`
    func loadFromICloud(ubiquityContainerIdentifier: String? = nil) throws -> WeeklyAttackReport {
        let fileManager = FileManager.default
        
        guard let containerURL = fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier) else {
            let pseudoURL = URL(fileURLWithPath: "iCloudContainer(\(ubiquityContainerIdentifier ?? "default"))")
            throw WeeklyReportParserError.fileNotFound(pseudoURL)
        }
        
        // iCloud Drive 配下: <container>/Documents/STRATEGY/weekly_attack_report.md を想定
        let strategyURL = containerURL
            .appendingPathComponent("Documents")
            .appendingPathComponent("STRATEGY")
            .appendingPathComponent("weekly_attack_report.md")
        
        guard FileManager.default.fileExists(atPath: strategyURL.path) else {
            throw WeeklyReportParserError.fileNotFound(strategyURL)
        }
        
        return try loadReport(from: strategyURL)
    }
    
    // MARK: - Private helpers
    
    /// Markdown から total_distortion_score を抽出する。
    ///
    /// 以下のようなフォーマットを想定して、ある程度ゆるくパースする:
    /// - `total_distortion_score: 2.3`
    /// - `total_distortion_score = 2.3`
    /// - `TOTAL_DISTORTION_SCORE 2.3`
    private func parseTotalDistortionScore(from markdown: String) -> Double? {
        let lines = markdown.split(whereSeparator: \.isNewline)
        let pattern = #"total_distortion_score[^0-9\-\+]*([\-+]?[0-9]+(?:\.[0-9]+)?)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        
        for line in lines {
            let string = String(line)
            guard let regex = regex else { continue }
            let range = NSRange(location: 0, length: string.utf16.count)
            if let match = regex.firstMatch(in: string, options: [], range: range),
               let valueRange = Range(match.range(at: 1), in: string) {
                let valueString = String(string[valueRange])
                if let value = Double(valueString) {
                    return value
                }
            }
        }
        return nil
    }
    
    /// Markdown から OB 情報を抽出する。
    ///
    /// 例えば以下のような行を想定する:
    /// - `OB HIGH: 150.200`
    /// - `- OB MID : 149.850`
    /// - `* OB_LOW = 149.500`
    ///
    /// ラベル部分は大文字・小文字やアンダースコアを気にせず正規化して保存する。
    private func parseOBEntries(from markdown: String) -> [OBEntry] {
        let lines = markdown.split(whereSeparator: \.isNewline)
        let pattern = #"OB\s+([A-Za-z0-9_]+)\s*[:=]\s*([0-9]+(?:\.[0-9]+)?)"#
        let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        var result: [OBEntry] = []
        
        for line in lines {
            let string = String(line)
            guard let regex = regex else { continue }
            let range = NSRange(location: 0, length: string.utf16.count)
            if let match = regex.firstMatch(in: string, options: [], range: range),
               let labelRange = Range(match.range(at: 1), in: string),
               let priceRange = Range(match.range(at: 2), in: string) {
                let rawLabel = String(string[labelRange])
                let normalizedLabel = rawLabel
                    .replacingOccurrences(of: "_", with: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                
                let priceString = String(string[priceRange])
                if let price = Double(priceString) {
                    result.append(OBEntry(label: normalizedLabel, price: price))
                }
            }
        }
        
        return result
    }
}

