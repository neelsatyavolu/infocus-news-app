import Foundation

/// `POST /api/announcements/submit` (the Portal's public announcement form).
struct AnnouncementSubmission: Encodable, Sendable, Equatable {
    enum SubmitterKind: String, Encodable, CaseIterable, Identifiable, Sendable {
        case palyStudent = "PALY_STUDENT"
        case pausdEmployee = "PAUSD_EMPLOYEE"
        case parentGuardian = "PARENT_GUARDIAN"
        case communityMember = "COMMUNITY_MEMBER"

        var id: String { rawValue }
        var label: String {
            switch self {
            case .palyStudent: "PALY Student"
            case .pausdEmployee: "PAUSD Employee"
            case .parentGuardian: "Parent/Guardian of a PALY Student"
            case .communityMember: "Palo Alto Community member"
            }
        }
    }

    enum RunOn: String, Encodable, CaseIterable, Identifiable, Sendable {
        case infocusOnly = "INFOCUS_ONLY"
        case schoologyOnly = "SCHOOLOGY_ONLY"
        case both = "BOTH"

        var id: String { rawValue }
        var label: String {
            switch self {
            case .infocusOnly: "InFocus only"
            case .schoologyOnly: "Schoology Update only"
            case .both: "Both"
            }
        }
    }

    static let maxShowDays = 4
    static let maxLength = 4000
    static let policyText = "I agree to the InFocus announcement policy. Announcements run for a maximum of four consecutive show days."

    var email: String
    var name: String
    var submitterKind: SubmitterKind
    var runOn: RunOn
    var announcement: String
    var startDate: String
    var endDate: String
    var policyAgreed: Bool
    var mediaLink: String?
    var moreInfo: String?

    /// The first problem to fix, worded for the form; nil when it can be sent.
    /// The Portal validates again and its message wins if it disagrees.
    var problem: String? {
        if name.trimmed.isEmpty { return "Enter your name." }
        if !Self.isEmail(email.trimmed) { return "Enter a valid email." }
        if announcement.trimmed.isEmpty { return "Write the announcement." }
        if announcement.trimmed.count > Self.maxLength { return "Keep the announcement under \(Self.maxLength) characters." }
        if startDate.isEmpty || endDate.isEmpty { return "Pick the show dates." }
        if endDate < startDate { return "The last show can't be before the first." }
        if let link = mediaLink?.trimmed, !link.isEmpty,
           !(link.lowercased().hasPrefix("http://") || link.lowercased().hasPrefix("https://")) {
            return "Media link must be a full URL (https://…)."
        }
        if !policyAgreed { return "Agree to the announcement policy to send it." }
        return nil
    }

    /// What goes over the wire: trimmed, optional fields left out when blank.
    var payload: AnnouncementSubmission {
        var copy = self
        copy.email = email.trimmed
        copy.name = name.trimmed
        copy.announcement = announcement.trimmed
        copy.mediaLink = mediaLink?.trimmed.nilIfEmpty
        copy.moreInfo = moreInfo?.trimmed.nilIfEmpty
        return copy
    }

    static func isEmail(_ value: String) -> Bool {
        value.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
