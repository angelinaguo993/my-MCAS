import SwiftUI

/// Home tab: record an episode first, then review a concise tracking overview.
struct DashboardView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingEpisodeLog = false
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    Theme.background.ignoresSafeArea()

                    GradientHeroBackground()
                        .frame(height: min(max(geometry.size.height * 0.42, 280), 380))
                        .ignoresSafeArea(edges: .top)

                    ScrollView {
                        VStack(spacing: 0) {
                            HomeHeroHeader(name: profileStore.profile?.name) {
                                showingSettings = true
                            }

                            VStack(alignment: .leading, spacing: 20) {
                                recordButton

                                if let message = viewModel.statsErrorMessage {
                                    HStack(alignment: .top) {
                                        Image(systemName: "arrow.clockwise.circle")
                                            .foregroundColor(Theme.primary)
                                        Text(message)
                                            .font(.caption)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer(minLength: 8)
                                        Button("Retry") {
                                            Task { await viewModel.loadStats() }
                                        }
                                        .font(.caption.weight(.semibold))
                                        .frame(minHeight: 44)
                                    }
                                }

                                HStack(alignment: .firstTextBaseline) {
                                    Text("Your overview")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    if let updatedAt = viewModel.statsUpdatedAt {
                                        Text("Updated \(updatedAt.formatted(date: .omitted, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(Theme.textPrimary.opacity(0.65))
                                            .accessibilityLabel("Episode overview updated at \(updatedAt.formatted(date: .omitted, time: .shortened))")
                                    }
                                }

                                episodeSummaryCard
                                medicationsSummaryCard
                            }
                            .padding()
                        }
                    }
                    .refreshable { await viewModel.loadDashboard() }
                    .overlay {
                        if viewModel.isLoading && viewModel.stats == nil && viewModel.insights == nil {
                            LoadingView()
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await viewModel.loadDashboard() }
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

    private var episodeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Days Since Last Episode")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer(minLength: 12)
                if let days = viewModel.stats?.daysSinceLastEpisode {
                    Text("\(days)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundColor(Theme.primary)
                        .contentTransition(.numericText())
                        .accessibilityLabel("\(days) days since last episode")
                } else if viewModel.statsErrorMessage != nil {
                    Text("Unavailable")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary.opacity(0.7))
                } else if viewModel.stats != nil {
                    Text("—")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(Theme.textPrimary.opacity(0.7))
                        .accessibilityLabel("No episodes recorded yet")
                } else {
                    ProgressView()
                        .tint(Theme.primary)
                        .accessibilityLabel("Loading episode timing")
                }
            }

            if viewModel.stats?.daysSinceLastEpisode != nil {
                Text("A tracking reference, not a measure of progress.")
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary.opacity(0.65))
            } else if viewModel.stats?.totalEpisodesLogged == 0 {
                Text("Your day count will appear after your first episode log.")
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary.opacity(0.65))
            }

            Divider()

            HStack(alignment: .firstTextBaseline) {
                Text("Total Episodes Logged")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer(minLength: 12)
                if let stats = viewModel.stats {
                    Text("\(stats.totalEpisodesLogged)")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundColor(Theme.textPrimary)
                } else if viewModel.statsErrorMessage != nil {
                    Text("Unavailable")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Theme.textPrimary.opacity(0.7))
                } else {
                    ProgressView()
                        .tint(Theme.primary)
                        .accessibilityLabel("Loading episode total")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var medicationsSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medication Summary")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            let prescribedMeds = profileStore.profile?.prescribedMedications ?? []
            if prescribedMeds.isEmpty {
                Text("Add medications you want to track alongside your episodes.")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.75))
                Button {
                    showingSettings = true
                } label: {
                    Label("Add medications", systemImage: "plus")
                        .font(.subheadline.weight(.semibold))
                        .frame(minHeight: 44)
                }
                .accessibilityHint("Opens settings where you can add medications to your tracking list")
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tracked Medications")
                        .font(.caption.bold())
                        .foregroundColor(Theme.textPrimary.opacity(0.65))

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                        ForEach(prescribedMeds, id: \.self) { med in
                            Text(med)
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Theme.primary.opacity(0.12))
                                .foregroundColor(Theme.textPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                Button("Edit tracked medications") {
                    showingSettings = true
                }
                .font(.caption.weight(.semibold))
                .frame(minHeight: 44, alignment: .leading)
            }

            Divider()

            if let message = viewModel.insightsErrorMessage, viewModel.insights != nil {
                HStack(alignment: .top) {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(Theme.textPrimary.opacity(0.8))
                    Spacer(minLength: 8)
                    Button("Retry") {
                        Task { await viewModel.loadInsights() }
                    }
                    .font(.caption.weight(.semibold))
                    .frame(minHeight: 44)
                }
            }

            if let insights = viewModel.insights {
                if let updatedAt = viewModel.insightsUpdatedAt {
                    Text("Pattern data updated \(updatedAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(Theme.textPrimary.opacity(0.65))
                }
                if !insights.medicationEffectiveness.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Patterns in your logs")
                            .font(.caption.bold())
                            .foregroundColor(Theme.textPrimary.opacity(0.65))
                        Text("Self-reported associations only; these don’t show whether a medication is medically effective.")
                            .font(.caption)
                            .foregroundColor(Theme.textPrimary.opacity(0.7))

                        ForEach(Array(insights.medicationEffectiveness.enumerated()), id: \.element.name) { index, stat in
                            HStack(alignment: .firstTextBaseline) {
                                Text(stat.name)
                                    .font(.body)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer(minLength: 12)
                                Text("\(Int((stat.proportion * 100).rounded()))% marked helpful · \(stat.sampleSize) uses")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(Theme.textPrimary)
                                    .multilineTextAlignment(.trailing)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(stat.name): marked helpful in \(Int((stat.proportion * Double(stat.sampleSize)).rounded())) of \(stat.sampleSize) logged uses")

                            if index < insights.medicationEffectiveness.count - 1 {
                                Divider()
                            }
                        }
                    }
                } else if !insights.hasEnoughData {
                    Text("Log \(insights.episodesNeeded) more episode\(insights.episodesNeeded == 1 ? "" : "s") to see patterns in your logs.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary.opacity(0.75))
                } else {
                    Text("Medication patterns will appear when you record medication details with an episode.")
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary.opacity(0.75))
                }
            } else if let message = viewModel.insightsErrorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Button("Retry medication patterns") {
                        Task { await viewModel.loadInsights() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44, alignment: .leading)
                }
            } else {
                ProgressView("Loading medication patterns…")
                    .font(.caption)
                    .tint(Theme.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var recordButton: some View {
        Button {
            Haptics.play(.light)
            showingEpisodeLog = true
        } label: {
            Label("Record Episode", systemImage: "plus.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Theme.accent)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
        }
        .buttonStyle(ScaleSpringButtonStyle())
        .accessibilityHint("Opens a form to record an episode")
    }

}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
            .environmentObject(UserProfileStore())
    }
}
