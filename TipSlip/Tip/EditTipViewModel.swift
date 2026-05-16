import Foundation
import SwiftUI

@Observable
@MainActor
final class EditTipViewModel {

    // MARK: - Identity
    let entryId: Int

    // MARK: - Form state
    var date: Date
    var shiftType: ShiftType
    var cashTipsText: String
    var creditTipsText: String
    var useStartEndTime: Bool
    var startTime: Date
    var endTime: Date
    var hoursWorkedText: String

    // MARK: - UI state
    var isSaving = false
    var isDeleting = false
    var errorMessage: String?
    var savedSuccessfully = false

    // MARK: - Computed
    var cashTips: Double  { Double(cashTipsText)  ?? 0 }
    var creditTips: Double { Double(creditTipsText) ?? 0 }
    var hoursWorked: Double { Double(hoursWorkedText) ?? 0 }

    // MARK: - Init from existing TipEntry

    init(entry: TipEntry) {
        self.entryId = entry.id

        // Parse date string "yyyy-MM-dd" → Date
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        self.date = df.date(from: entry.date) ?? .now

        // Shift type
        self.shiftType = ShiftType(rawValue: entry.shiftType ?? "Morning") ?? .morning

        // Tips
        self.cashTipsText  = entry.cashTips.map  { String(format: "%.2f", $0) } ?? ""
        self.creditTipsText = entry.creditTips.map { String(format: "%.2f", $0) } ?? ""

        // Hours / times
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"

        if let start = entry.startTime.flatMap({ tf.date(from: $0) }),
           let end   = entry.endTime.flatMap({ tf.date(from: $0) }) {
            self.useStartEndTime = true
            self.startTime = start
            self.endTime   = end
            self.hoursWorkedText = ""
        } else {
            self.useStartEndTime = false
            self.startTime = .now
            self.endTime   = .now
            self.hoursWorkedText = entry.hoursWorked.map { String(format: "%.1f", $0) } ?? ""
        }
    }

    // MARK: - Save (PUT)

    func save(using tipService: TipService) async {
        guard validate() else { return }

        isSaving = true
        errorMessage = nil

        do {
            let _ = try await tipService.update(id: entryId, request: buildRequest())
            savedSuccessfully = true
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isSaving = false
    }

    // MARK: - Delete

    func delete(using tipService: TipService) async throws {
        isDeleting = true
        try await tipService.delete(id: entryId)
        isDeleting = false
    }

    // MARK: - Private

    private func validate() -> Bool {
        if cashTips + creditTips <= 0 {
            errorMessage = "Enter at least some cash or credit tips."
            return false
        }
        if !useStartEndTime && hoursWorked <= 0 {
            errorMessage = "Enter hours worked, or use start and end times."
            return false
        }
        errorMessage = nil
        return true
    }

    private func buildRequest() -> TipEntryRequest {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"

        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"

        return TipEntryRequest(
            cashTips: cashTips,
            creditTips: creditTips,
            date: df.string(from: date),
            shiftType: shiftType.rawValue,
            startTime: useStartEndTime ? tf.string(from: startTime) : nil,
            endTime:   useStartEndTime ? tf.string(from: endTime)   : nil,
            hoursWorked: useStartEndTime ? nil : hoursWorked,
            notes: nil,
            tipOutRoleIds: [],
            tagIds: []
        )
    }
}
