import SwiftUI

/// Core Flow 3: user reviews historical patterns and past episode details
/// via a calendar view. Days with a logged episode are highlighted;
/// tapping one shows that day's episode(s) — if there's more than one
/// (e.g. multiple episodes logged the same day), a list appears first,
/// otherwise it jumps straight to that single episode's detail.
struct CalendarView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var displayedMonth = Date()
    @State private var selectedDayEpisodes: [Episode]?
    @State private var selectedDayDate: Date?
    @State private var selectedSingleEpisode: Episode?

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    monthHeader

                    if viewModel.isLoading {
                        LoadingView()
                    } else {
                        calendarGrid
                            .cardStyle()
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Calendar")
            .task { await load() }
            .sheet(item: $selectedSingleEpisode) { episode in
                EpisodeDetailView(episode: episode)
            }
            .sheet(isPresented: Binding(
                get: { selectedDayEpisodes != nil },
                set: { if !$0 { selectedDayEpisodes = nil } }
            )) {
                if let episodes = selectedDayEpisodes, let date = selectedDayDate {
                    DayEpisodesListView(date: date, episodes: episodes)
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
            }
        }
        .foregroundColor(Theme.primary)
    }

    private var calendarGrid: some View {
        let days = daysInDisplayedMonth()
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days, id: \.self) { day in
                if day == 0 {
                    Color.clear.frame(height: 36)
                } else {
                    dayCell(day)
                }
            }
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let episodesThatDay = viewModel.episodesByDay[day] ?? []
        let hasEpisode = !episodesThatDay.isEmpty
        
        // 1. Calculate if this specific cell represents 'today'
        var isToday = false
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.day = day
        if let cellDate = calendar.date(from: components) {
            isToday = calendar.isDateInToday(cellDate)
        }
        
        // 2. Define your custom hex color (#B3D89C)
        let todayColor = Color(red: 179/255, green: 216/255, blue: 156/255)

        return Button {
            guard !episodesThatDay.isEmpty else { return }

            if episodesThatDay.count == 1 {
                // Only one episode that day — skip the list, go straight to detail.
                selectedSingleEpisode = episodesThatDay.first
            } else {
                // Multiple episodes logged the same day — show them all in a list.
                selectedDayDate = episodesThatDay.first?.date
                selectedDayEpisodes = episodesThatDay
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.caption)
                if hasEpisode && episodesThatDay.count > 1 {
                    Text("\(episodesThatDay.count)")
                        .font(.system(size: 9, weight: .bold))
                }
            }
            .frame(width: 36, height: 36)
            // Apply the background logic:
            // If it has an episode -> Theme.accent
            // If it doesn't have an episode but IS today -> todayColor
            // Otherwise -> light gray
            .background(hasEpisode ? Theme.accent : (isToday ? todayColor : Color.gray.opacity(0.1)))
            // Make text white if it's highlighted with either color
            .foregroundColor(hasEpisode || isToday ? .white : Theme.textPrimary)
            .clipShape(Circle())
        }
        .disabled(!hasEpisode)
    }

    private func daysInDisplayedMonth() -> [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        // Leading blanks so day 1 lands under the correct weekday column.
        let weekday = calendar.component(.weekday, from: firstOfMonth) - 1
        return Array(repeating: 0, count: weekday) + Array(range)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            Task { await load() }
        }
    }

    private func load() async {
        let year = calendar.component(.year, from: displayedMonth)
        let month = calendar.component(.month, from: displayedMonth)
        await viewModel.loadMonth(year: year, month: month)
    }
}

struct CalendarView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarView()
    }
}
