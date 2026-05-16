import Foundation

enum DashboardPeriod: String, CaseIterable {
    case payPeriod     = "Pay Period"
    case lastPayPeriod = "Last Pay Period"
    case week          = "Week"
    case twoWeeks      = "2 Weeks"
    case month         = "Month"
    case ytd           = "YTD"
    
    // Return periods available when pay period is configured
    static var withPayPeriod: [DashboardPeriod] {
        [.payPeriod, .lastPayPeriod, .week, .month]
    }
    
    // Return periods available when pay period is NOT configured
    static var withoutPayPeriod: [DashboardPeriod] {
        [.week, .twoWeeks, .month, .ytd]
    }
}

@Observable
@MainActor
final class DashboardViewModel {

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

    // MARK: - Next pay period boundary (FR-032)

    var nextPayPeriodBoundary: Date? {
        guard let startDate = UserDefaults.standard.object(forKey: "payPeriodStartDate") as? Date,
              let length = UserDefaults.standard.object(forKey: "payPeriodLength") as? Int else {
            return nil
        }
        let today = Date()
        let cal = Calendar.current
        let daysSinceStart = cal.dateComponents([.day], from: startDate, to: today).day ?? 0
        let periodsElapsed = daysSinceStart / length
        let currentPeriodStart = cal.date(byAdding: .day, value: periodsElapsed * length, to: startDate) ?? today
        return cal.date(byAdding: .day, value: length, to: currentPeriodStart)
    }

    // MARK: - Pay Period Configuration
    var hasPayPeriodConfigured: Bool {
        // Check if user has configured a pay period
        // TODO: Replace with actual check from user settings/preferences
        UserDefaults.standard.object(forKey: "payPeriodConfigured") != nil
    }
    
    var availablePeriods: [DashboardPeriod] {
        hasPayPeriodConfigured ? DashboardPeriod.withPayPeriod : DashboardPeriod.withoutPayPeriod
    }

    // MARK: - Cache
    private var lastFetched: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes (FR-062)
    
    // MARK: - Init
    
    init() {
        // Default to pay period if configured, otherwise week
        if UserDefaults.standard.object(forKey: "payPeriodConfigured") != nil {
            self.period = .payPeriod
        } else {
            self.period = .week
        }
    }

    // MARK: - Actions

    func load(force: Bool = false) async {
        if !force, let last = lastFetched, Date().timeIntervalSince(last) < cacheDuration {
            return // cache still valid
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
        lastFetched = nil   // invalidate cache on period change
        await load()
    }
    
    // MARK: - Pay Period Configuration
    
    /// Configure the pay period settings
    /// - Parameters:
    ///   - startDate: The start date of the current pay period
    ///   - lengthInDays: The length of the pay period (e.g., 14 for bi-weekly, 7 for weekly)
    func configurePayPeriod(startDate: Date, lengthInDays: Int) {
        UserDefaults.standard.set(startDate, forKey: "payPeriodStartDate")
        UserDefaults.standard.set(lengthInDays, forKey: "payPeriodLength")
        UserDefaults.standard.set(true, forKey: "payPeriodConfigured")
        
        // Switch to pay period view if not already there
        if !availablePeriods.contains(.payPeriod) {
            period = .payPeriod
            Task { await load(force: true) }
        }
    }
    
    /// Remove pay period configuration
    func removePayPeriodConfiguration() {
        UserDefaults.standard.removeObject(forKey: "payPeriodStartDate")
        UserDefaults.standard.removeObject(forKey: "payPeriodLength")
        UserDefaults.standard.removeObject(forKey: "payPeriodConfigured")
        
        // Switch to week view if currently on pay period
        if period == .payPeriod || period == .lastPayPeriod {
            period = .week
            Task { await load(force: true) }
        }
    }

    // MARK: - Private

    private func dateRange(for period: DashboardPeriod) -> (String, String) {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let cal = Calendar.current

        let start: Date
        switch period {
        case .payPeriod:
            start = calculatePayPeriodStart(for: today, isLastPeriod: false)
        case .lastPayPeriod:
            start = calculatePayPeriodStart(for: today, isLastPeriod: true)
        case .week:
            start = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) ?? today
        case .twoWeeks:
            start = cal.date(byAdding: .day, value: -14, to: today) ?? today
        case .month:
            start = cal.date(from: cal.dateComponents([.year, .month], from: today)) ?? today
        case .ytd:
            var comps = cal.dateComponents([.year], from: today)
            comps.month = 1; comps.day = 1
            start = cal.date(from: comps) ?? today
        }

        return (f.string(from: start), f.string(from: today))
    }
    
    private func calculatePayPeriodStart(for date: Date, isLastPeriod: Bool) -> Date {
        guard let startDate = UserDefaults.standard.object(forKey: "payPeriodStartDate") as? Date,
              let length = UserDefaults.standard.object(forKey: "payPeriodLength") as? Int else {
            // Fallback to 14 days if not configured
            return Calendar.current.date(byAdding: .day, value: -14, to: date) ?? date
        }
        
        let cal = Calendar.current
        let daysSinceStart = cal.dateComponents([.day], from: startDate, to: date).day ?? 0
        let periodsElapsed = daysSinceStart / length
        
        // If last period, go back one more period
        let targetPeriod = isLastPeriod ? periodsElapsed - 1 : periodsElapsed
        
        let start = cal.date(byAdding: .day, value: targetPeriod * length, to: startDate) ?? date
        return start
    }
}
