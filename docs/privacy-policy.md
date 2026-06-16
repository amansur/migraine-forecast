# Privacy Policy — Migraine Forecast

**Last updated:** 15 June 2026

Migraine Forecast ("the app") is a local-first iOS, Android, macOS, and web application that helps people identify and forecast migraine triggers. This policy describes what data the app uses, how it is stored, and which third parties it communicates with on your behalf.

## Summary

- The app stores all your personal data **on your device only**.
- No personal data is sent to the app's developer or to any analytics service.
- The app talks directly to third-party APIs you choose to connect (Oura, Apple Health / Health Connect, weather providers). When it does, it sends only what is necessary to fetch the data you asked for.

## Data the app handles

The app reads, stores, or transmits the following categories, depending on which features you use:

| Category | Source | Where it goes |
|---|---|---|
| Migraine attacks, journal entries, baseline severity, custom triggers | You, via the app's Log screen | Local SQLite database on your device |
| Sleep duration & efficiency, heart-rate variability (HRV), menstrual cycle events | Apple Health (iOS/macOS) or Health Connect (Android), if you grant permission | Local SQLite database; read on demand, cached locally |
| Sleep score, lowest heart rate, restless periods, activity score, readiness score, temperature deviation, average heart rate, average HRV | Your Oura Ring account, if you connect it via OAuth | Local SQLite database; fetched from Oura's API and cached |
| Approximate location (latitude / longitude) | Your device's location services, if you grant permission, or a manually set location | Local storage; sent to weather APIs to retrieve forecasts |
| Weather and air quality data | Open-Meteo public API | Local SQLite database |

You can erase all locally stored data at any time from the app's Settings screen ("Erase all data").

## Third-party services

The app communicates with the following services only when their corresponding feature is in use:

- **Oura Ring API** (`api.ouraring.com`, `cloud.ouraring.com`) — used when you connect your Oura account. The app exchanges an authorization code for an access token and refresh token, both stored in secure storage on your device, and then requests sleep, activity, and readiness data. Oura's privacy policy applies to data handled by Oura: <https://ouraring.com/privacy-policy>.
- **Open-Meteo** (`api.open-meteo.com`, `archive-api.open-meteo.com`, `air-quality-api.open-meteo.com`) — used to fetch weather forecasts and air-quality data. The app sends the latitude and longitude (yours, or one you set manually) and a date range. Open-Meteo does not require an account; their privacy notice is at <https://open-meteo.com/en/privacy>.
- **Apple Health / Health Connect** — accessed locally via the operating system. No network traffic; data flows between the app and the OS health store.
- **Device location services** — used to determine your latitude and longitude for weather forecasts, via standard iOS / Android / macOS APIs. The coordinates are stored locally and sent to Open-Meteo as described above.

The app does not use third-party analytics, advertising, crash-reporting, or any service that profiles you across applications or devices.

## OAuth tokens

If you connect your Oura account, the access token, refresh token, and token expiry are stored in your device's secure storage (Keychain on iOS / macOS, Keystore on Android, `localStorage` on web). They are used solely to authenticate requests to Oura's API. Disconnecting Oura from the app's Settings clears these tokens immediately.

## Data retention

- On-device data persists until you erase it (Settings → "Erase all data") or uninstall the app.
- The app does not retain any data on its developer's servers — there are no such servers.
- If you uninstall the app, your device removes the local database according to platform conventions.

## Data sharing

The app does not share, sell, or transmit your personal data to any party other than the third-party services listed above, and only when those services are needed to provide the feature you requested.

## Children's privacy

The app is not intended for use by children under 13. The developer does not knowingly collect data from anyone in this age range.

## Changes to this policy

This policy may be updated as the app evolves. Material changes will be reflected by updating the "Last updated" date at the top of this document. The current version is always available at the URL where you found this document.

## Contact

For questions about this privacy policy, contact Claude.
