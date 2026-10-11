import SwiftUI

/// opens up all logged episodes in list view for a given day
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
