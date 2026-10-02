import Foundation

/// A failed request, worded for people.
enum APIError: LocalizedError, Equatable {
    case offline
    case server(status: Int, message: String?)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .offline:
            "You're offline. Check your connection and try again."
        case .server(_, let message?):
            message
        case .server(let status, nil):
            status >= 500 ? "InFocus is having trouble right now. Try again in a minute." : "Something went wrong (\(status))."
        case .badResponse:
            "InFocus sent something unexpected. Try again later."
        }
    }

    var status: Int? {
        if case .server(let status, _) = self { return status }
        return nil
    }
}

/// Shared networking: one session with a roomy cache for images and pages.
enum HTTP {
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 256 << 20)
        config.requestCachePolicy = .useProtocolCachePolicy
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    static func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError
                    where [.notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
                           .cannotConnectToHost, .dataNotAllowed].contains(error.code) {
            throw APIError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        return (data, http)
    }
}

/// Install the shared cache for AsyncImage too (it uses URLSession.shared).
extension URLCache {
    static func configureShared() {
        URLCache.shared = URLCache(memoryCapacity: 48 << 20, diskCapacity: 300 << 20)
    }
}
