import UIKit

/// Lexend in the system bars (the bars themselves stay system glass).
@MainActor
enum SystemAppearance {
    static func apply() {
        let text = UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xECEFEA) : UIColor(hex: 0x0F110F) }

        // System (glass) bars; only the type is ours.
        let bar = UINavigationBar.appearance()
        bar.titleTextAttributes = [.font: font("Lexend-SemiBold", 17), .foregroundColor: text]
        bar.largeTitleTextAttributes = [.font: font("Lexend-SemiBold", 32), .foregroundColor: text]

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        for item in [tab.stackedLayoutAppearance, tab.inlineLayoutAppearance, tab.compactInlineLayoutAppearance] {
            item.normal.titleTextAttributes = [.font: font("Lexend-Medium", 10)]
            item.selected.titleTextAttributes = [.font: font("Lexend-Medium", 10)]
        }
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        UISegmentedControl.appearance().setTitleTextAttributes([.font: font("Lexend-Medium", 13)], for: .normal)
    }

    private static func font(_ name: String, _ size: CGFloat) -> UIFont {
        UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
    }
}
