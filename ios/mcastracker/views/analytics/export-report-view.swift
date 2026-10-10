import SwiftUI
import PDFKit

enum ReportPeriod: String, CaseIterable, Identifiable {
    case thirtyDays, ninetyDays, allTime

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        case .allTime: return nil
        }
    }

    var label: String {
        switch self {
        case .thirtyDays: return "Last 30 days"
        case .ninetyDays: return "Last 90 days"
        case .allTime: return "All time"
        }
    }
}

@MainActor
final class ExportReportViewModel: ObservableObject {
    @Published var period: ReportPeriod = .ninetyDays
    @Published var includeAI = true
    @Published var isGenerating = false
    @Published var pdfURL: URL?
    @Published var errorMessage: String?
    @Published var notice: String?

    func generate(profile: UserProfile?) async {
        isGenerating = true
        errorMessage = nil
        notice = nil
        pdfURL = nil
        defer { isGenerating = false }

        do {
            let all = try await APIClient.shared.fetchAllEpisodes()
            let now = Date()

            var inPeriod = all
            if let days = period.days,
               let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) {
                inPeriod = all.filter { $0.date >= cutoff }
            }
            guard !inPeriod.isEmpty else {
                errorMessage = "You haven't logged any episodes in this time range yet."
                return
            }

            var aiResult: AIAnalysisResult? = nil
            if includeAI {
                let insights = try? await APIClient.shared.fetchInsights()
                aiResult = try? await AIAnalysisService().fetchAnalysis(for: inPeriod, insights: insights)
                if aiResult == nil {
                    notice = "The AI observations couldn't be generated, so this summary was created without them."
                }
            }

            let report = DoctorReport(
                episodes: inPeriod,
                allEpisodes: all,
                periodDays: period.days,
                periodLabel: period.label,
                generatedAt: now
            )
            guard let url = DoctorReportPDF.makePDF(report: report, profile: profile, ai: aiResult) else {
                errorMessage = "Couldn't create the PDF. Please try again."
                return
            }
            pdfURL = url
        } catch {
            if (error as? URLError)?.code == .cancelled { return }
            errorMessage = "Couldn't load your episodes. The server may be waking up, so try again in a moment."
        }
    }
}

struct ExportReportView: View {
    @EnvironmentObject private var profileStore: UserProfileStore
    @StateObject private var viewModel = ExportReportViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        introCard
                        optionsCard
                        if let error = viewModel.errorMessage {
                            messageCard(error, color: Theme.accent)
                        }
                        if let notice = viewModel.notice {
                            messageCard(notice, color: Theme.textPrimary.opacity(0.7))
                        }
                        actionArea
                        if let url = viewModel.pdfURL {
                            previewCard(url)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Doctor Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: Cards

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("A summary to bring to your appointment")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Text("Creates a PDF with your episode patterns, medication history, and a full log, organized for a clinician to skim. It describes what you recorded. It doesn't diagnose anything.")
                .font(.nSubheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var optionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Time range")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            ChipGrid(
                items: ReportPeriod.allCases,
                isSelected: { viewModel.period == $0 },
                label: { $0.label },
                onTap: { viewModel.period = $0 }
            )

            Toggle("Include AI observations", isOn: $viewModel.includeAI)
                .font(.nSubheadlineBold)
                .tint(Theme.primary)
            Text("Turning this on sends your logged episodes to an AI service to write a few observations. They're labeled \"unverified\" in the PDF.")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func messageCard(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.nSubheadline)
            .foregroundColor(color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
    }

    @ViewBuilder
    private var actionArea: some View {
        if viewModel.isGenerating {
            HStack(spacing: 12) {
                ProgressView()
                Text(viewModel.includeAI ? "Building your summary and AI notes…" : "Building your summary…")
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .cardStyle()
        } else {
            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.generate(profile: profileStore.profile) }
                } label: {
                    Text(viewModel.pdfURL == nil ? "Create PDF" : "Create again")
                        .font(.nHeadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Theme.accent, Color(hex: "F0709A")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: Theme.accent.opacity(0.35), radius: 12, x: 0, y: 6)
                }

                if let url = viewModel.pdfURL {
                    ShareLink(item: url) {
                        Label("Share or save PDF", systemImage: "square.and.arrow.up")
                            .font(.nHeadline)
                            .foregroundColor(Theme.accent)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Capsule().stroke(Theme.accent, lineWidth: 2))
                    }
                }
            }
        }
    }

    private func previewCard(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            PDFPreview(url: url)
                .frame(height: 460)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

/// Shows generated PDF inside app so user can check before sharing.
private struct PDFPreview: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.document = PDFDocument(url: url)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(url: url)
    }
}