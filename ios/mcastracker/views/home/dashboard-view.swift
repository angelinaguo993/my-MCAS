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

    // MARK: - Cards & Components

    private func errorBanner(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(Theme.textPrimary)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(10)
    }

    private var daysSinceCard: some View {
        VStack(spacing: 8) {
            Text("Days Since Last Episode")
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.7))

            if let days = viewModel.stats?.daysSinceLastEpisode {
                Text("\(days)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(Theme.primary)
            } else {
                Text("—")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(Theme.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var totalLoggedCard: some View {
        VStack(spacing: 8) {
            Text("Total Episodes Logged")
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.7))

            // Pulls from insights model where total episodes count is tracked
            Text("\(viewModel.insights?.totalEpisodes ?? 0)")
                .font(.title.bold())
                .foregroundColor(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private func medicationsUsedCard(_ meds: [FrequencyStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medication Summary")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            ForEach(Array(meds.enumerated()), id: \.element.name) { index, stat in
                HStack {
                    // Left side: Medication name
                    Text(stat.name)
                        .font(.body)
                        .foregroundColor(Theme.textPrimary)
                    
                    Spacer()
                    
                    // Right side: Percentage of effectiveness / helpfulness
                    Text("\(Int(stat.proportion * 100))% effective")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.accent)
                }
                
                // Add a divider for all rows except the last one
                if index < meds.count - 1 {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var recordButton: some View {
        Button {
            showingEpisodeLog = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                Text("Record Episode")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Theme.accent)
            .cornerRadius(12)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UserProfileStore())
    }
}