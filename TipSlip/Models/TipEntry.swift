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

// MARK: - Response (what we get back from GET /api/tips/recent and POST /api/tips)

struct TipEntry: Decodable, Identifiable {
    let id: Int
    let amount: Double          // cashTips + creditTips (server-computed)
    let cashTips: Double?
    let creditTips: Double?
    let date: String            // "yyyy-MM-dd"
    let shiftType: String?
    let notes: String?
    let startTime: String?      // "HH:mm" or nil
    let endTime: String?        // "HH:mm" or nil
    let hoursWorked: Double?
    let tipOutRecords: [TipOutRecord]?

    // Convenience: total tip-out deducted across all roles
    var totalTipOut: Double {
        tipOutRecords?.reduce(0) { $0 + $1.finalAmount } ?? 0
    }
}

// MARK: - Tip-out record (nested inside TipEntry)

struct TipOutRecord: Decodable {
    let id: Int
    let roleId: Int
    let roleName: String
    let computedAmount: Double
    let finalAmount: Double     // actual deduction (may differ if overridden)
    let isOverridden: Bool
}

// MARK: - Helpers

extension TipEntry {
    /// Parses the "yyyy-MM-dd" date string into a Date for display.
    var parsedDate: Date {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: date) ?? .now
    }
}

// MARK: - Shift type

enum ShiftType: String, CaseIterable {
    case morning = "Morning"
    case evening = "Evening"
    case night   = "Night"

    var label: String { rawValue }
}
