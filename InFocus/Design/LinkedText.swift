import Foundation
import SwiftUI

/// Plain text with its links made tappable: web addresses (also bare ones like
/// `bit.ly/paly`), emails and phone numbers, in brand green and underlined.
/// SwiftUI's `Text` opens them through the environment's `openURL`.
enum LinkedText {
    private static let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue
    )

    /// The links found in `text`, in order, with the range of text each covers.
    static func links(in text: String) -> [(range: Range<String.Index>, url: URL)] {
        guard let detector else { return [] }
        let whole = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: whole).compactMap { match in
            guard let range = Range(match.range, in: text), let url = url(for: match) else { return nil }
            return (range, url)
        }
    }

    static func attributed(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        for link in links(in: text) {
            guard let lower = AttributedString.Index(link.range.lowerBound, within: result),
                  let upper = AttributedString.Index(link.range.upperBound, within: result) else { continue }
            result[lower..<upper].link = link.url
            result[lower..<upper].foregroundColor = Brand.green
            result[lower..<upper].underlineStyle = .single
        }
        return result
    }

    /// Only links people expect to open: web pages, email and phone calls.
    private static func url(for match: NSTextCheckingResult) -> URL? {
        if match.resultType == .phoneNumber, let number = match.phoneNumber {
            let digits = number.filter { $0.isNumber || $0 == "+" }
            return digits.count >= 7 ? URL(string: "tel:\(digits)") : nil
        }
        guard let url = match.url, let scheme = url.scheme?.lowercased() else { return nil }
        return ["http", "https", "mailto"].contains(scheme) ? url : nil
    }
}
