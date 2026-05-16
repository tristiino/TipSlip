import Foundation

@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Dependencies
    private let service: SettingsService

    // MARK: - Editable form state (mirrors UserSettings fields)
    var taxRate:              Double  = 0.03
    var payPeriodStartAnchor: Date    = .now
    var payPeriodLengthDays:  Int     = 14
    var morningStart:         Date    = Calendar.current.date(bySettingHour: 6,  minute: 0, second: 0, of: .now) ?? .now
    var eveningStart:         Date    = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: .now) ?? .now
    var nightStart:           Date    = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: .now) ?? .now
    var theme:                AppTheme = .system

    // MARK: - UI state
    var isLoading:      Bool    = false
    var isSaving:       Bool    = false
    var errorMessage:   String?
    var savedSuccessfully: Bool = false

    // MARK: - Init

    init(service: SettingsService) {
        self.service = service
    }

    // MARK: - Actions

    func load() async {
        isLoading = true
        await service.load()
        if let s = service.settings {
            populateForm(from: s)
        }
        errorMessage = service.errorMessage
        isLoading = false
    }

    func save() async {
        guard var current = service.settings else { return }

        // Write form state back into the model
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"

        current.taxRate              = taxRate
        current.payPeriodStartAnchor = dateFmt.string(from: payPeriodStartAnchor)
        current.payPeriodLengthDays  = payPeriodLengthDays
        current.morningStart         = timeFmt.string(from: morningStart)
        current.eveningStart         = timeFmt.string(from: eveningStart)
        current.nightStart           = timeFmt.string(from: nightStart)
        current.theme                = theme

        service.settings = current

        isSaving = true
        await service.save()
        isSaving = false

        if service.errorMessage == nil {
            savedSuccessfully = true
        } else {
            errorMessage = service.errorMessage
        }
    }

    // MARK: - Private

    private func populateForm(from s: UserSettings) {
        taxRate = s.taxRate
        theme   = s.theme

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        if let anchor = s.payPeriodStartAnchor, let d = dateFmt.date(from: anchor) {
            payPeriodStartAnchor = d
        }

        payPeriodLengthDays = s.payPeriodLengthDays

        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm:ss"
        timeFmt.timeZone = .current

        func parseTime(_ str: String?, defaultHour: Int) -> Date {
            if let str, let parsed = timeFmt.date(from: str) {
                let cal = Calendar.current
                let now = Date()
                var comps = cal.dateComponents([.hour, .minute, .second], from: parsed)
                comps.year  = cal.component(.year,  from: now)
                comps.month = cal.component(.month, from: now)
                comps.day   = cal.component(.day,   from: now)
                return cal.date(from: comps) ?? now
            }
            return Calendar.current.date(bySettingHour: defaultHour, minute: 0, second: 0, of: .now) ?? .now
        }

        morningStart = parseTime(s.morningStart, defaultHour: 6)
        eveningStart = parseTime(s.eveningStart, defaultHour: 14)
        nightStart   = parseTime(s.nightStart,   defaultHour: 21)
    }
}
