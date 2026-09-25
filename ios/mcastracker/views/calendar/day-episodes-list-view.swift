import SwiftUI

/// Shown when a calendar day has more than one logged episode — lists all
/// of them, and tapping one opens its full detail. If a day has exactly
/// one episode, CalendarView skips straight to EpisodeDetailView instead
/// of showing this intermediate list.
struct DayEpisodesListView: View {
    let date: Date
    let episodes: [Episode]

    var body: some View {
        NavigationStack {
            List(episodes) { episode in
                NavigationLink {
                    EpisodeDetailView(episode: episode)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(episode.date.formatted(date: .omitted, time: .shortened))
                                .font(.subheadline.bold())
                                .foregroundColor(Theme.textPrimary)
                            if !episode.symptoms.isEmpty {
                                Text(episode.symptoms.map { $0.category.displayName }.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(Theme.textPrimary.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Text("\(episode.overallSeverity)/10")
                            .font(.subheadline.bold())
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DayEpisodesListView_Previews: PreviewProvider {
    static var previews: some View {
        DayEpisodesListView(date: Date(), episodes: [])
    }
}
