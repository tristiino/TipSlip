import Foundation

struct DashboardSummary: Decodable {
    let totalTips: Double
    let grossTips: Double
    let netEarnings: Double
    let shiftsWorked: Int
    let avgTipsPerShift: Double
    let totalHoursWorked: Double
    let estimatedHourlyWage: Double
    let totalTipOut: Double
}

struct DailyEarning: Decodable, Identifiable {
    let date: String        // "yyyy-MM-dd" from LocalDate
    let totalTips: Double
    let cashTips: Double
    let creditTips: Double
    let netEarnings: Double
    let grossTips: Double

    // Identifiable conformance for Swift Charts
    var id: String { date }

    // Parsed date for chart axis labels
    var parsedDate: Date {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: date) ?? .now
    }
}
