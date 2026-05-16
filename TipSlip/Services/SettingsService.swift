import Foundation

@Observable
@MainActor
final class SettingsService {

    // MARK: - State
    var settings: UserSettings?
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Cache
    private var lastFetched: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes

    // MARK: - Load

    func load(force: Bool = false) async {
        if !force, let last = lastFetched, Date().timeIntervalSince(last) < cacheDuration {
            return // cache still valid
        }

        isLoading = true
        errorMessage = nil

        do {
            settings = try await NetworkClient.get("/settings")
            lastFetched = .now
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load settings."
        }

        isLoading = false
    }

    // MARK: - Save

    func save() async {
        guard let current = settings else { return }

        isLoading = true
        errorMessage = nil

        do {
            settings = try await NetworkClient.put("/settings", body: current)
            lastFetched = .now
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not save settings."
        }

        isLoading = false
    }

    // MARK: - Helpers

    /// Parsed morningStart as a Date (time-only, today's date)
    var morningStartDate: Date {
        parseTime(settings?.morningStart) ?? defaultTime(hour: 6)
    }

    /// Parsed eveningStart as a Date (time-only, today's date)
    var eveningStartDate: Date {
        parseTime(settings?.eveningStart) ?? defaultTime(hour: 14)
    }

    /// Parsed nightStart as a Date (time-only, today's date)
    var nightStartDate: Date {
        parseTime(settings?.nightStart) ?? defaultTime(hour: 21)
    }

    private func parseTime(_ string: String?) -> Date? {
        guard let string else { return nil }
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = .current
        guard let parsed = f.date(from: string) else { return nil }
        // Anchor to today so comparisons work
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.hour, .minute, .second], from: parsed)
        comps.year  = cal.component(.year,  from: now)
        comps.month = cal.component(.month, from: now)
        comps.day   = cal.component(.day,   from: now)
        return cal.date(from: comps)
    }

    private func defaultTime(hour: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour, minute: 0, second: 0, of: Date()
        ) ?? Date()
    }
}
