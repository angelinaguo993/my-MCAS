# Product

<!-- impeccable:product-schema 1 -->

## Platform

ios

## Users

People living with MCAS who want to track their own episodes, symptoms, triggers, and medications. Clinicians as direct users are not established.

## Product Purpose

myMCAS helps people living with MCAS record episodes and review symptom and trigger patterns over time, with information they can bring to care visits.

## Positioning

Unconfirmed. The app includes episode tracking, pattern summaries, educational material, and doctor-report export; the intended differentiator and success measure need user confirmation.

## Operating Context

The iOS app supports onboarding with profile, medication, symptom, trigger, and episode-frequency details; episode logging; calendar and history views; analytics and insights; discover content; settings; and doctor-report export. A Python backend provides episode, user, and insight APIs and analysis services. These capabilities are inferred from repository code and may not all be production-ready.

## Capabilities and Constraints

- Episode records include dates, symptoms, triggers, sleep, severity, medication, and notes.
- The app presents symptom and trigger frequencies and associations as personal tracking insights.
- The Discover section includes source-linked educational content and an explicit general-information-not-medical-advice disclaimer, with emergency guidance.
- Privacy, data retention, security, clinical validation, and intended medical-claim boundaries are unconfirmed. Do not infer guarantees or clinical efficacy from the implementation.
- The backend and app integration status is unconfirmed.

## Evidence on Hand

Repository evidence includes the iOS SwiftUI app under `ios/mcastracker`, episode and insight APIs under `backend/app`, analysis services, and source-linked educational content in `ios/mcastracker/models/discover-content.swift`. No customer, clinical, or performance evidence was established; do not fabricate it.

## Product Principles

- Make it practical to record an episode and its context.
- Present patterns as observations from a person’s logged data.
- Keep educational material sourced and distinguish it from medical advice.

