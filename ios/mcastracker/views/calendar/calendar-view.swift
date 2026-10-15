import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var displayedMonth = Date()
    @State private var selectedDayEpisodes: [Episode]?
    @State private var selectedDayDate: Date?
    @State private var selectedSingleEpisode: Episode?
    @State private var selectedDate: Date?
    
    @State private var viewMode: CalendarViewMode = .calendar
    @State private var selectedTimeframe: TrendTimeframe = .oneMonth // Default to 1 month

    enum CalendarViewMode: String, CaseIterable, Identifiable {
        case calendar = "Calendar"
        case trends = "Trends"
        var id: String { rawValue }
    }

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 12) {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(CalendarViewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .onChange(of: viewMode) { _ in
                        Task { await load() }
                    }

                    if viewMode == .calendar {
                        ScrollView {
                            VStack(spacing: 16) {
                                monthHeader
                                if let error = viewModel.errorMessage {
                                    errorBanner(error)
                                }
                                if viewModel.isLoading {
                                    LoadingView()
                                } else {
                                    calendarCard
                                    selectedDaySummary
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .refreshable { await load() }
                    } else {
                        VStack(spacing: 16) {
                            Picker("Timeframe", selection: $selectedTimeframe) {
                                ForEach(TrendTimeframe.allCases) { frame in
                                    Text(frame.rawValue).tag(frame)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 16)
                            .onChange(of: selectedTimeframe) { _ in
                                Task { await load() }
                            }

                            if let error = viewModel.errorMessage {
                                errorBanner(error)
                                    .padding(.horizontal)
                            }

                            if viewModel.isLoading {
                                LoadingView()
                            } else {
                                ScrollView {
                                    VStack(spacing: 20) {
                                        // feeds filtered trendEpisodes array to the chart
                                        SeverityTrendChart(episodes: viewModel.trendEpisodes)
                                        trendSummaryCard
                                        mostFrequentTriggersCard
                                        mostFrequentSymptomsCard
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .refreshable { await load() }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .navigationTitle("History & Trends")
            .task { await load() }
            .sheet(item: $selectedSingleEpisode) { episode in
                EpisodeDetailView(episode: episode) { _ in
                    Task { await load() }
                }
            }
            .sheet(isPresented: Binding(
                get: { selectedDayEpisodes != nil },
                set: { if !$0 { selectedDayEpisodes = nil } }
            )) {
                if let episodes = selectedDayEpisodes, let date = selectedDayDate {
                    DayEpisodesListView(date: date, episodes: episodes) { deletedEpisode in
                        if selectedDayEpisodes?.count == 1 {
                            selectedDayEpisodes = nil
                            selectedDayDate = nil
                        } else {
                            selectedDayEpisodes?.removeAll { $0.id == deletedEpisode.id }
                        }
                        Task { await load() }
                    }
                }
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button { changeMonth(by: -1) } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Previous month")
            Spacer(minLength: 8)
            Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            Button { changeMonth(by: 1) } label: {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Next month")
        }
        .foregroundColor(Theme.primary)
        .padding(.horizontal, 8)
    }

    private var calendarCard: some View {
        VStack(spacing: 14) {
            HStack {
                Label("\(viewModel.episodes.count) episodes", systemImage: "waveform.path.ecg")
                Spacer()
                Label("\(viewModel.episodesByDay.count) days", systemImage: "calendar")
            }
            .font(.nCaptionBold)
            .foregroundColor(Theme.textPrimary.opacity(0.75))

            calendarGrid

            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 8, height: 8)
                Text("Days with episode logs · tap a date to inspect it")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.65))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
        .padding(.vertical, Theme.cardPadding)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    @ViewBuilder
    private var selectedDaySummary: some View {
        if let selectedDate {
            let count = viewModel.episodesByDay[calendar.component(.day, from: selectedDate)]?.count ?? 0
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: count > 0 ? "waveform.path.ecg" : "calendar")
                    .font(.title3)
                    .foregroundColor(count > 0 ? Theme.accent : Theme.primary)
                    .frame(width: 36, height: 36)
                    .background(Theme.primary.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                        .font(.nSubheadlineBold)
                        .foregroundColor(Theme.textPrimary)
                    Text(count == 0 ? "No episodes logged on this date." : "\(count) episode\(count == 1 ? "" : "s") logged for this date.")
                        .font(.nCaption)
                        .foregroundColor(Theme.textPrimary.opacity(0.7))
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
            .padding(.horizontal, 4)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(Theme.accent)
            Text(message)
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary)
            Spacer(minLength: 4)
            Button("Retry") { Task { await load() } }
                .font(.nCaptionBold)
                .frame(minHeight: 44)
        }
        .padding(.horizontal, 12)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
    }

    private var trendSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(selectedTimeframe.rawValue) Summary")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            
            let totalEpisodes = viewModel.trendEpisodes.count
            let avgSeverity = totalEpisodes > 0 ? Double(viewModel.trendEpisodes.reduce(0) { $0 + $1.overallSeverity }) / Double(totalEpisodes) : 0
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Episodes")
                        .font(.nSubheadline)
                        .foregroundColor(Theme.textPrimary.opacity(0.65))
                    Text("\(totalEpisodes)")
                        .font(.nHeadline)
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Average Severity")
                        .font(.nSubheadline)
                        .foregroundColor(Theme.textPrimary.opacity(0.65))
                    Text(totalEpisodes == 0 ? "—" : String(format: "%.1f / 10", avgSeverity))
                        .font(.nHeadline)
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .cardStyle()

    }

    private var mostFrequentTriggersCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Most Frequent Triggers")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)

            let counts = countOccurrences(viewModel.trendEpisodes.flatMap { $0.triggers.map { $0.rawValue } })

            if counts.isEmpty {
                Text("No triggers logged in this timeframe")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.65))
            } else {
                ForEach(counts.prefix(5), id: \.name) { item in
                    trendFrequencyRow(
                        label: Trigger.from(rawValue: item.name)?.displayName ?? item.name,
                        icon: Trigger.from(rawValue: item.name)?.iconName ?? "questionmark.circle.fill",
                        count: item.count,
                        maximum: counts.first?.count ?? 1
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var mostFrequentSymptomsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Most Frequent Symptoms")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)

            let counts = countOccurrences(viewModel.trendEpisodes.flatMap { $0.symptoms.map { $0.category.rawValue } })

            if counts.isEmpty {
                Text("No symptoms logged in this timeframe")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.65))
            } else {
                ForEach(counts.prefix(5), id: \.name) { item in
                    trendFrequencyRow(
                        label: SymptomCategory(rawValue: item.name)?.displayName ?? item.name,
                        icon: SymptomCategory(rawValue: item.name)?.iconName ?? "questionmark.circle.fill",
                        count: item.count,
                        maximum: counts.first?.count ?? 1
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func trendFrequencyRow(label: String, icon: String, count: Int, maximum: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Theme.primary)
                    .frame(width: 24)
                Text(label)
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer(minLength: 8)
                Text("\(count)")
                    .font(.nCaptionBold)
                    .foregroundColor(Theme.accent)
            }
            ProgressView(value: Double(count), total: Double(max(1, maximum)))
                .tint(Theme.accent)
                .accessibilityLabel("\(label): \(count) logged")
        }
    }

    private func countOccurrences(_ values: [String]) -> [(name: String, count: Int)] {
        var counts: [String: Int] = [:]
        for value in values {
            counts[value, default: 0] += 1
        }
        return counts.map { (name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var calendarGrid: some View {
        let days = daysInDisplayedMonth()
        let weekdaySymbols = calendar.veryShortStandaloneWeekdaySymbols
        let weekdayStart = max(0, calendar.firstWeekday - 1)
        let orderedWeekdays = Array(weekdaySymbols[weekdayStart...]) + Array(weekdaySymbols[..<weekdayStart])

        return VStack(spacing: 10) {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(orderedWeekdays.indices, id: \.self) { index in
                    Text(orderedWeekdays[index])
                        .font(.nCaptionBold)
                        .foregroundColor(Theme.textPrimary.opacity(0.6))
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(days.indices, id: \.self) { index in
                    let day = days[index]
                    if day == 0 {
                        Color.clear.frame(maxWidth: .infinity, minHeight: 44)
                    } else {
                        dayCell(day)
                    }
                }
            }
        }
    }

    private func dayCell(_ day: Int) -> some View {
        let episodesThatDay = viewModel.episodesByDay[day] ?? []
        let hasEpisode = !episodesThatDay.isEmpty
        
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.day = day
        let cellDate = calendar.date(from: components)
        let isToday = cellDate.map(calendar.isDateInToday) ?? false
        let isSelected: Bool
        if let cellDate, let selectedDate {
            isSelected = calendar.isDate(selectedDate, inSameDayAs: cellDate)
        } else {
            isSelected = false
        }

        return Button {
            selectedDate = cellDate
            if !episodesThatDay.isEmpty {
                if episodesThatDay.count == 1 {
                    selectedSingleEpisode = episodesThatDay.first
                } else {
                    selectedDayDate = cellDate
                    selectedDayEpisodes = episodesThatDay
                }
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.nCaption)
                Circle()
                    .fill(hasEpisode ? Theme.accent : .clear)
                    .frame(width: 5, height: 5)
                    .accessibilityHidden(true)
            }
            .frame(width: 34, height: 34)
            .background(
                hasEpisode ? Theme.accent.opacity(0.15)
                    : (isToday ? Theme.success.opacity(0.28) : Color.gray.opacity(0.1))
            )
            .foregroundColor(Theme.textPrimary)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(
                        isSelected ? Theme.primary : (isToday ? Theme.success : .clear),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .padding(1)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: day, episodes: episodesThatDay, isToday: isToday))
        .accessibilityHint(episodesThatDay.isEmpty ? "Select this date" : "Opens logged episodes for this date")
    }

    private func accessibilityLabel(for day: Int, episodes: [Episode], isToday: Bool) -> String {
        var components = calendar.dateComponents([.year, .month], from: displayedMonth)
        components.day = day
        let date = components.date?.formatted(date: .complete, time: .omitted) ?? "Day \(day)"
        if episodes.isEmpty {
            return isToday ? "\(date), today, no episodes logged" : "\(date), no episodes logged"
        }
        return "\(date), \(episodes.count) episode\(episodes.count == 1 ? "" : "s") logged"
    }

    private func daysInDisplayedMonth() -> [Int] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))
        else { return [] }

        let weekday = (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7
        return Array(repeating: 0, count: weekday) + Array(range)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
            selectedDate = nil
            Task { await load() }
        }
    }

    private func load() async {
        if viewMode == .calendar {
            let year = calendar.component(.year, from: displayedMonth)
            let month = calendar.component(.month, from: displayedMonth)
            await viewModel.loadMonth(year: year, month: month)
        } else {
            await viewModel.loadTrends(timeframe: selectedTimeframe)
        }
    }
}
