import Foundation

/// Everything the doctor PDF reports
struct DoctorReport {

    struct Count: Identifiable {
        let name: String
        let count: Int
        let total: Int
        var id: String { name }
        var percent: Int {
            total == 0 ? 0 : Int((Double(count) / Double(total) * 100).rounded())
        }
    }

    struct MedicationStat: Identifiable {
        let name: String
        let timesTaken: Int
        let timesHelped: Int
        let lowerPercent: Int
        let upperPercent: Int
        var id: String { name }
        var helpedPercent: Int {
            timesTaken == 0 ? 0 : Int((Double(timesHelped) / Double(timesTaken) * 100).rounded())
        }
    }

    struct SeverityComparison: Identifiable {
        let name: String
        let averageWith: Double
        let averageWithout: Double
        let episodesWith: Int
        var id: String { name }
    }

    struct SleepComparison {
        let shortEpisodes: Int             // slept under 6 hours
        let shortAverageSeverity: Double
        let longEpisodes: Int             // slept 7+ hours
        let longAverageSeverity: Double
    }

    let periodLabel: String
    let generatedAt: Date
    let episodes: [Episode]               // newest first

    let episodeCount: Int
    let averageSeverity: Double?
    let minSeverity: Int?
    let maxSeverity: Int?
    let episodesPerWeek: Double?
    let last14Days: Int
    let prior14Days: Int
    let averageSleepHours: Double?
    let episodesWithSleepData: Int
    let sleepComparison: SleepComparison?

    let topTriggers: [Count]
    let triggerPairs: [Count]
    let severityByTrigger: [SeverityComparison]
    let symptomCategories: [Count]
    let specificSymptoms: [Count]
    let medications: [MedicationStat]

    init(episodes inPeriod: [Episode],
         allEpisodes: [Episode],
         periodDays: Int?,
         periodLabel: String,
         generatedAt: Date = Date()) {

        let sorted = inPeriod.sorted { $0.date > $1.date }
        let total = sorted.count
        let calendar = Calendar.current

        // MARK: Overview

        let severities = sorted.map { $0.overallSeverity }
        let avgSeverity: Double? = severities.isEmpty ? nil : Self.average(severities)

        var perWeek: Double? = nil
        if total > 0 {
            let days: Double
            if let periodDays = periodDays {
                days = Double(periodDays)
            } else {
                let earliest = sorted.last?.date ?? generatedAt
                let span = calendar.dateComponents([.day], from: earliest, to: generatedAt).day ?? 7
                days = Double(max(span, 7))
            }
            perWeek = Double(total) / (days / 7.0)
        }

        let day14 = calendar.date(byAdding: .day, value: -14, to: generatedAt) ?? generatedAt
        let day28 = calendar.date(byAdding: .day, value: -28, to: generatedAt) ?? generatedAt
        let recent = allEpisodes.filter { $0.date >= day14 }.count
        let prior = allEpisodes.filter { $0.date >= day28 && $0.date < day14 }.count

        // MARK: Sleep

        let sleepValues = sorted.compactMap { $0.sleepHours }
        let avgSleep: Double? = sleepValues.isEmpty
            ? nil
            : sleepValues.reduce(0, +) / Double(sleepValues.count)
        let shortSleep = sorted.filter { ($0.sleepHours ?? 99) < 6 }
        let longSleep = sorted.filter { ($0.sleepHours ?? -1) >= 7 }
        var sleepCompare: SleepComparison? = nil
        if shortSleep.count >= 2 && longSleep.count >= 2 {
            sleepCompare = SleepComparison(
                shortEpisodes: shortSleep.count,
                shortAverageSeverity: Self.average(shortSleep.map { $0.overallSeverity }),
                longEpisodes: longSleep.count,
                longAverageSeverity: Self.average(longSleep.map { $0.overallSeverity })
            )
        }

        // MARK: Triggers

        var triggerCounts: [Trigger: Int] = [:]
        var pairCounts: [String: Int] = [:]
        for ep in sorted {
            let present = Set(ep.triggers)
            for t in present {
                triggerCounts[t, default: 0] += 1
            }
            let ordered = present.sorted { $0.rawValue < $1.rawValue }
            if ordered.count >= 2 {
                for i in 0..<ordered.count {
                    for j in (i + 1)..<ordered.count {
                        let key = "\(ordered[i].displayName) + \(ordered[j].displayName)"
                        pairCounts[key, default: 0] += 1
                    }
                }
            }
        }

        var triggerNameCounts: [String: Int] = [:]
        for (trigger, count) in triggerCounts {
            triggerNameCounts[trigger.displayName] = count
        }

        // Average severity with vs. without each trigger (needs 2+ episodes with it).
        var comparisons: [SeverityComparison] = []
        for (trigger, count) in triggerCounts where count >= 2 {
            let withTrigger = sorted.filter { $0.triggers.contains(trigger) }.map { $0.overallSeverity }
            let withoutTrigger = sorted.filter { !$0.triggers.contains(trigger) }.map { $0.overallSeverity }
            if withoutTrigger.isEmpty { continue }
            comparisons.append(SeverityComparison(
                name: trigger.displayName,
                averageWith: Self.average(withTrigger),
                averageWithout: Self.average(withoutTrigger),
                episodesWith: withTrigger.count
            ))
        }
        comparisons.sort {
            ($0.averageWith - $0.averageWithout) > ($1.averageWith - $1.averageWithout)
        }

        // MARK: Symptoms

        var categoryCounts: [SymptomCategory: Int] = [:]
        var specificCounts: [String: Int] = [:]
        for ep in sorted {
            var categories = Set<SymptomCategory>()
            var specifics = Set<String>()
            for entry in ep.symptoms {
                categories.insert(entry.category)
                for s in entry.specificSymptoms where !s.isEmpty {
                    specifics.insert(s)
                }
            }
            for c in categories { categoryCounts[c, default: 0] += 1 }
            for s in specifics { specificCounts[s, default: 0] += 1 }
        }
        var categoryNameCounts: [String: Int] = [:]
        for (category, count) in categoryCounts {
            categoryNameCounts[Self.shortName(category)] = count
        }

        // MARK: Medications

        var taken: [String: Int] = [:]
        var helped: [String: Int] = [:]
        for ep in sorted where ep.medicationTaken {
            for name in Set(ep.medicationNames) where !name.isEmpty {
                taken[name, default: 0] += 1
                if ep.medicationHelped == true {
                    helped[name, default: 0] += 1
                }
            }
        }
        var medStats: [MedicationStat] = []
        for (name, timesTaken) in taken {
            let timesHelped = helped[name] ?? 0
            let interval = Self.wilson(successes: timesHelped, total: timesTaken)
            medStats.append(MedicationStat(
                name: name,
                timesTaken: timesTaken,
                timesHelped: timesHelped,
                lowerPercent: Int((interval.lower * 100).rounded()),
                upperPercent: Int((interval.upper * 100).rounded())
            ))
        }
        medStats.sort {
            $0.timesTaken != $1.timesTaken ? $0.timesTaken > $1.timesTaken : $0.name < $1.name
        }

        // MARK: Assign everything once

        self.periodLabel = periodLabel
        self.generatedAt = generatedAt
        self.episodes = sorted
        self.episodeCount = total
        self.averageSeverity = avgSeverity
        self.minSeverity = severities.min()
        self.maxSeverity = severities.max()
        self.episodesPerWeek = perWeek
        self.last14Days = recent
        self.prior14Days = prior
        self.averageSleepHours = avgSleep
        self.episodesWithSleepData = sleepValues.count
        self.sleepComparison = sleepCompare
        self.topTriggers = Self.makeCounts(triggerNameCounts, total: total, limit: 6)
        self.triggerPairs = Self.makeCounts(pairCounts, total: total, limit: 4, minimum: 2)
        self.severityByTrigger = Array(comparisons.prefix(4))
        self.symptomCategories = Self.makeCounts(categoryNameCounts, total: total, limit: 7)
        self.specificSymptoms = Self.makeCounts(specificCounts, total: total, limit: 6)
        self.medications = medStats
    }

    // MARK: Helpers

    /// "Skin (hives, flushing, itching)" -> "Skin"
    static func shortName(_ category: SymptomCategory) -> String {
        category.displayName.components(separatedBy: " (").first ?? category.displayName
    }

    private static func average(_ values: [Int]) -> Double {
        values.isEmpty ? 0 : Double(values.reduce(0, +)) / Double(values.count)
    }

    private static func makeCounts(_ dict: [String: Int], total: Int, limit: Int, minimum: Int = 1) -> [Count] {
        let sortedCounts = dict
            .filter { $0.value >= minimum }
            .map { Count(name: $0.key, count: $0.value, total: total) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.name < $1.name }
        return Array(sortedCounts.prefix(limit))
    }

    /// Wilson 95% score interval, the same math the backend's /insights uses.
    /// Gives an honest range for small samples instead of a falsely precise percentage.
    static func wilson(successes: Int, total: Int) -> (lower: Double, upper: Double) {
        guard total > 0 else { return (0, 0) }
        let z = 1.96
        let n = Double(total)
        let p = Double(successes) / n
        let denominator = 1 + (z * z) / n
        let center = (p + (z * z) / (2 * n)) / denominator
        let margin = z * (p * (1 - p) / n + (z * z) / (4 * n * n)).squareRoot() / denominator
        return (max(0, center - margin), min(1, center + margin))
    }
}