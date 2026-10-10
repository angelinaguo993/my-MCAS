import SwiftUI

/// Home tab: greeting header over the gradient, days since last episode,
/// total episodes, medications, and the Record Episode button.
struct DashboardView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingEpisodeLog = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                // Gradient sits BEHIND the scroll view so it reaches the top of the screen.
                VStack(spacing: 0) {
                    GradientHeroBackground()
                        .frame(height: 460)
                    Spacer(minLength: 0)
                }
                .ignoresSafeArea(edges: .top)

                ScrollView {
                    VStack(spacing: 0) {
                        HomeHeroHeader(name: profileStore.profile?.name) {
                            showingSettings = true
                        }

                        VStack(spacing: 20) {
                            if let error = viewModel.errorMessage {
                                errorBanner(error)
                            }
                            daysSinceCard
                            totalLoggedCard
                            if let insights = viewModel.insights, insights.hasEnoughData {
                                medicationsUsedCard(insights.medicationEffectiveness)
                            }
                            recordButton
                        }
                        .padding()
                    }
                }
                .overlay {
                    if viewModel.isLoading && viewModel.stats == nil {
                        LoadingView()
                            .allowsHitTesting(false)   // never blocks taps on the gear/button
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.loadDashboard() }
            .refreshable { await viewModel.loadDashboard() }
            .sheet(isPresented: $showingEpisodeLog, onDismiss: {
                Task { await viewModel.loadDashboard() }
            }) {
                EpisodeLogView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: Cards

    private var daysSinceCard: some View {
        VStack(spacing: 8) {
            Text("Days Since Last Episode")
                .font(.nSubheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.7))

            if let days = viewModel.stats?.daysSinceLastEpisode {
                Text("\(days)")
                    .font(.app(AppFont.extraBold, size: 56, relativeTo: .largeTitle))
                    .foregroundColor(Theme.primary)
            } else {
                Text("—")