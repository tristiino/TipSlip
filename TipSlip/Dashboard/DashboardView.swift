import SwiftUI
import Charts

// Helper for dual-line chart data
private struct TipTypeSample: Identifiable {
    let id: String
    let date: Date
    let amount: Double
    let type: String
}

struct DashboardView: View {

    @Environment(SettingsService.self) private var settingsService
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: DashboardViewModel?
    @State private var selectedEarningsDate: Date? = nil
    @State private var selectedCashCreditDate: Date? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.s24) {

                    // MARK: Custom header
                    HStack {
                        Text("Dashboard")
                            .font(.displayLarge)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Image("logo-full")
                            .resizable()
                            .renderingMode(.original)
                            .scaledToFit()
                            .frame(height: 52)
                    }
                    .padding(.horizontal, Spacing.s16)
                    .padding(.top, Spacing.s8)

                    // MARK: Period picker
                    Picker("Period", selection: Binding(
                        get: { viewModel?.period ?? .week },
                        set: { newVal in Task { await viewModel?.changePeriod(to: newVal) } }
                    )) {
                        ForEach(viewModel?.availablePeriods ?? DashboardPeriod.withoutPayPeriod, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .dynamicTypeSize(.xSmall ... .accessibility1) // segmented labels can't scale past this
                    .padding(.horizontal, Spacing.s16)
                    // MARK: Next pay period boundary (FR-032)
                    if viewModel?.period == .payPeriod,
                       let boundary = viewModel?.nextPayPeriodBoundary {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                                .accessibilityHidden(true)
                            Text("Pay period ends \(boundary.formatted(.dateTime.month(.abbreviated).day()))")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                        .padding(.horizontal, Spacing.s16)
                        .accessibilityElement(children: .combine)
                    }

                    if let summary = viewModel?.summary {

                        // MARK: Stats group 1 — overview
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.s12) {
                            statCard(
                                label: "Total Tips",
                                value: summary.grossTips.asCurrency,
                                icon: "dollarsign.circle.fill",
                                color: Color.brandPrimary
                            )
                            statCard(
                                label: "Net Earnings",
                                value: summary.netEarnings.asCurrency,
                                icon: "arrow.down.circle.fill",
                                color: Color.semanticSuccess
                            )
                            statCard(
                                label: "Hours Worked",
                                value: String(format: "%.1f h", summary.totalHoursWorked),
                                icon: "clock.fill",
                                color: Color.brandAccent
                            )
                            statCard(
                                label: "Shifts Worked",
                                value: "\(summary.shiftsWorked)",
                                icon: "list.bullet.rectangle.portrait.fill",
                                color: Color.brandPrimary
                            )
                        }
                        .padding(.horizontal, Spacing.s16)

                        // MARK: Earnings chart
                        if !(viewModel?.dailyEarnings.isEmpty ?? true) {
                            earningsChart
                        }

                        // MARK: Stats group 2 — breakdown
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.s12) {
                            statCard(
                                label: "Avg Per Shift",
                                value: summary.avgTipsPerShift.asCurrency,
                                icon: "divide",
                                color: Color.brandPrimary
                            )
                            statCard(
                                label: "Gross Earnings",
                                value: summary.totalTips.asCurrency,
                                icon: "chart.bar.doc.horizontal.fill",
                                color: Color.brandAccent
                            )
                            statCard(
                                label: "Cash Tips",
                                value: (viewModel?.totalCashTips ?? 0).asCurrency,
                                icon: "banknote.fill",
                                color: Color.semanticSuccess
                            )
                            statCard(
                                label: "Credit Tips",
                                value: (viewModel?.totalCreditTips ?? 0).asCurrency,
                                icon: "creditcard.fill",
                                color: Color.brandPrimary
                            )
                        }
                        .padding(.horizontal, Spacing.s16)

                        // MARK: Cash vs Credit chart
                        if !(viewModel?.dailyEarnings.isEmpty ?? true) {
                            cashCreditChart
                        }

                    } else if viewModel?.isLoading == true {
                        ProgressView()
                            .padding(.top, Spacing.s48)
                            .accessibilityLabel("Loading dashboard data")
                    } else if let error = viewModel?.errorMessage {
                        errorView(message: error)
                    } else if viewModel?.summary == nil && viewModel?.isLoading == false {
                        emptyState
                    }
                }
                .padding(.top, Spacing.s16)
                .padding(.bottom, Spacing.s32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .refreshable {
                await viewModel?.load(force: true)
            }
            .task {
                await settingsService.load()  // ensure settings are ready before init
                let vm = DashboardViewModel(settingsService: settingsService)
                viewModel = vm
                await vm.load()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel?.load() }
                }
            }
        }
    }

    // MARK: - Earnings chart

    private var earningsChart: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Text("Earnings")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, Spacing.s4)
                .accessibilityAddTraits(.isHeader)

            Chart(viewModel?.dailyEarnings ?? []) { day in
                LineMark(
                    x: .value("Date", day.parsedDate, unit: .day),
                    y: .value("Tips", day.totalTips)
                )
                .foregroundStyle(Color.brandPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", day.parsedDate, unit: .day),
                    y: .value("Tips", day.totalTips)
                )
                .foregroundStyle(selectedEarningsDate.map { Calendar.current.isDate($0, inSameDayAs: day.parsedDate) } == true ? Color.brandPrimary : Color.brandAccent)
                .symbolSize(selectedEarningsDate.map { Calendar.current.isDate($0, inSameDayAs: day.parsedDate) } == true ? 120 : 60)
                .annotation(position: .top) {
                    if let sel = selectedEarningsDate,
                       Calendar.current.isDate(sel, inSameDayAs: day.parsedDate) {
                        VStack(spacing: 2) {
                            Text(day.parsedDate, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            Text(day.totalTips, format: .currency(code: "USD"))
                                .font(.captionBold)
                                .foregroundStyle(Color.textPrimary)
                        }
                        .padding(.horizontal, Spacing.s8)
                        .padding(.vertical, Spacing.s4)
                        .background(Color.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Radii.small))
                        .shadow(color: .black.opacity(0.1), radius: 4)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: chartAxisStride)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.borderDefault)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(amount, format: .currency(code: "USD").precision(.fractionLength(0)))
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.borderDefault)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            let origin = geo[proxy.plotAreaFrame].origin
                            let tapX = location.x - origin.x
                            let tapY = location.y - origin.y
                            guard let earnings = viewModel?.dailyEarnings else { return }
                            var closest: DailyEarning? = nil
                            var closestDist = CGFloat.infinity
                            for day in earnings {
                                guard let dotX = proxy.position(forX: day.parsedDate),
                                      let dotY = proxy.position(forY: day.totalTips) else { continue }
                                let dist = hypot(tapX - dotX, tapY - dotY)
                                if dist < closestDist { closestDist = dist; closest = day }
                            }
                            guard let day = closest, closestDist < 30 else {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedEarningsDate = nil }
                                return
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if let sel = selectedEarningsDate, Calendar.current.isDate(sel, inSameDayAs: day.parsedDate) {
                                    selectedEarningsDate = nil
                                } else {
                                    selectedEarningsDate = day.parsedDate
                                }
                            }
                        }
                }
            }
            .frame(height: 200)
            .animation(.easeInOut(duration: 0.5), value: viewModel?.period)
            .padding(Spacing.s16)
            .tipCardStyle()
            .accessibilityLabel("Earnings chart showing daily tip totals for the selected period")
        }
        .padding(.horizontal, Spacing.s16)
    }

    // MARK: - Cash vs Credit chart

    private var cashCreditSamples: [TipTypeSample] {
        (viewModel?.dailyEarnings ?? []).flatMap { day in
            [
                TipTypeSample(id: "cash-\(day.date)", date: day.parsedDate, amount: day.cashTips,   type: "Cash"),
                TipTypeSample(id: "credit-\(day.date)", date: day.parsedDate, amount: day.creditTips, type: "Credit")
            ]
        }
    }

    private var cashCreditChart: some View {
        VStack(alignment: .leading, spacing: Spacing.s12) {
            Text("Cash vs. Credit")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, Spacing.s4)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: Spacing.s16) {
                HStack(spacing: Spacing.s4) {
                    Circle().fill(Color.semanticSuccess).frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                    Text("Cash").font(.caption).foregroundStyle(Color.textSecondary)
                }
                HStack(spacing: Spacing.s4) {
                    Circle().fill(Color.brandPrimary).frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                    Text("Credit").font(.caption).foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.s4)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Legend: green is cash tips, blue is credit tips")

            Chart(cashCreditSamples) { sample in
                LineMark(
                    x: .value("Date", sample.date, unit: .day),
                    y: .value("Amount", sample.amount)
                )
                .foregroundStyle(by: .value("Type", sample.type))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("Date", sample.date, unit: .day),
                    y: .value("Amount", sample.amount)
                )
                .foregroundStyle(by: .value("Type", sample.type))
                .symbolSize(selectedCashCreditDate.map { Calendar.current.isDate($0, inSameDayAs: sample.date) } == true ? 80 : 40)
                .annotation(position: .top) {
                    if let sel = selectedCashCreditDate,
                       Calendar.current.isDate(sel, inSameDayAs: sample.date),
                       sample.type == "Cash",
                       let day = viewModel?.dailyEarnings.first(where: { Calendar.current.isDate($0.parsedDate, inSameDayAs: sel) }) {
                        VStack(spacing: 2) {
                            Text(day.parsedDate, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            HStack(spacing: Spacing.s8) {
                                Text("Cash: \(day.cashTips.formatted(.currency(code: "USD")))")
                                    .font(.captionBold)
                                    .foregroundStyle(Color.semanticSuccess)
                                Text("Credit: \(day.creditTips.formatted(.currency(code: "USD")))")
                                    .font(.captionBold)
                                    .foregroundStyle(Color.brandPrimary)
                            }
                        }
                        .padding(.horizontal, Spacing.s8)
                        .padding(.vertical, Spacing.s4)
                        .background(Color.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Radii.small))
                        .shadow(color: .black.opacity(0.1), radius: 4)
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .onTapGesture { location in
                            let origin = geo[proxy.plotAreaFrame].origin
                            let tapX = location.x - origin.x
                            let tapY = location.y - origin.y
                            guard let earnings = viewModel?.dailyEarnings else { return }
                            var closest: DailyEarning? = nil
                            var closestDist = CGFloat.infinity
                            for day in earnings {
                                for amount in [day.cashTips, day.creditTips] {
                                    guard let dotX = proxy.position(forX: day.parsedDate),
                                          let dotY = proxy.position(forY: amount) else { continue }
                                    let dist = hypot(tapX - dotX, tapY - dotY)
                                    if dist < closestDist { closestDist = dist; closest = day }
                                }
                            }
                            guard let day = closest, closestDist < 30 else {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedCashCreditDate = nil }
                                return
                            }
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if let sel = selectedCashCreditDate, Calendar.current.isDate(sel, inSameDayAs: day.parsedDate) {
                                    selectedCashCreditDate = nil
                                } else {
                                    selectedCashCreditDate = day.parsedDate
                                }
                            }
                        }
                }
            }
            .chartForegroundStyleScale([
                "Cash":   Color.semanticSuccess,
                "Credit": Color.brandPrimary
            ])
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: chartAxisStride)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(date, format: .dateTime.month(.abbreviated).day())
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.borderDefault)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    if let amount = value.as(Double.self) {
                        AxisValueLabel {
                            Text(amount, format: .currency(code: "USD").precision(.fractionLength(0)))
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.borderDefault)
                }
            }
            .frame(height: 200)
            .animation(.easeInOut(duration: 0.5), value: viewModel?.period)
            .padding(Spacing.s16)
            .tipCardStyle()
            .accessibilityLabel("Cash vs credit tips chart showing daily breakdown for the selected period")
        }
        .padding(.horizontal, Spacing.s16)
    }

    // Axis label density based on period
    private var chartAxisStride: Int {
        switch viewModel?.period {
        case .week:          return 1
        case .twoWeeks:      return 2
        case .month:         return 7
        case .payPeriod:     return 2
        case .lastPayPeriod: return 2
        case .ytd:           return 30
        case .none:          return 1
        }
    }

    // MARK: - Subviews

    private func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                Spacer()
            }
            Text(value)
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(Spacing.s16)
        .tipCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.s16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(Color.textTertiary)
                .accessibilityHidden(true)
            Text("No shifts yet")
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)
            Text("Log your first shift using the Add Tip tab to see your earnings here.")
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Spacing.s48)
        .padding(.horizontal, Spacing.s32)
        .accessibilityElement(children: .combine)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.s12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)
                .accessibilityHidden(true)
            Text(message)
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel?.load(force: true) }
            }
            .font(.bodyMedium)
            .foregroundStyle(Color.brandPrimary)
        }
        .padding(.top, Spacing.s48)
        .padding(.horizontal, Spacing.s32)
    }
}

// MARK: - Double formatting helper

private extension Double {
    var asCurrency: String {
        self.formatted(.currency(code: "USD").precision(.fractionLength(2)))
    }
}

#Preview {
    DashboardView()
        .environment(AuthService())
        .environment(SettingsService())
}
