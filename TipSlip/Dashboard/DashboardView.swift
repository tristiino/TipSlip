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

    @State private var viewModel = DashboardViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.s24) {

                    // MARK: Period picker
                    Picker("Period", selection: $viewModel.period) {
                        ForEach(viewModel.availablePeriods, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Spacing.s16)
                    .onChange(of: viewModel.period) { _, new in
                        Task { await viewModel.changePeriod(to: new) }
                    }

                    // MARK: Next pay period boundary (FR-032)
                    if viewModel.period == .payPeriod,
                       let boundary = viewModel.nextPayPeriodBoundary {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                            Text("Pay period ends \(boundary.formatted(.dateTime.month(.abbreviated).day()))")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                        }
                        .padding(.horizontal, Spacing.s16)
                    }

                    if let summary = viewModel.summary {

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
                        if !viewModel.dailyEarnings.isEmpty {
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
                                value: viewModel.totalCashTips.asCurrency,
                                icon: "banknote.fill",
                                color: Color.semanticSuccess
                            )
                            statCard(
                                label: "Credit Tips",
                                value: viewModel.totalCreditTips.asCurrency,
                                icon: "creditcard.fill",
                                color: Color.brandPrimary
                            )
                        }
                        .padding(.horizontal, Spacing.s16)

                        // MARK: Cash vs Credit chart
                        if !viewModel.dailyEarnings.isEmpty {
                            cashCreditChart
                        }

                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, Spacing.s48)
                    } else if let error = viewModel.errorMessage {
                        errorView(message: error)
                    }
                }
                .padding(.top, Spacing.s16)
                .padding(.bottom, Spacing.s32)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.load(force: true)
            }
            .task {
                await viewModel.load()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel.load() }
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

            Chart(viewModel.dailyEarnings) { day in
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
                .foregroundStyle(Color.brandAccent)
                .symbolSize(60)
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
            .frame(height: 200)
            .padding(Spacing.s16)
            .tipCardStyle()
        }
        .padding(.horizontal, Spacing.s16)
    }

    // MARK: - Cash vs Credit chart

    private var cashCreditSamples: [TipTypeSample] {
        viewModel.dailyEarnings.flatMap { day in
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

            HStack(spacing: Spacing.s16) {
                HStack(spacing: Spacing.s4) {
                    Circle().fill(Color.semanticSuccess).frame(width: 8, height: 8)
                    Text("Cash").font(.caption).foregroundStyle(Color.textSecondary)
                }
                HStack(spacing: Spacing.s4) {
                    Circle().fill(Color.brandPrimary).frame(width: 8, height: 8)
                    Text("Credit").font(.caption).foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.s4)

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
                .symbolSize(40)
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
            .padding(Spacing.s16)
            .tipCardStyle()
        }
        .padding(.horizontal, Spacing.s16)
    }

    // Axis label density based on period
    private var chartAxisStride: Int {
        switch viewModel.period {
        case .week:          return 1
        case .twoWeeks:      return 2
        case .month:         return 7
        case .payPeriod:     return 2
        case .lastPayPeriod: return 2
        case .ytd:           return 30
        }
    }

    // MARK: - Subviews

    private func statCard(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.titleMedium)
                .foregroundStyle(Color.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(Spacing.s16)
        .tipCardStyle()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.s12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)
            Text(message)
                .font(.bodyRegular)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            Button("Try Again") {
                Task { await viewModel.load(force: true) }
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
}
