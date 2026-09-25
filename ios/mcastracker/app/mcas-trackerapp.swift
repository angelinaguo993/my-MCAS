import SwiftUI

@main
struct MCASTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
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
        RootTabView()
    }
}
