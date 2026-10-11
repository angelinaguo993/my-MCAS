import UIKit
import SwiftUI

/// puts text top -> bottom on us letter pg, starts new page when text will not fit on one pg
final class PDFReportWriter {
    private let context: UIGraphicsPDFRendererContext
    private let pageRect: CGRect
    private let margin: CGFloat = 48
    private let footerText: String
    private var y: CGFloat = 0
    private var pageNumber = 0

    private let accent = UIColor(Theme.accent)
    private let gray = UIColor(white: 0.40, alpha: 1)

    init(context: UIGraphicsPDFRendererContext, pageRect: CGRect, footerText: String) {
        self.context = context
        self.pageRect = pageRect
        self.footerText = footerText
        startPage()
    }

    // MARK: Fonts and styling

    /// use nunito if registed, otherwise font becomes default
    static func font(_ size: CGFloat, bold: Bool = false) -> UIFont {
        if let custom = UIFont(name: bold ? AppFont.bold : AppFont.regular, size: size) {
            return custom
        }
        return bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
    }

    private func styled(_ text: String,
                        size: CGFloat,
                        bold: Bool = false,
                        color: UIColor = .black,
                        hanging: CGFloat = 0) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        if hanging > 0 {
            paragraph.firstLineHeadIndent = 0
            paragraph.headIndent = hanging
        }
        return NSAttributedString(string: text, attributes: [
            .font: PDFReportWriter.font(size, bold: bold),
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ])
    }

    // MARK: Pages

    private var bottomLimit: CGFloat { pageRect.height - margin - 28 }

    private func startPage() {
        context.beginPage()
        pageNumber += 1
        y = margin

        let attributes: [NSAttributedString.Key: Any] = [
            .font: PDFReportWriter.font(8),
            .foregroundColor: gray
        ]
        let footer = "\(footerText)   •   Page \(pageNumber)"
        (footer as NSString).draw(
            in: CGRect(x: margin, y: pageRect.height - margin + 6, width: pageRect.width - margin * 2, height: 12),
            withAttributes: attributes
        )
    }

    /// Measures the block, starts a new page first if it won't fit, then draws it.
    private func draw(_ text: NSAttributedString,
                      spaceBefore: CGFloat = 0,
                      spaceAfter: CGFloat = 4,
                      keepWithNext: CGFloat = 0) {
        let width = pageRect.width - margin * 2
        let measured = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        let height = ceil(measured.height)

        if y + spaceBefore + height + keepWithNext > bottomLimit {
            startPage()
        } else {
            y += spaceBefore
        }
        text.draw(in: CGRect(x: margin, y: y, width: width, height: height))
        y += height + spaceAfter
    }

    // MARK: Building blocks

    func title(_ text: String) {
        draw(styled(text, size: 22, bold: true, color: accent), spaceAfter: 2)
    }

    func subtitle(_ text: String) {
        draw(styled(text, size: 9.5, color: gray), spaceAfter: 4)
    }

    func note(_ text: String) {
        draw(styled(text, size: 8.5, color: gray), spaceAfter: 6)
    }

    func heading(_ text: String) {
        draw(styled(text, size: 13, bold: true, color: accent), spaceBefore: 12, spaceAfter: 4, keepWithNext: 60)
    }

    func subheading(_ text: String) {
        draw(styled(text, size: 10, bold: true), spaceBefore: 4, spaceAfter: 2, keepWithNext: 30)
    }

    func labeled(_ label: String, _ value: String) {
        let line = NSMutableAttributedString()
        line.append(styled(label + ": ", size: 10, bold: true))
        line.append(styled(value, size: 10))
        draw(line, spaceAfter: 2)
    }

    func bullet(_ text: String) {
        draw(styled("•  " + text, size: 10, hanging: 12), spaceAfter: 2)
    }

    /// One episode: a bold title line followed by detail lines, kept together on one page.
    func entry(title: String, lines: [String]) {
        let block = NSMutableAttributedString(attributedString: styled(title, size: 10, bold: true))
        for line in lines {
            block.append(styled("\n" + line, size: 9, hanging: 10))
        }
        draw(block, spaceAfter: 8)
    }

    func rule() {
        if y + 10 > bottomLimit { startPage() }
        let path = UIBezierPath()
        path.move(to: CGPoint(x: margin, y: y))
        path.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        UIColor(white: 0.85, alpha: 1).setStroke()
        path.lineWidth = 0.5
        path.stroke()
        y += 10
    }
}

/// Turns a DoctorReport into a PDF file in the temp folder and returns its URL.
enum DoctorReportPDF {

    static func makePDF(report: DoctorReport, profile: UserProfile?, ai: AIAnalysisResult?) -> URL? {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)   // US Letter, in points

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "MCAS Symptom & Trigger Summary",
            kCGPDFContextCreator as String: "MCAS Tracker"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            let writer = PDFReportWriter(
                context: context,
                pageRect: pageRect,
                footerText: "MCAS Tracker  •  self-reported data  •  not a diagnosis or medical advice"
            )
            DoctorReportPDF.writeBody(writer, report: report, profile: profile, ai: ai)
        }

        let stamp = DateFormatter()
        stamp.dateFormat = "yyyy-MM-dd-HHmmss"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MCAS-Doctor-Summary-\(stamp.string(from: report.generatedAt)).pdf")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private static func oneDecimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private static func writeBody(_ w: PDFReportWriter,
                                  report: DoctorReport,
                                  profile: UserProfile?,
                                  ai: AIAnalysisResult?) {
        let dateText = report.generatedAt.formatted(date: .abbreviated, time: .omitted)

        w.title("MCAS Symptom & Trigger Summary")
        w.subtitle("Prepared for discussion with a clinician  •  Generated \(dateText)  •  \(report.periodLabel)")
        w.note("Self-reported data logged in the MCAS Tracker app. This summary shows patterns in what the patient recorded. It is not a diagnosis and not medical advice.")
        w.rule()

        // MARK: Patient

        if let p = profile {
            w.heading("Patient")
            if !p.name.isEmpty { w.labeled("Name", p.name) }

            var demographics: [String] = []
            if let age = p.age { demographics.append("\(age) years old") }
            if let sex = p.sex { demographics.append(sex.displayName) }
            if !demographics.isEmpty { w.labeled("Age / sex", demographics.joined(separator: ", ")) }

            let location = [p.city, p.state].filter { !$0.isEmpty }.joined(separator: ", ")
            if !location.isEmpty { w.labeled("Location", location) }

            if let frequency = p.typicalEpisodeFrequency {
                var text = frequency.displayName
                if frequency == .other, let extra = p.otherFrequencyDescription, !extra.isEmpty {
                    text = extra
                }
                w.labeled("Typical episode frequency (self-reported at setup)", text)
            }
            if !p.prescribedMedications.isEmpty {
                w.labeled("Prescribed medications (self-reported at setup)",
                          p.prescribedMedications.joined(separator: ", "))
            }
            if !p.previousTriggers.isEmpty {
                w.labeled("Triggers noted at setup", p.previousTriggers.map { $0.displayName }.joined(separator: ", "))
            }
            if !p.previousSymptoms.isEmpty {
                w.labeled("Symptoms noted at setup",
                          p.previousSymptoms.map { DoctorReport.shortName($0) }.joined(separator: ", "))
            }
        }

        // MARK: Overview

        w.heading("Overview")
        w.labeled("Episodes logged", "\(report.episodeCount)")
        if let average = report.averageSeverity, let low = report.minSeverity, let high = report.maxSeverity {
            w.labeled("Severity", "average \(oneDecimal(average)) / 10 (range \(low) to \(high))")
        }
        if let perWeek = report.episodesPerWeek {
            w.labeled("Frequency", "about \(oneDecimal(perWeek)) per week")
        }

        let direction: String
        if report.last14Days > report.prior14Days {
            direction = "more frequent recently"
        } else if report.last14Days < report.prior14Days {
            direction = "less frequent recently"
        } else {
            direction = "no change"
        }
        w.labeled("Recent trend",
                  "\(report.last14Days) episodes in the last 14 days vs. \(report.prior14Days) in the 14 days before (\(direction))")

        if let sleep = report.averageSleepHours {
            w.labeled("Sleep before episodes",
                      "average \(oneDecimal(sleep)) hours (\(report.episodesWithSleepData) of \(report.episodeCount) episodes have sleep recorded)")
        }
        if let compare = report.sleepComparison {
            w.bullet("After under 6 hours of sleep: average severity \(oneDecimal(compare.shortAverageSeverity)) / 10 across \(compare.shortEpisodes) episodes")
            w.bullet("After 7 or more hours: average severity \(oneDecimal(compare.longAverageSeverity)) / 10 across \(compare.longEpisodes) episodes")
        }

        // MARK: Triggers

        if !report.topTriggers.isEmpty {
            w.heading("Most frequent triggers")
            for trigger in report.topTriggers {
                w.bullet("\(trigger.name): present in \(trigger.count) of \(trigger.total) episodes (\(trigger.percent)%)")
            }
            w.note("Triggers are the factors the patient selected for each episode. Appearing alongside an episode does not prove cause.")
        }
        if !report.triggerPairs.isEmpty {
            w.subheading("Triggers that often occur together")
            for pair in report.triggerPairs {
                w.bullet("\(pair.name): together in \(pair.count) episodes")
            }
        }
        if !report.severityByTrigger.isEmpty {
            w.subheading("Average severity with vs. without each trigger")
            for item in report.severityByTrigger {
                w.bullet("\(item.name): \(oneDecimal(item.averageWith)) / 10 with it (\(item.episodesWith) episodes), \(oneDecimal(item.averageWithout)) / 10 without")
            }
        }

        // MARK: Symptoms

        if !report.symptomCategories.isEmpty {
            w.heading("Symptoms by body system")
            for symptom in report.symptomCategories {
                w.bullet("\(symptom.name): \(symptom.count) of \(symptom.total) episodes (\(symptom.percent)%)")
            }
            if !report.specificSymptoms.isEmpty {
                let list = report.specificSymptoms.map { "\($0.name) (\($0.count))" }.joined(separator: ", ")
                w.labeled("Most reported specific symptoms", list)
            }
        }

        // MARK: Medications

        if !report.medications.isEmpty {
            w.heading("Medications taken during episodes")
            for med in report.medications {
                let times = med.timesTaken == 1 ? "time" : "times"
                w.bullet("\(med.name): taken \(med.timesTaken) \(times), reported helpful \(med.timesHelped) (\(med.helpedPercent)%; 95% range \(med.lowerPercent) to \(med.upperPercent)%)")
            }
            w.note("Based only on the patient's own yes/no answer to \"did it help?\" for each episode. With few entries the range is wide. This does not replace clinical judgment about any medication.")
        }

        // MARK: AI observations (optional)

        if let ai = ai {
            w.heading("AI-generated observations (unverified)")
            w.note("Produced automatically by an AI model from the patient's logs. These can be wrong or oversimplified, so treat them as questions to explore with a clinician, not as findings.")
            let triggers = ai.triggersToAvoid.map { Trigger.from(rawValue: $0)?.displayName ?? $0 }
            writeAIList(w, title: "Possible triggers to discuss", items: triggers)
            writeAIList(w, title: "Medication observations", items: ai.medicationInsights)
            writeAIList(w, title: "Patterns in the patient's notes", items: ai.notesAnalysis)
        }

        // MARK: Episode log

        w.heading("Episode log (newest first)")
        for episode in report.episodes {
            var lines: [String] = []

            if !episode.triggers.isEmpty {
                lines.append("Triggers: " + episode.triggers.map { $0.displayName }.joined(separator: ", "))
            }
            if !episode.symptoms.isEmpty {
                let parts = episode.symptoms.map { entry -> String in
                    var text = "\(DoctorReport.shortName(entry.category)) \(entry.severity)/10"
                    let specifics = entry.specificSymptoms.filter { !$0.isEmpty }
                    if !specifics.isEmpty {
                        text += " (" + specifics.joined(separator: ", ") + ")"
                    }
                    return text
                }
                lines.append("Symptoms: " + parts.joined(separator: "; "))
            }
            if episode.medicationTaken {
                var text = episode.medicationNames.isEmpty ? "taken" : episode.medicationNames.joined(separator: ", ")
                if let helped = episode.medicationHelped {
                    text += helped ? " (helped)" : " (did not help)"
                }
                lines.append("Medication: " + text)
            }
            if let sleep = episode.sleepHours {
                lines.append("Sleep the night before: \(oneDecimal(sleep)) hours")
            }
            if let weather = episode.weatherSummary, !weather.isEmpty {
                lines.append("Weather when logged: " + weather)
            }
            if let notes = episode.notes, !notes.isEmpty {
                let trimmed = notes.count > 500 ? String(notes.prefix(500)) + "…" : notes
                lines.append("Notes: " + trimmed)
            }

            let when = episode.date.formatted(date: .abbreviated, time: .omitted)
            w.entry(title: "\(when)  —  severity \(episode.overallSeverity)/10", lines: lines)
        }

        w.rule()
        w.note("Confidence ranges are 95% Wilson score intervals. Percentages describe how often something appeared in the patient's own log. They are patterns to discuss, not proof of cause.")
    }

    private static func writeAIList(_ w: PDFReportWriter, title: String, items: [String]) {
        guard !items.isEmpty else { return }
        w.subheading(title)
        for item in items {
            w.bullet(item)
        }
    }
}