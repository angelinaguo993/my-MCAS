import SwiftUI

@main
struct MCASTrackerApp: App {
    @StateObject private var profileStore = UserProfileStore()



    init() {
        FontRegistrar.registerBundledFonts()
        Self.styleNavigationBar()
    }

    private static func styleNavigationBar() {
        let color = UIColor(Theme.textPrimary)

        var large: [NSAttributedString.Key: Any] = [.foregroundColor: color]
        var inline: [NSAttributedString.Key: Any] = [.foregroundColor: color]

        if let font = UIFont(name: AppFont.extraBold, size: 34) {
            large[.font] = font
        } else {
            print("⚠️ Font not found: \(AppFont.extraBold)")
        }
        if let font = UIFont(name: AppFont.bold, size: 17) {
            inline[.font] = font
        } else {
            print("⚠️ Font not found: \(AppFont.bold)")
        }

        // Style used once the user scrolls and the bar gets its blurred background
        let scrolled = UINavigationBarAppearance()
        scrolled.configureWithDefaultBackground()
        scrolled.largeTitleTextAttributes = large
        scrolled.titleTextAttributes = inline

        // Style used when the large title sits at the top of the screen
        let atTop = UINavigationBarAppearance()
        atTop.configureWithTransparentBackground()
        atTop.largeTitleTextAttributes = large
        atTop.titleTextAttributes = inline

        let bar = UINavigationBar.appearance()
        bar.standardAppearance = scrolled
        bar.compactAppearance = scrolled
        bar.scrollEdgeAppearance = atTop

        // Tab bar labels
        if let tab = UIFont(name: AppFont.semiBold, size: 10) {
            UITabBarItem.appearance().setTitleTextAttributes([.font: tab], for: .normal)
            UITabBarItem.appearance().setTitleTextAttributes([.font: tab], for: .selected)
        }
    }
    var body: some Scene {
        WindowGroup {
            Group {
                if profileStore.hasCompletedOnboarding {
                    RootTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(profileStore)
        }
    }
}

/// Ties together the four tabs: Home (logging), Analytics (patterns),
/// Calendar (history), Discover (facts/articles, placeholder for now).
struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }

            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            DiscoverView()
                .tabItem { Label("Discover", systemImage: "newspaper.fill") }
        }
        .tint(Theme.primary)
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView().environmentObject(UserProfileStore())
    }
}
