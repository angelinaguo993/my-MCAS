import SwiftUI
import Charts

struct SeverityTrendChart: View {
    let episodes: [Episode]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Severity Over Time")
                .font(.nHeadline)
            
            Chart {
                ForEach(episodes) { episode in
                    LineMark(
                        x: .value("Date", episode.date, unit: .day),
                        y: .value("Severity", episode.overallSeverity)
                    )
                    .symbol(Circle())
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.accent)
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYScale(domain: 0...10)
            .frame(height: 250)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
