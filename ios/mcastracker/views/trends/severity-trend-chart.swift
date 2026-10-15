import SwiftUI
import Charts

struct SeverityTrendChart: View {
    let episodes: [Episode]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Severity Over Time")
                        .font(.nHeadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Each dot is one episode · severity is scored from 1 to 10")
                        .font(.nCaption)
                        .foregroundColor(Theme.textPrimary.opacity(0.7))
                }
                Spacer()
                Image(systemName: "waveform.path.ecg")
                    .font(.title3)
                    .foregroundColor(Theme.accent)
            }

            if episodes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.title2)
                        .foregroundColor(Theme.primary)
                    Text("No episodes in this period")
                        .font(.nSubheadlineBold)
                        .foregroundColor(Theme.textPrimary)
                    Text("Log an episode to see your severity trend here.")
                        .font(.nCaption)
                        .foregroundColor(Theme.textPrimary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 170)
            } else {
                let sortedEpisodes = episodes.sorted { $0.date < $1.date }

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 8, height: 8)
                            Text("Dot: one episode")
                        }
                        HStack(spacing: 7) {
                            Capsule()
                                .fill(Theme.primary.opacity(0.65))
                                .frame(width: 16, height: 2)
                            Text("Line: connects episodes by date")
                        }
                    }
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.75))

                    Chart {
                        ForEach(sortedEpisodes) { episode in
                            LineMark(
                                x: .value("Date", episode.date),
                                y: .value("Severity", episode.overallSeverity)
                            )
                            .foregroundStyle(Theme.primary.opacity(0.55))
                            .interpolationMethod(.linear)

                            PointMark(
                                x: .value("Date", episode.date),
                                y: .value("Severity", episode.overallSeverity)
                            )
                            .symbolSize(58)
                            .foregroundStyle(Theme.accent)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            AxisValueLabel(format: .dateTime.month().day())
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: Array(stride(from: 1, through: 10, by: 1))) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: value.as(Int.self).map { $0 == 1 || $0 == 5 || $0 == 10 ? 1 : 0.5 } ?? 0.5))
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartXAxisLabel("Episode date")
                    .chartYAxisLabel("Severity")
                    .chartYScale(domain: 1...10)
                    .chartPlotStyle { plot in
                        plot.background(Theme.primary.opacity(0.06))
                    }
                    .frame(height: 250)
                    .accessibilityLabel("Overall severity by episode date, on a scale from 1 to 10")

                    Text("The line connects logged episodes in date order; it does not represent values between them.")
                        .font(.nCaption)
                        .foregroundColor(Theme.textPrimary.opacity(0.7))

                    DisclosureGroup("Episode values") {
                        VStack(spacing: 0) {
                            ForEach(sortedEpisodes) { episode in
                                HStack {
                                    Text(episode.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.nSubheadline)
                                        .foregroundColor(Theme.textPrimary)
                                    Spacer()
                                    Text("Severity \(episode.overallSeverity) / 10")
                                        .font(.nSubheadlineBold)
                                        .foregroundColor(Theme.accent)
                                }
                                .padding(.vertical, 8)
                                .accessibilityElement(children: .combine)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .font(.nSubheadlineBold)
                    .tint(Theme.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .padding(.horizontal, 4)
    }
}
