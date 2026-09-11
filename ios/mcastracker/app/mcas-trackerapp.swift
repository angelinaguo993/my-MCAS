import SwiftUI

@main
struct MCASTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
    }
}

/// Ties together the three core flows: Dashboard, History (calendar), Education.
struct RootTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }

            CalendarView()
                .tabItem { Label("History", systemImage: "calendar") }
        }
        .tint(Theme.primary)
    }
}

struct RootTabView_Previews: PreviewProvider {
    static var previews: some View {
        RootTabView()
    }
}
