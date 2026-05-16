import Foundation

// MARK: - Request (what we send to POST /api/tips)

struct TipEntryRequest: Encodable {
    let cashTips: Double
    let creditTips: Double
    let date: String        // "yyyy-MM-dd" — backend expects LocalDate
    let shiftType: String   // "Morning" | "Evening" | "Night"
    let startTime: String?  // "HH:mm" — optional
    let endTime: String?    // "HH:mm" — optional
    let hoursWorked: Double?
    let notes: String?
    let tipOutRoleIds: [Int]
    let tagIds: [Int]
}

// MARK: - Response (what we get back from the server)

struct TipEntry: Decodable {
    let id: Int
    let amount: Double
    let cashTips: Double?
    let creditTips: Double?
    let date: String
    let shiftType: String?
    let notes: String?
    let startTime: String?
    let endTime: String?
    let hoursWorked: Double?
    let totalTipOut: Double
    let netTips: Double
}

// MARK: - Shift type

enum ShiftType: String, CaseIterable {
    case morning = "Morning"
    case evening = "Evening"
    case night   = "Night"

    var label: String { rawValue }
}
