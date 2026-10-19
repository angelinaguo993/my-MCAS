import SwiftUI

/// Discover tab: source-linked MCAS education with topic filters and expandable reads.
struct DiscoverView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedCategories: Set<DiscoverCategory> = [.all]
    @State private var searchText = ""
    @State private var expandedFactIDs: Set<String> = []

    private let categoryColumns = [GridItem(.flexible()), GridItem(.flexible())]

    private var visibleFacts: [DiscoverFact] {
        DiscoverContent.facts.filter { fact in
            let categoryMatches = selectedCategories.contains(.all) || selectedCategories.contains(fact.category)
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let searchMatches = query.isEmpty
                || fact.title.localizedCaseInsensitiveContains(query)
                || fact.body.localizedCaseInsensitiveContains(query)
                || fact.sourceName.localizedCaseInsensitiveContains(query)
            return categoryMatches && searchMatches
        }
    }

    private var visibleArticles: [DiscoverArticle] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return DiscoverContent.articles }
        return DiscoverContent.articles.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.summary.localizedCaseInsensitiveContains(query)
                || $0.source.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            factOfTheDayCard(DiscoverContent.factOfTheDay()) { category in
                                selectOnly(category)
                                move(to: "browse", using: proxy)
                            }

                            searchField

                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Explore facts by topic")
                                        .font(.nTitle2)
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text("\(visibleFacts.count) facts")
                                        .font(.nCaptionBold)
                                        .foregroundColor(Theme.textPrimary.opacity(0.65))
                                }
                                categoryFilters
                            }
                            .id("browse")

                            if visibleFacts.isEmpty && visibleArticles.isEmpty {
                                noSearchResults
                            } else {
                                if !visibleFacts.isEmpty {
                                    factsSection
                                }
                                if !visibleArticles.isEmpty {
                                    articlesSection
                                }
                            }

                            disclaimerCard
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
            .navigationTitle("Discover")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Theme.primary)
            TextField("Search facts and articles", text: $searchText)
                .font(.nSubheadline)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .frame(minHeight: 44)
                .accessibilityLabel("Search facts and articles")
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.textPrimary.opacity(0.55))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.leading, 14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
    }

    private var categoryFilters: some View {
        LazyVGrid(columns: categoryColumns, spacing: 8) {
            ForEach(DiscoverCategory.allCases) { category in
                let isSelected = selectedCategories.contains(.all)
                    ? category == .all
                    : selectedCategories.contains(category)
                Button {
                    toggle(category)
                } label: {
                    HStack(spacing: 8) {
                        Text(category.displayName)
                            .font(.nSubheadlineBold)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        isSelected ? Theme.primary.opacity(0.24) : Color(.systemBackground),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selectedCategories)
    }

    private var factsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Facts")
                .font(.nTitle2)
                .foregroundColor(Theme.textPrimary)
            ForEach(visibleFacts) { fact in
                factCard(fact)
            }
        }
        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: visibleFacts.map(\.id))
    }

    private var noSearchResults: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("No matches", systemImage: "text.magnifyingglass")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Text("Try a different search or choose another topic.")
                .font(.nSubheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.7))
            Button("Clear search and topics") {
                searchText = ""
                selectedCategories = [.all]
            }
            .font(.nSubheadlineBold)
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: Featured fact

    private func factOfTheDayCard(_ fact: DiscoverFact, onBrowse: @escaping (DiscoverCategory) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text(fact.title)
                    .font(.app(AppFont.extraBold, size: 25, relativeTo: .title2))
                    .foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: fact.icon)
                    .font(.title2)
                    .foregroundColor(Theme.textPrimary.opacity(0.85))
            }
            Text(fact.body)
                .font(.nSubheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.88))
            sourceLink(fact)

            Button {
                onBrowse(fact.category)
            } label: {
                Label("Explore \(fact.category.displayName)", systemImage: "arrow.down")
                    .font(.nSubheadlineBold)
                    .foregroundColor(Theme.textPrimary)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Theme.primary.opacity(0.35), Theme.accent.opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
        )
    }

    // MARK: Browse

    private func factCard(_ fact: DiscoverFact) -> some View {
        DisclosureGroup(
            isExpanded: Binding(
                get: { expandedFactIDs.contains(fact.id) },
                set: { expanded in
                    if expanded {
                        expandedFactIDs.insert(fact.id)
                    } else {
                        expandedFactIDs.remove(fact.id)
                    }
                }
            )
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text(fact.body)
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.82))
                sourceLink(fact)
            }
            .padding(.top, 8)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: fact.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Theme.accent)
                    .frame(width: 34, height: 34)
                    .background(Theme.accent.opacity(0.12), in: Circle())
                Text(fact.title)
                    .font(.nHeadline)
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 4)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .tint(Theme.primary)
        .cardStyle()
    }

    @ViewBuilder
    private func sourceLink(_ fact: DiscoverFact) -> some View {
        if let url = fact.sourceURL {
            Link(destination: url) {
                Label("Read source: \(fact.sourceName)", systemImage: "arrow.up.right")
                    .font(.nCaptionBold)
                    .foregroundColor(Theme.accent)
                    .frame(minHeight: 44, alignment: .leading)
            }
        } else {
            Text("Source: \(fact.sourceName)")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.65))
        }
    }

    // MARK: Articles

    private var articlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keep reading")
                .font(.nTitle2)
                .foregroundColor(Theme.textPrimary)

            ForEach(visibleArticles) { article in
                Link(destination: article.url) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.title3)
                            .foregroundColor(Theme.accent)
                            .frame(width: 40, height: 40)
                            .background(Theme.accent.opacity(0.12), in: Circle())
                        VStack(alignment: .leading, spacing: 6) {
                            Text(article.source)
                                .font(.nCaptionBold)
                                .foregroundColor(Theme.accent)
                            Text(article.title)
                                .font(.nHeadline)
                                .foregroundColor(Theme.textPrimary)
                                .multilineTextAlignment(.leading)
                            Text(article.summary)
                                .font(.nCaption)
                                .foregroundColor(Theme.textPrimary.opacity(0.72))
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Theme.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var disclaimerCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "cross.case.fill")
                .foregroundColor(Theme.primary)
            Text("This is general education, not medical advice. MCAS is still debated and everyone's situation is different, so talk with a clinician about your own symptoms. Sources checked \(DiscoverContent.lastReviewed). In an emergency (trouble breathing, swelling of the throat or tongue, fainting), call 911.")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
    }

    private func toggle(_ category: DiscoverCategory) {
        guard category != .all else {
            selectedCategories = [.all]
            return
        }
        if selectedCategories.contains(.all) {
            selectedCategories = [category]
        } else if selectedCategories.contains(category) {
            selectedCategories.remove(category)
            if selectedCategories.isEmpty { selectedCategories = [.all] }
        } else {
            selectedCategories.insert(category)
        }
    }

    private func selectOnly(_ category: DiscoverCategory) {
        searchText = ""
        selectedCategories = [category]
    }

    private func move(to id: String, using proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo(id, anchor: .top)
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(id, anchor: .top)
            }
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
