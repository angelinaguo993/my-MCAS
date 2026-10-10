import SwiftUI

/// Discover tab: "did you know" fact that changes daily, browsable fact cards,
/// and links to the sources they came from
struct DiscoverView: View {
    @State private var category: DiscoverCategory = .all

    private var visibleFacts: [DiscoverFact] {
        category == .all
            ? DiscoverContent.facts
            : DiscoverContent.facts.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        factOfTheDayCard(DiscoverContent.factOfTheDay())

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Browse")
                                .font(.nTitle2)
                                .foregroundColor(Theme.textPrimary)
                            ChipGrid(
                                items: DiscoverCategory.allCases,
                                isSelected: { category == $0 },
                                label: { $0.title },
                                onTap: { category = $0 }
                            )
                        }

                        ForEach(visibleFacts) { fact in
                            factCard(fact)
                        }

                        articlesSection
                        disclaimerCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Discover")
        }
    }

    // MARK: Fact cards

    private func factOfTheDayCard(_ fact: DiscoverFact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DID YOU KNOW?")
                .font(.nCaptionBold)
                .tracking(1.5)
                .foregroundColor(Theme.textPrimary.opacity(0.65))
            Text(fact.title)
                .font(.app(AppFont.extraBold, size: 24, relativeTo: .title2))
                .foregroundColor(Theme.textPrimary)
            Text(fact.body)
                .font(.nSubheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.85))
            sourceLink(fact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Theme.primary.opacity(0.35), Theme.accent.opacity(0.25)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
    }

    private func factCard(_ fact: DiscoverFact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: fact.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .frame(width: 32, height: 32)
                    .background(Theme.accent.opacity(0.12), in: Circle())
                Text(fact.title)
                    .font(.nHeadline)
                    .foregroundColor(Theme.textPrimary)
            }
            Text(fact.body)
                .font(.nSubheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.8))
            sourceLink(fact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private func sourceLink(_ fact: DiscoverFact) -> some View {
        if let url = fact.sourceURL {
            Link(destination: url) {
                HStack(spacing: 4) {
                    Text("Source: \(fact.sourceName)")
                    Image(systemName: "arrow.up.right")
                }
                .font(.nCaptionBold)
                .foregroundColor(Theme.accent)
            }
        } else {
            Text("Source: \(fact.sourceName)")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))
        }
    }

    // MARK: Articles

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keep reading")
                .font(.nTitle2)
                .foregroundColor(Theme.textPrimary)

            ForEach(DiscoverContent.articles) { article in
                Link(destination: article.url) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(article.source.uppercased())
                            .font(.nCaptionBold)
                            .tracking(1)
                            .foregroundColor(Theme.accent)
                        Text(article.title)
                            .font(.nHeadline)
                            .foregroundColor(Theme.textPrimary)
                            .multilineTextAlignment(.leading)
                        Text(article.summary)
                            .font(.nCaption)
                            .foregroundColor(Theme.textPrimary.opacity(0.7))
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
            }
        }
    }

    private var disclaimerCard: some View {
        Text("This is general education, not medical advice. MCAS is still debated and everyone's situation is different, so talk with a clinician about your own symptoms. Sources checked \(DiscoverContent.lastReviewed). In an emergency (trouble breathing, swelling of the throat or tongue, fainting), call 911.")
            .font(.nCaption)
            .foregroundColor(Theme.textPrimary.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 8)
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}