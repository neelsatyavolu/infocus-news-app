import Foundation

/// Show dates are Pacific calendar days (`YYYY-MM-DD`); shows air at 8:30 AM.
enum ShowDate {
    static let timeZone = TimeZone(identifier: "America/Los_Angeles")!

    private static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    /// Noon Pacific on that day (safe from DST edges), or nil if malformed.
    static func parse(_ key: String) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, key.count == 10 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    static func key(_ date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// "Friday, September 25"
    static func long(_ date: Date) -> String { format(date, "EEEE, MMMM d") }
    /// "Fri, Sep 25"
    static func short(_ date: Date) -> String { format(date, "EEE, MMM d") }
    /// "Fri, Sep 25 · 7:00 PM" in Pacific time.
    static func dayAndTime(_ date: Date) -> String { format(date, "EEE, MMM d · h:mm a") }

    /// Formats in Pacific time with a fixed `dateFormat` pattern.
    static func format(_ date: Date, _ template: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = template
        return formatter.string(from: date)
    }

    /// Consecutive show dates from `start` (inclusive), at most `limit`.
    static func window(from start: String, in dates: [String], limit: Int) -> [String] {
        guard let index = dates.firstIndex(of: start) else { return [] }
        return Array(dates[index...].prefix(limit))
    }
}

/// ISO-8601 with or without fractional seconds (Portal and YouTube both).
enum ISODate {
    static func parse(_ value: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            guard let date = parse(raw) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date \(raw)")
            }
            return date
        }
        return decoder
    }()
}
