import UIKit
import UserNotifications
import Observation

/// New show / new story / going live alerts. Registers with APNs every launch
/// and tells the Portal which alerts this device wants
/// (`POST`/`DELETE /api/public/news-devices`). No account: the token is the device.
@MainActor @Observable
final class PushManager {
    enum Permission: Equatable { case notDetermined, denied, allowed }

    private(set) var permission: Permission = .notDetermined
    /// Lowercase hex APNs token, once iOS hands it over.
    private(set) var deviceToken: String?
    private(set) var lastError: String?

    private let preferences: Preferences
    private let client: PortalClient
    private let defaults: UserDefaults
    private var syncTask: Task<Void, Never>?
    private static let registeredKey = "push.registered"

    init(preferences: Preferences, client: PortalClient = .shared, defaults: UserDefaults = .standard) {
        self.preferences = preferences
        self.client = client
        self.defaults = defaults
    }

    private var center: UNUserNotificationCenter { .current() }

    /// At launch: Apple wants registration every launch. Getting a token
    /// doesn't need alert permission (that only decides what is shown).
    func start() async {
        await refreshPermission()
        UIApplication.shared.registerForRemoteNotifications()
    }

    func refreshPermission() async {
        permission = Self.permission(await center.notificationSettings().authorizationStatus)
    }

    /// Onboarding and Settings: the iOS prompt (shown once by iOS).
    @discardableResult
    func requestPermission() async -> Bool {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("InFocus: notification permission request failed: \(error.localizedDescription)")
        }
        await refreshPermission()
        UIApplication.shared.registerForRemoteNotifications()
        scheduleSync()
        return permission == .allowed
    }

    func didRegister(_ token: Data) {
        deviceToken = Self.hex(token)
        scheduleSync()
    }

    func didFail(_ error: Error) {
        print("InFocus: push unavailable in this build: \(error.localizedDescription)")
    }

    /// After a toggle changes: wait a beat so quick flips send one request.
    func scheduleSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            await self?.sync()
        }
    }

    func sync() async {
        guard let token = deviceToken else { return }
        await refreshPermission()
        let wanted = permission == .allowed && preferences.wantsAnyAlerts
        do {
            if wanted {
                try await client.registerDevice(.init(
                    token: token, environment: AppConfig.pushEnvironment, appVersion: AppConfig.version,
                    shows: preferences.notifyShows, stories: preferences.notifyStories, live: preferences.notifyLive))
                defaults.set(true, forKey: Self.registeredKey)
            } else if defaults.bool(forKey: Self.registeredKey) {
                try await client.unregisterDevice(token: token)
                defaults.set(false, forKey: Self.registeredKey)
            }
            lastError = nil
        } catch is CancellationError {
            return
        } catch {
            lastError = Loadable<Void>.message(for: error)
            print("InFocus: push registration failed: \(lastError ?? "")")
        }
    }

    func openSystemSettings() {
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    nonisolated static func hex(_ token: Data) -> String {
        token.map { String(format: "%02x", $0) }.joined()
    }

    nonisolated static func permission(_ status: UNAuthorizationStatus) -> Permission {
        switch status {
        case .authorized, .provisional, .ephemeral: .allowed
        case .denied: .denied
        default: .notDetermined
        }
    }
}
