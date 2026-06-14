# Migraine Forecast — Evidence-Backed Design Spec v2

**Status:** Draft for review
**Date:** 2026-06-14

## Overview

Migraine Weatherr is a Flutter application designed for migraine sufferers that predicts daily migraine risk using an enhanced rules-based scoring engine strictly derived from the latest peer-reviewed clinical research. The application leverages a local-first architecture (no backend, no user accounts for privacy) and correlates daily environmental and physiological metrics against a user's logged triggers and migraine attacks.

## Core Value Proposition

- Produce a highly evidence-backed, transparent daily migraine risk score (0–100, segmented into low/moderate/high bands) from automatically-gathered data on the user's device.
- Utilize a **Convergent Sensing** approach, fusing continuous biometric data (like overnight HRV and electrodermal activity) with environmental exposures (barometric pressure, AQI) to evaluate holistic allostatic load, rather than treating triggers in isolation.
- Empower patients with a personalized trigger journal that retroactively maps physiological and atmospheric correlations.
- Ensure 100% on-device data processing for health privacy.

## Evidence-Backed Triggers

Our trigger engine is heavily weighted based on recent literature, incorporating findings from environmental, climate, and biometric studies.

### Atmospheric and Weather Triggers (via Open-Meteo)

1. **Barometric Pressure Fluctuations**
   - **Evidence:** Systematic reviews and case-time series analyses show rapid drops and fluctuations in barometric pressure are linked to increased migraine frequency. (e.g., PMID: 41245912, PMID: 42109518).
   - **Signal:** 24h pressure drop $\ge$ 5 hPa, or rapid intra-day fluctuations.
   - **Lead Time:** Same day to 48 hours.
2. **Temperature Drops & Cold/Wet Extremes**
   - **Evidence:** Colder winter temperatures and high humidity have been independently linked to migraine frequency and cold-wet allodynia via TRPM8 receptors (PMID: 42109518, PMID: 35670097, PMID: 40842130, PMID: 26018293).
   - **Signal:** Sharp drop in ambient temperature ($\ge$ 5°C) combined with relative humidity $>$ 60%.
3. **Air Pollution & Particulate Matter**
   - **Evidence:** Higher nitrogen dioxide ($NO_2$), ozone ($O_3$), and on warm days $PM_{2.5}$ significantly increase the odds of a migraine attack onset (PMID: 42109518, PMID: 25938912, PMID: 41302667).
   - **Signal:** Air Quality Index parameters exceeding WHO standard limits (e.g., $PM_{2.5} > 35 \mu g/m^3$, elevated $O_3$ and $NO_2$).

### Biometric and Physiological Triggers (via Wearables & Health Connect / Apple Health)

4. **Continuous Autonomic Nervous System (ANS) Tone**
   - **Evidence:** Nocturnal pulse rate variability (HRV) and phasic Electrodermal Activity (EDA) are predictive of next-day headache and indicative of nociplastic pain mechanisms (PMCID: PMC13206900). Trials (e.g., NCT02910921, NCT05454319) show active utilization of these metrics for predicting and preempting attacks.
   - **Signal:** $>20\%$ drop in RMSSD from individual 14-day rolling baseline, or elevated nocturnal EDA.
5. **Sleep Deficit / Disturbance**
   - **Evidence:** Fragmented or insufficient sleep are primary lifestyle triggers.
   - **Signal:** $<$ 6h total sleep, sleep efficiency $<$ 85%, or schedule shifts $>2h$ vs a 7-day median.
6. **Menstrual Phase (Hormonal Drop)**
   - **Evidence:** Estrogen drops are a strong, predictable trigger for menstrual migraines.
   - **Signal:** Cycle day -2 to +3 relative to menses onset.
7. **Somatic Symptoms & Vagal Tone**
   - **Evidence:** Lower resting vagally-mediated HRV is linked to increased somatic symptom severity, particularly when psychological stressors (e.g., attachment anxiety/avoidance) are present (PMCID: PMC12731400).

### Self-Logged Triggers

7. **Alcohol & Caffeine Fluctuations**
   - **Evidence:** Introduction of alcohol or rapid withdrawal of caffeine.
   - **Signal:** Logged use vs. baseline.
8. **Stress and Hydration**
   - **Evidence:** Psychological let-down and dehydration are strong catalysts when combined with environmental factors.

## Architecture & Data Flow

Maintains a three-layer clean architecture:
1. **Data Source Layer (Adapters)**:
   - `WeatherSource` (Open-Meteo) for localized weather and AQI.
   - `HealthSource` for HRV, Sleep, Menstrual flow, and continuous EDA/HRV from wearables.
   - `JournalSource` (Drift/SQLite) for manual logs.
2. **Domain Core Layer**:
   - Pure Dart environment. Contains the `ConvergentRiskEngine`, `TriggerModules`, and `CorrelationAnalyzer`. Evaluates allostatic load by layering environmental signals over the user's physiological baseline threshold.
3. **App/UI Layer**:
   - Riverpod for state management. Provides clear risk visualizations (arc/gauge, numeric, or intuitive weather icons) tailored to the "Calm/Wellness" design aesthetic.

## Personalization: The User-in-the-Loop Model

Given individual heterogeneity to weather (PMID: 40842130), the algorithm does not rely on a static population model. 
- **Baseline:** Day-1 triggers are manually flagged during onboarding.
- **Correlation Analysis:** After $\ge$ 10 logged attacks, the system runs local conditional probability analyses on past data.
- **Suggestion Engine:** If a specific trigger (e.g., barometric pressure drops) is highly correlated with an attack (e.g., lower bound of the 90% Confidence Interval shows significant lift over baseline), the app prompts the user to *increase the trigger's weight* in their personal settings.
- **Signal Validation (Project Hermes Model):** To dramatically reduce false positive alerts from the Convergent Engine, the app implements a post-prediction validation layer. When a high-risk threshold is breached, the app prompts the user with targeted contextual queries (e.g., "Are you experiencing mild neck stiffness?") to confirm the presence of subtle prodrome symptoms before issuing a definitive alert (arXiv:2602.18643).

## Future Integration: Digital Therapeutics

- **Biofeedback Intervention:** Implement localized biofeedback protocols (as evaluated in NCT05454319) to provide real-time breathing/relaxation exercises when the app detects an impending risk state (low HRV + environmental trigger), effectively shifting from risk prediction to active preemptive treatment.
- Using localized ARIMAX modeling for patient-specific climate forecasting (PMID: 41914055).
