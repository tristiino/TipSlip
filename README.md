# TipSlip — iOS

TipSlip is a native iPhone app for service-industry workers — servers, bartenders, and hospitality staff — to log shifts, record tips, track earnings, and manage tip-outs. Built with Swift and SwiftUI, it delivers a fast, intuitive experience designed specifically for how tipped employees actually work.

---

## Background

TipSlip began as a web application at [tiptrackerapp.org](https://tiptrackerapp.org), built with Angular on the frontend and Spring Boot on the backend. The iOS app is a ground-up native rewrite — not a port of the web UI — designed to take full advantage of the iPhone platform while reusing the same backend API. A user can sign in on the web or on iOS and see the same account, shifts, and data on both.

The web domain will migrate from `tiptrackerapp.org` to `tipslip.app` at production launch.

---

## What the app does

- **Log shifts** — record hours worked, hourly rate, and shift date
- **Track tips** — enter cash and card tips per shift
- **Earnings dashboard** — view totals by day, week, pay period, or custom range
- **Tip-out management** — define roles (barback, host, etc.) and calculate tip-share distributions
- **Settings** — configure pay period, tax rate, and tip-out percentages
- **Cross-platform sync** — all data lives on the shared backend; web and iOS stay in sync automatically

---

## Tech stack

| Layer | Technology |
|---|---|
| Platform | iOS 17+ (iPhone) |
| Language | Swift 5.9+ |
| UI framework | SwiftUI |
| Architecture | MVVM with `@Observable` |
| Networking | `URLSession` + `async/await` |
| Auth | JWT — stored in Keychain |
| Backend | Spring Boot 3.5.3 REST API |
| Database | MySQL 8.0 (server-side; iOS never touches it directly) |
| CI | GitHub Actions |

---

## Architecture

The app is structured around MVVM using Apple's `@Observable` macro introduced in iOS 17:

```
SwiftUI Views
    └── @Observable ViewModels
            └── Services  (auth, shifts, tips)
                    ├── Networking  — URLSession / async-await
                    └── Persistence — Keychain (JWT) + response cache
                                          └── Spring Boot REST API
```

---

## Project structure

```
TipSlip/
├── TipSlip/
│   ├── TipSlipApp.swift     ← app entry point
│   ├── Views/               ← SwiftUI screens
│   ├── ViewModels/          ← @Observable business logic
│   ├── Services/            ← auth, shift, and tip services
│   ├── Networking/          ← URLSession client and endpoint definitions
│   ├── Models/              ← Swift data models mirroring backend DTOs
│   └── Persistence/         ← Keychain wrapper and response cache
├── TipSlipTests/
├── TipSlipUITests/
└── TipSlip.xcodeproj/
```

---

## Authentication

Authentication uses the same JWT-based flow as the web app:

1. `POST /api/auth/login` returns a signed JWT.
2. The token is stored securely in the iOS Keychain — never `UserDefaults`.
3. All authenticated requests include `Authorization: Bearer <token>`.
4. A `401` response clears the token and redirects to the sign-in screen.

---

## Getting started

**Requirements:** macOS 14 (Sonoma) or later, Xcode 16+, Apple Developer Program membership.

```bash
git clone <repo-url>
open TipSlip.xcodeproj
```

Select an iOS 17+ Simulator or a connected device and press `⌘R`.

---

## CI

A GitHub Actions workflow builds the project on every push and pull request to `main`, targeting the iOS Simulator (no code signing required). See [`.github/workflows/ios.yml`](.github/workflows/ios.yml).

---

## Owner

Tristan Barnett — [tristanwbarnett@gmail.com](mailto:tristanwbarnett@gmail.com)
