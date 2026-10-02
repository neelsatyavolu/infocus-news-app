import SwiftUI

@main
struct InFocusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let model = AppModel.shared

    init() {
        SystemAppearance.apply()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model.preferences)
                .environment(model.shows)
                .environment(model.live)
                .environment(model.saved)
                .environment(model.router)
                .environment(model.push)
                .preferredColorScheme(model.preferences.appearance.colorScheme)
                .tint(Brand.green)
                .toggleStyle(SwitchToggleStyle(tint: Brand.fill))
                .task { await model.push.start() }
        }
    }
}
