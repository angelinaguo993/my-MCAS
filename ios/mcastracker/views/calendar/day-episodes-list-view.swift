import SwiftUI

/// opens up all logged episodes in list view for a given day
struct DayEpisodesListView: View {
    let date: Date
    let episodes: [Episode]
    var onDelete: (Episode) -> Void = { _ in }
    @State private var visibleEpisodes: [Episode]

    init(date: Date, episodes: [Episode], onDelete: @escaping (Episode) -> Void = { _ in }) {
        self.date = date
        self.episodes = episodes
        self.onDelete = onDelete
        _visibleEpisodes = State(initialValue: episodes)
    }

    var body: some View {
        NavigationStack {
            List(visibleEpisodes) { episode in
                NavigationLink {
                    EpisodeDetailView(episode: episode) { deletedEpisode in
                        visibleEpisodes.removeAll { $0.id == deletedEpisode.id }
                        onDelete(deletedEpisode)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(episode.date.formatted(date: .omitted, time: .shortened))
                                .font(.nSubheadlineBold)
                                .foregroundColor(Theme.textPrimary)
                            if !episode.symptoms.isEmpty {
                                Text(episode.symptoms.map { $0.category.displayName }.joined(separator: ", "))
                                    .font(.nCaption)
                                    .foregroundColor(Theme.textPrimary.opacity(0.6))
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Text("\(episode.overallSeverity)/10")
                            .font(.nSubheadlineBold)
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.vertical, 4)
                }
            }
            .overlay {
                if visibleEpisodes.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(Theme.primary)
                        Text("No episodes on this date")
                            .font(.nSubheadline)
                            .foregroundColor(Theme.textPrimary.opacity(0.75))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
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
