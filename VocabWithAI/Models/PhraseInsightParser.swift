//
//  PhraseInsightParser.swift
//  VocabWithAI
//
//  AI INSIGHT 텍스트를 구조화된 데이터로 파싱.
//

import Foundation

// MARK: - 파싱 결과 모델

struct ParsedInsight {
    let title: String
    let meaning: String
    let analogy: String
    let nuance: String
    let warning: String?
    let connections: [GrammarConnection]
    let practiceSentences: [PracticeSentence]
}

struct GrammarConnection: Identifiable {
    let id = UUID()
    let partOfSpeech: String
    let formula: String
    let examples: [GrammarExample]
}

struct GrammarExample: Identifiable {
    let id = UUID()
    let from: String
    let to: String
}

struct PracticeSentence: Identifiable {
    let id = UUID()
    let title: String
    let category: String
    let japanese: String
    let furigana: String
    let korean: String
    let highlightWord: String
}

// MARK: - 파서

enum PhraseInsightParser {

    static func parse(_ text: String, mainGrammar: String) -> ParsedInsight {
        let lines = text.components(separatedBy: .newlines)

        var title = mainGrammar
        var meaning = ""
        var analogy = ""
        var nuance = ""
        var warning: String?
        var connections: [GrammarConnection] = []
        var practiceSentences: [PracticeSentence] = []

        var section = 0
        var pTitle = "", pCategory = "", pJapanese = "", pFurigana = "", pKorean = ""

        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.isEmpty { continue }

            if t.hasPrefix("# 1.") {
                section = 1
                if let l = t.range(of: "「"), let r = t.range(of: "」") {
                    title = String(t[l.upperBound..<r.lowerBound])
                }
                continue
            }
            if t.hasPrefix("# 2.") { section = 2; continue }
            if t.hasPrefix("# 3.") {
                section = 3
                pTitle = ""; pCategory = ""; pJapanese = ""; pFurigana = ""; pKorean = ""
                continue
            }

            switch section {
            case 1:
                if t.hasPrefix("## 의미:") {
                    meaning = afterColon(t)
                } else if t.hasPrefix("## 비유:") {
                    analogy = afterColon(t)
                } else if t.hasPrefix("## 뉘앙스와 주의점:") {
                    nuance = afterColon(t)
                } else if t.hasPrefix("*") {
                    warning = String(t.dropFirst()).trimmingCharacters(in: .whitespaces)
                }

            case 2:
                if t.hasPrefix("## ") {
                    let header = String(t.dropFirst(3))
                    // 첫 콜론으로 분리 (품사:공식)
                    guard let colonIdx = header.firstIndex(of: ":") else { continue }
                    let pos = String(header[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                    let rest = String(header[header.index(after: colonIdx)...])
                                .trimmingCharacters(in: .whitespaces)

                    var formula = rest
                    var examples: [GrammarExample] = []

                    let markers = ["(예:", "(예：", "(예:", "(예："]
                    var exStart: String.Index?
                    for m in markers {
                        if let r = rest.range(of: m) { exStart = r.lowerBound; break }
                    }

                    if let start = exStart {
                        formula = String(rest[..<start]).trimmingCharacters(in: .whitespaces)
                        var exContent = String(rest[start...])
                        for m in markers { exContent = exContent.replacingOccurrences(of: m, with: "") }
                        exContent = exContent
                            .replacingOccurrences(of: ")", with: "")
                            .replacingOccurrences(of: ")", with: "")
                            .trimmingCharacters(in: .whitespaces)

                        let pairs = exContent.components(separatedBy: ",")
                        for pair in pairs {
                            let p = pair.trimmingCharacters(in: .whitespaces)
                            let arrow = p.contains("➔") ? "➔" : "→"
                            let sides = p.components(separatedBy: arrow)
                            if sides.count == 2 {
                                examples.append(GrammarExample(
                                    from: sides[0].trimmingCharacters(in: .whitespaces),
                                    to: sides[1].trimmingCharacters(in: .whitespaces)
                                ))
                            }
                        }
                    }

                    connections.append(GrammarConnection(
                        partOfSpeech: pos,
                        formula: formula,
                        examples: examples
                    ))
                }

            case 3:
                if t.hasPrefix("### 한자:") {
                    pJapanese = afterColon(t)
                } else if t.hasPrefix("### 히라가나:") {
                    pFurigana = afterColon(t)
                } else if t.hasPrefix("### 한글:") {
                    pKorean = afterColon(t)
                    if !pTitle.isEmpty && !pJapanese.isEmpty {
                        practiceSentences.append(PracticeSentence(
                            title: pTitle, category: pCategory,
                            japanese: pJapanese, furigana: pFurigana, korean: pKorean,
                            highlightWord: title
                        ))
                        pTitle = ""
                    }
                } else if t.hasPrefix("## ") {
                    let header = String(t.dropFirst(3))
                    if let p = header.range(of: "(") {
                        pTitle = String(header[..<p.lowerBound])
                                .trimmingCharacters(in: .whitespaces)
                        pCategory = String(header[p.upperBound...])
                            .replacingOccurrences(of: ")", with: "")
                            .replacingOccurrences(of: ")", with: "")
                            .trimmingCharacters(in: .whitespaces)
                    } else {
                        pTitle = header
                        pCategory = ""
                    }
                    pJapanese = ""; pFurigana = ""; pKorean = ""
                }

            default: break
            }
        }

        return ParsedInsight(
            title: title,
            meaning: meaning,
            analogy: analogy,
            nuance: nuance,
            warning: warning,
            connections: connections,
            practiceSentences: practiceSentences
        )
    }

    private static func afterColon(_ s: String) -> String {
        let parts = s.components(separatedBy: ":")
        return parts.dropFirst().joined(separator: ":")
                    .trimmingCharacters(in: .whitespaces)
    }
}
