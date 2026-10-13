import SwiftUI

/// Home tab: greeting header over the gradient, days since last episode,
/// total episodes, medications, and record ep button
struct DashboardView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingEpisodeLog = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

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
                            medicationsSummaryCard
                            recordButton
                        }
                        .padding()
                    }
                }
                .overlay {
                    if viewModel.isLoading && viewModel.stats == nil {
                        LoadingView()
                            .allowsHitTesting(false)
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

    private var medicationsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medication Summary")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            // 1. Show medications tracked from onboarding or episodes
            if let prescribedMeds = profileStore.profile?.prescribedMedications, !prescribedMeds.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tracked Medications")
                        .font(.caption.bold())
                        .foregroundColor(Theme.textPrimary.opacity(0.6))
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(prescribedMeds, id: \.self) { med in
                            Text(med)
                                .font(.subheadline)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .background(Theme.primary.opacity(0.12))
                                .foregroundColor(Theme.textPrimary)
                                .cornerRadius(8)
                        }
                    }
                }
            }

            // 2. Show effectiveness stats if available from insights
            if let insights = viewModel.insights, insights.hasEnoughData, !insights.medicationEffectiveness.isEmpty {
                Divider()
                Text("Effectiveness")
                    .font(.caption.bold())
                    .foregroundColor(Theme.textPrimary.opacity(0.6))

                ForEach(Array(insights.medicationEffectiveness.enumerated()), id: \.element.name) { index, stat in
                    HStack {
                        Text(stat.name)
                            .font(.body)
                            .foregroundColor(Theme.textPrimary)
                        
                        Spacer()
                        
                        Text("\(Int(stat.proportion * 100))% effective")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.accent)
                    }
                    
                    if index < insights.medicationEffectiveness.count - 1 {
                        Divider()
                    }
                }
            } else if (profileStore.profile?.prescribedMedications ?? []).isEmpty {
                Text("No medications added yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
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