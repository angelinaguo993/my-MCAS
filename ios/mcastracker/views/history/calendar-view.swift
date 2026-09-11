import SwiftUI

/// Core Flow 3: user reviews historical patterns and past episode details
/// via a calendar view. Days with a logged episode are highlighted;
/// tapping one shows that day's details.
struct CalendarView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @State private var displayedMonth = Date()
    @State private var selectedEpisode: Episode?

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
            .navigationTitle("History")
            .task { await load() }
            .sheet(item: $selectedEpisode) { episode in
                EpisodeDetailView(episode: episode)
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

        return Button {
            if let first = episodesThatDay.first {
                selectedEpisode = first
            }
        } label: {
            Text("\(day)")
                .font(.caption)
                .frame(width: 36, height: 36)
                .background(hasEpisode ? Theme.accent : Color.gray.opacity(0.1))
                .foregroundColor(hasEpisode ? .white : Theme.textPrimary)
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
