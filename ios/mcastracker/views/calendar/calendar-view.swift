import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var displayedMonth = Date()
    @State private var selectedDayEpisodes: [Episode]?
    @State private var selectedDayDate: Date?
    @State private var selectedSingleEpisode: Episode?
    
    // View state trackers
    @State private var viewMode: CalendarViewMode = .calendar
    @State private var selectedTimeframe: TrendTimeframe = .oneMonth // Default to 1 month

    enum CalendarViewMode: String, CaseIterable, Identifiable {
        case calendar = "Calendar"
        case trends = "Trends"
        var id: String { rawValue }
    }

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    
                    // Main Toggle: Calendar vs Trends
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: viewMode) { _ in
                        Task { await load() }
                    }

                    if viewMode == .calendar {
                        // === CALENDAR UI ===
                        monthHeader

                        if viewModel.isLoading {
                            LoadingView()
                        } else {
                            calendarGrid
                                .cardStyle()
                        }
                    } else {
                        // === TRENDS UI ===
                        VStack(spacing: 16) {
                            // Sub-Toggle: 1W / 1M / 3M
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(TrendTimeframe.allCases) { frame in
                                    Text(frame.rawValue).tag(frame)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .onChange(of: selectedTimeframe) { _ in
                                Task { await load() }
                            }

                            if viewModel.isLoading {
                                LoadingView()
                            } else {
                                ScrollView {
                                    VStack(spacing: 20) {
                                        // Feeds the filtered trendEpisodes array to the chart
                                        SeverityTrendChart(episodes: viewModel.trendEpisodes)
                                        
                                        trendSummaryCard
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("History & Trends")
            .navigationBarTitleDisplayMode(.inline)
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
        .padding(.horizontal)
    }

    private var trendSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(selectedTimeframe.rawValue) Summary")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            
            let totalEpisodes = viewModel.trendEpisodes.count
            let avgSeverity = totalEpisodes > 0 ? Double(viewModel.trendEpisodes.reduce(0) { $0 + $1.overallSeverity }) / Double(totalEpisodes) : 0
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Episodes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("\(totalEpisodes)")
                        .font(.title2.bold())
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Average Severity")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f / 10", avgSeverity))
                        .font(.title2.bold())
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .cardStyle()
    }

    private var calendarGrid: some View {
        let days = daysInDisplayedMonth()
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(days.indices, id: \.self) { index in
                let day = days[index]
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
        
        var isToday = false
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.day = day
        if let cellDate = calendar.date(from: components) {
            isToday = calendar.isDateInToday(cellDate)
        }
        
        let todayColor = Color(red: 179/255, green: 216/255, blue: 156/255)

        return Button {
            guard !episodesThatDay.isEmpty else { return }
            if episodesThatDay.count == 1 {
                selectedSingleEpisode = episodesThatDay.first
            } else {
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
            .background(hasEpisode ? Theme.accent : (isToday ? todayColor : Color.gray.opacity(0.1)))
            .foregroundColor(hasEpisode || isToday ? .white : Theme.textPrimary)
            .clipShape(Circle())
        }
        .disabled(!hasEpisode)
    }

    private func daysInDisplayedMonth() -> [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

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
        if viewMode == .calendar {
            let year = calendar.component(.year, from: displayedMonth)
            let month = calendar.component(.month, from: displayedMonth)
            await viewModel.loadMonth(year: year, month: month)
        } else {
            // Tell the view model to fetch the custom timeframe array
            await viewModel.loadTrends(timeframe: selectedTimeframe)
        }
    }
}