---
target: the home page
total_score: 22
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 2
target_identity: "file:/Users/angelinaguo/my-MCAS/ios/mcastracker/views/home/dashboard-view.swift"
target_fingerprint: "sha256:732d6dea4c6026872d76e81f3c51e68dd8cb4d406d519509ca6ad5d475a54e68"
target_path: /Users/angelinaguo/my-MCAS/ios/mcastracker/views/home/dashboard-view.swift
timestamp: 2026-10-14T03-05-39Z
slug: ios-mcastracker-views-home-dashboard-view-swift
closed: true
---
Method: dual-agent (A: `/root/critique_assessment_a` · B: `/root/critique_assessment_b`)

### Design Health Score

| # | Heuristic | Score | Key issue |
|---|---|---:|---|
| 1 | Visibility of System Status | 2/4 | Loading, refresh, and error feedback exist; no visible update timestamp or clear partial-load status. |
| 2 | Match System / Real World | 2/4 | “% effective” reads like clinical efficacy, while the data represents personal logs. |
| 3 | User Control and Freedom | 3/4 | Refresh, settings, episode logging, and labeled tabs use familiar iOS patterns. |
| 4 | Consistency and Standards | 3/4 | Native tab navigation, sheets, and pull-to-refresh fit iOS conventions. |
| 5 | Error Prevention | 2/4 | Medication-effectiveness percentages lack denominator, time window, or qualification. |
| 6 | Recognition Rather Than Recall | 3/4 | Sections and tabs are labeled plainly; the metrics themselves lack context. |
| 7 | Flexibility and Efficiency | 2/4 | The main logging action comes after three summary sections; no quick repeat path is evident. |
| 8 | Aesthetic and Minimalist Design | 2/4 | The stacked cards compete for attention, and the fixed-height gradient hero’s role is unclear from source. |
| 9 | Error Recovery | 2/4 | Retry guidance exists, but the banner does not say which data failed or distinguish stale from partial content. |
| 10 | Help and Documentation | 1/4 | No contextual explanation for metrics or useful guidance in empty states. |
| **Total** |  | **22/40** | **Acceptable; meaningful improvements needed.** |

### Design Specificity Verdict

**Low; category-interchangeable.** The dashboard has MCAS-specific tracking data, but the four common tabs, stacked metric cards, gradient hero, and pink “Record Episode” button could belong to many wellness apps. The main opportunity is to make Home feel designed around the actual job: quickly recording an episode and reviewing personal patterns with appropriate context.

The deterministic detector reported **0 findings** for the dashboard source. It found no rules or locations, and there were no false positives to resolve. No visual overlay was produced.

### Overall Impression

The screen is calm and legible at the source level, and the main action is easy to understand once found. Its biggest opportunity is to put episode logging first and present metrics in careful, emotionally neutral language.

### What’s Working

- “Record Episode” is a clear, full-width action with plain language.
- Recency, total logs, and medications give a compact overview of relevant tracking information.
- Labeled native tabs and pull-to-refresh follow familiar iOS patterns.

### Priority Issues

1. **[P1] Medication “Effectiveness” can imply clinical efficacy.** The UI displays values like “72% effective” without a denominator or explanation. Users may treat personal tracking associations as treatment evidence. **Fix:** Label these as patterns in the user’s logged data, show how many episodes contributed and over what period, and avoid “effective” unless it is clinically supported. **Suggested command:** `$impeccable clarify`.
2. **[P1] The primary task is buried below three summary sections.** Users who open Home to log an episode must scroll past recency, total episodes, and medications. **Fix:** Put episode logging in the first viewport and make secondary summaries visually quieter. **Suggested command:** `$impeccable layout`.
3. **[P2] “Days Since Last Episode” creates a streak-like success measure.** For people with frequent symptoms, a large day count may feel discouraging or imply that fewer episodes are the measure of success. The em dash also gives no explanation when data is missing. **Fix:** Use a neutral “Last episode” date or relative time and explain the no-data state. **Suggested command:** `$impeccable clarify`.
4. **[P2] Empty medication and insight states do not guide the next step.** With no medications, the card says “No medications added yet” without a route to add them; insufficient insight data has no clear explanation here. **Fix:** Add an actionable path to medication settings and explain when personal patterns will appear. **Suggested command:** `$impeccable onboard`.
5. **[P2] The error banner obscures which data failed.** Dashboard stats and insights load separately, but one generic message can appear alongside partial or stale content. **Fix:** Identify the unavailable section and offer a section-specific retry while preserving visible data. **Suggested command:** `$impeccable harden`.

### Persona Red Flags

- **Alex, frequent tracker:** The logging action is below three summary panels, adding friction to the repeated task. No quick repeat path is apparent from this screen.
- **Sam, accessibility-dependent:** Text labels are present, but this source does not establish VoiceOver’s reading order or how the percentages are announced. The adaptive medication grid also merits Dynamic Type review.
- **Person with MCAS reviewing personal patterns:** “Days Since Last Episode” may frame an episode-free streak as the goal, and “effective” may sound medically validated.

### Minor Observations

- The hero background has a fixed height of 460 points; source alone cannot establish how it behaves across device sizes.
- Card corners use a 12-point radius while the theme defines a 16-point card radius.
- The screen has no visible “last updated” indicator.
- Assessment was source-based: no Simulator screenshots were available because `simctl` is not installed in this environment.

### Questions to Consider

- Should Home prioritize quickly logging an episode or reviewing patterns?
- Should the large day count remain if it can feel like a streak or success score?
- Which should we tackle first: metric language, first-screen hierarchy, or empty/error states?
