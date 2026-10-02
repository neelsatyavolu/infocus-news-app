import Foundation

/// The InFocus Portal's public API (shows, live, announcements, push).
/// Every response is `{ data }` or `{ error: { message } }`.
struct PortalClient: Sendable {
    let base: URL

    static let shared = PortalClient(base: AppConfig.portalURL)

    // MARK: Reads

    func shows() async throws -> ShowsFeed {
        try await get("api/public/shows")
    }

    func announcements(for showDate: String) async throws -> ShowAnnouncements {
        try await get("api/public/shows/\(showDate)/announcements")
    }

    func live() async throws -> LiveFeed {
        try await get("api/public/live")
    }

    // MARK: Writes

    struct DeviceRegistration: Encodable, Sendable {
        let token: String
        let environment: String
        let appVersion: String
        let shows: Bool
        let stories: Bool
        let live: Bool
    }

    func registerDevice(_ registration: DeviceRegistration) async throws {
        try await send("POST", "api/public/news-devices", body: registration)
    }

    func unregisterDevice(token: String) async throws {
        try await send("DELETE", "api/public/news-devices", body: ["token": token])
    }

    func submit(_ announcement: AnnouncementSubmission) async throws {
        try await send("POST", "api/announcements/submit", body: announcement.payload)
    }

    // MARK: Plumbing

    private struct Envelope<T: Decodable>: Decodable { let data: T }
    private struct ErrorEnvelope: Decodable {
        struct Body: Decodable { let message: String }
        let error: Body
    }

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var request = URLRequest(url: base.appending(path: path))
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await HTTP.data(for: request)
        try Self.check(data, response)
        do {
            return try ISODate.decoder.decode(Envelope<T>.self, from: data).data
        } catch {
            throw APIError.badResponse
        }
    }

    private func send(_ method: String, _ path: String, body: some Encodable) async throws {
        var request = URLRequest(url: base.appending(path: path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await HTTP.data(for: request)
        try Self.check(data, response)
    }

    static func check(_ data: Data, _ response: HTTPURLResponse) throws {
        guard !(200..<300).contains(response.statusCode) else { return }
        let message = (try? JSONDecoder().decode(ErrorEnvelope.self, from: data))?.error.message
        throw APIError.server(status: response.statusCode, message: message)
    }
}
