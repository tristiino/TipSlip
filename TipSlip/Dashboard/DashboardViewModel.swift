import Foundation

enum DashboardPeriod: String, CaseIterable {
    case payPeriod     = "Pay Period"
    case lastPayPeriod = "Last Pay Period"
    case week          = "Week"
    case twoWeeks      = "2 Weeks"
    case month         = "Month"
    case ytd           = "YTD"

    static var withPayPeriod: [DashboardPeriod] {
        [.payPeriod, .lastPayPeriod, .week, .month]
    }

    static var withoutPayPeriod: [DashboardPeriod] {
        [.week, .twoWeeks, .month, .ytd]
    }
}

@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Dependencies
    private let settingsService: SettingsService

    // MARK: - State
    var period: DashboardPeriod
    var summary: DashboardSummary?
    var dailyEarnings: [DailyEarning] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Derived totals (FR-031)

    var totalCashTips: Double {
        dailyEarnings.reduce(0) { $0 + $1.cashTips }
    }

    var totalCreditTips: Double {
        dailyEarnings.reduce(0) { $0 + $1.creditTips }
    }

    // MARK: - Pay period config (reads from SettingsService)

    var hasPayPeriodConfigured: Bool {
        settingsService.settings?.payPeriodStartAnchor != nil
    }

    var availablePeriods: [DashboardPeriod] {
        hasPayPeriodConfigured ? DashboardPeriod.withPayPeriod : DashboardPeriod.withoutPayPeriod
    }

    // MARK: - Next pay period boundary (FR-032)

    var nextPayPeriodBoundary: Date? {
        guard let settings = settingsService.settings,
              let anchorStr = settings.payPeriodStartAnchor else { return nil }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let anchorDate = f.date(from: anchorStr) else { return nil }

        let length = settings.payPeriodLengthDays
        let today  = Date()
        let cal    = Calendar.current
        let daysSinceStart  = cal.dateComponents([.day], from: anchorDate, to: today).day ?? 0
        let periodsElapsed  = daysSinceStart / length
        let currentPeriodStart = cal.date(byAdding: .day, value: periodsElapsed * length, to: anchorDate) ?? today
        return cal.date(byAdding: .day, value: length, to: currentPeriodStart)
    }

    // MARK: - Cache
    private var lastFetched: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes (FR-062)

    // MARK: - Init

    init(settingsService: SettingsService) {
        self.settingsService = settingsService
        // Default to pay period if anchor is configured, otherwise week
        if settingsService.settings?.payPeriodStartAnchor != nil {
            self.period = .payPeriod
        } else {
            self.period = .week
        }
    }

    // MARK: - Actions

    func load(force: Bool = false) async {
        if !force, let last = lastFetched, Date().timeIntervalSince(last) < cacheDuration {
            return
        }

        isLoading = true
        errorMessage = nil

        let (start, end) = dateRange(for: period)
        let dateParam = "startDate=\(start)&endDate=\(end)"

        async let summaryResult: DashboardSummary = NetworkClient.get(
            "/tips/summary?\(dateParam)"
        )
        async let earningsResult: [DailyEarning] = NetworkClient.get(
            "/tips/earnings/daily?\(dateParam)&groupBy=day"
        )

        do {
            let (s, e) = try await (summaryResult, earningsResult)
            summary = s
            dailyEarnings = e
            lastFetched = .now
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Could not load dashboard data."
        }

        isLoading = false
    }

    func changePeriod(to newPeriod: DashboardPeriod) async {
        period = newPeriod
        lastFetched = nil
        await load()
    }

    // MARK: - Private

    private func dateRange(for period: DashboardPeriod) -> (String, String) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let cal   = Calendar.current

        switch period {
        case .payPeriod:
            let start = calculatePayPeriodStart(for: today, isLastPeriod: false)
            return (f.string(from: start), f.string(from: today))

        case .lastPayPeriod:
            // Start = beginning of previous period
            // End   = day before current period starts (not today)
            let start        = calculatePayPeriodStart(for: today, isLastPeriod: true)
            let currentStart = calculatePayPeriodStart(for: today, isLastPeriod: false)
            let end          = cal.date(byAdding: .day, value: -1, to: currentStart) ?? today
            return (f.string(from: start), f.string(from: end))

        case .week:
            let start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
            return (f.string(from: start), f.string(from: today))

        case .twoWeeks:
            let start = cal.date(byAdding: .day, value: -14, to: today) ?? today
            return (f.string(from: start), f.string(from: today))

        case .month:
            let start = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
            return (f.string(from: start), f.string(from: today))

        case .ytd:
            var comps = cal.dateComponents([.year], from: today)
            comps.month = 1; comps.day = 1
            let start = cal.date(from: comps) ?? today
            return (f.string(from: start), f.string(from: today))
        }
    }

    private func calculatePayPeriodStart(for date: Date, isLastPeriod: Bool) -> Date {
        guard let settings = settingsService.settings,
              let anchorStr = settings.payPeriodStartAnchor else {
            return Calendar.current.date(byAdding: .day, value: -14, to: date) ?? date
        }

        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let anchorDate = f.date(from: anchorStr) else {
            return Calendar.current.date(byAdding: .day, value: -14, to: date) ?? date
        }

        let length = settings.payPeriodLengthDays
        let cal    = Calendar.current
        let daysSinceStart = cal.dateComponents([.day], from: anchorDate, to: date).day ?? 0
        let periodsElapsed = daysSinceStart / length
        let targetPeriod   = isLastPeriod ? periodsElapsed - 1 : periodsElapsed
        return cal.date(byAdding: .day, value: targetPeriod * length, to: anchorDate) ?? date
    }
}
