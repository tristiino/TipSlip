import Foundation
import SwiftUI

@Observable
@MainActor
final class AddTipViewModel {

    // MARK: - Form state
    var date: Date = .now
    var shiftType: ShiftType = .morning
    var cashTipsText: String = ""
    var creditTipsText: String = ""
    var useStartEndTime: Bool = false
    var startTime: Date = .now
    var endTime: Date = .now
    var hoursWorkedText: String = ""

    // MARK: - UI state
    var isLoading: Bool = false
    var errorMessage: String?
    var savedSuccessfully: Bool = false

    // MARK: - Computed
    var cashTips: Double  { Double(cashTipsText)  ?? 0 }
    var creditTips: Double { Double(creditTipsText) ?? 0 }
    var hoursWorked: Double { Double(hoursWorkedText) ?? 0 }

    // MARK: - FR-074 Auto-select shift type

    func autoSelectShiftType(using service: SettingsService) {
        let now = Date()
        let cal = Calendar.current

        // Convert a Date to total minutes since midnight
        func minutes(_ date: Date) -> Int {
            cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date)
        }

        let current = minutes(now)
        let morning = minutes(service.morningStartDate)
        let evening = minutes(service.eveningStartDate)
        let night   = minutes(service.nightStartDate)

        // Night wraps past midnight, so check it first
        if current >= night || current < morning {
            shiftType = .night
        } else if current >= evening {
            shiftType = .evening
        } else {
            shiftType = .morning
        }
    }

    // MARK: - Actions

    func save(using service: SettingsService? = nil) async {
        guard validate() else { return }

        isLoading = true
        errorMessage = nil

        let request = buildRequest()

        do {
            let _: TipEntry = try await NetworkClient.post("/tips", body: request)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            savedSuccessfully = true
            resetForm(using: service)
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }

        isLoading = false
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
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        return TipEntryRequest(
            cashTips: cashTips,
            creditTips: creditTips,
            date: dateFormatter.string(from: date),
            shiftType: shiftType.rawValue,
            startTime: useStartEndTime ? timeFormatter.string(from: startTime) : nil,
            endTime: useStartEndTime ? timeFormatter.string(from: endTime) : nil,
            hoursWorked: useStartEndTime ? nil : hoursWorked,
            notes: nil,
            tipOutRoleIds: [],
            tagIds: []
        )
    }

    func resetForm(using service: SettingsService? = nil) {
        date = .now
        cashTipsText = ""
        creditTipsText = ""
        useStartEndTime = false
        startTime = .now
        endTime = .now
        hoursWorkedText = ""
        if let service {
            autoSelectShiftType(using: service)
        } else {
            shiftType = .morning
        }
    }
}
