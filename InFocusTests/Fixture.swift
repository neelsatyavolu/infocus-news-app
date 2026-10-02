import Foundation

/// Loads a JSON fixture bundled with the tests.
enum Fixture {
    static func data(_ name: String) throws -> Data {
        let bundle = Bundle(for: Marker.self)
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
        }
        return try Data(contentsOf: url)
    }

    private final class Marker {}
}

/// The Portal's `{ data }` envelope, for decoding fixtures the way the app does.
struct Envelope<T: Decodable>: Decodable { let data: T }
