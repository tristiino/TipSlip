import SwiftUI

struct AddTipView: View {

    @Environment(SettingsService.self) private var settingsService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = AddTipViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.s24) {

                    // MARK: Date & Shift
                    formSection(title: "SHIFT", accessibilityTitle: "Shift") {
                        VStack(spacing: Spacing.s12) {
                            HStack {
                                Text("Date")
                                    .font(.bodyRegular)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(Color.brandPrimary)
                                    .accessibilityLabel("Shift date")
                            }
                            .padding(.horizontal, Spacing.s16)
                            .frame(minHeight: 48)

                            Divider().background(Color.borderDefault)

                            Picker("Shift Type", selection: $viewModel.shiftType) {
                                ForEach(ShiftType.allCases, id: \.self) { type in
                                    Text(type.label).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Spacing.s16)
                            .padding(.bottom, Spacing.s12)
                            .accessibilityLabel("Shift type")
                        }
                        .tipCardStyle()
                    }

                    // MARK: Tips
                    formSection(title: "TIPS", accessibilityTitle: "Tips") {
                        VStack(spacing: Spacing.s12) {
                            tipAmountRow(label: "Cash Tips", text: $viewModel.cashTipsText)

                            Divider().background(Color.borderDefault)

                            tipAmountRow(label: "Credit Tips", text: $viewModel.creditTipsText)
                        }
                        .tipCardStyle()
                    }

                    // MARK: Hours
                    formSection(title: "HOURS", accessibilityTitle: "Hours") {
                        VStack(spacing: Spacing.s12) {
                            Toggle(isOn: $viewModel.useStartEndTime) {
                                Text("Use start & end time")
                                    .font(.bodyRegular)
                                    .foregroundStyle(Color.textPrimary)
                            }
                            .tint(Color.brandPrimary)
                            .padding(.horizontal, Spacing.s16)
                            .padding(.top, Spacing.s12)
                            .accessibilityLabel("Use start and end time instead of hours")

                            Divider().background(Color.borderDefault)

                            if viewModel.useStartEndTime {
                                HStack {
                                    Text("Start")
                                        .font(.bodyRegular)
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                    DatePicker("", selection: $viewModel.startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(Color.brandPrimary)
                                        .accessibilityLabel("Shift start time")
                                }
                                .padding(.horizontal, Spacing.s16)

                                Divider().background(Color.borderDefault)

                                HStack {
                                    Text("End")
                                        .font(.bodyRegular)
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                    DatePicker("", selection: $viewModel.endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(Color.brandPrimary)
                                        .accessibilityLabel("Shift end time")
                                }
                                .padding(.horizontal, Spacing.s16)
                                .padding(.bottom, Spacing.s12)

                            } else {
                                ViewThatFits(in: .horizontal) {
                                    HStack {
                                        Text("Hours Worked")
                                            .font(.bodyRegular)
                                            .foregroundStyle(Color.textPrimary)
                                        Spacer()
                                        TextField("0.0", text: $viewModel.hoursWorkedText)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(minWidth: 80)
                                            .font(.bodyMedium)
                                            .foregroundStyle(Color.textPrimary)
                                            .accessibilityLabel("Hours worked")
                                    }
                                    VStack(alignment: .leading, spacing: Spacing.s8) {
                                        Text("Hours Worked")
                                            .font(.bodyRegular)
                                            .foregroundStyle(Color.textPrimary)
                                        TextField("0.0", text: $viewModel.hoursWorkedText)
                                            .keyboardType(.decimalPad)
                                            .font(.bodyMedium)
                                            .foregroundStyle(Color.textPrimary)
                                            .accessibilityLabel("Hours worked")
                                    }
                                }
                                .padding(.horizontal, Spacing.s16)
                                .padding(.bottom, Spacing.s12)
                            }
                        }
                        .tipCardStyle()
                    }

                    // MARK: Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.semanticDanger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.s24)
                    }

                    // MARK: Save button
                    Button {
                        Task { await viewModel.save(using: settingsService) }
                    } label: {
                        Group {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Shift").font(.bodyMedium)
                            }
                        }
                        .tipPrimaryButton()
                    }
                    .accessibilityLabel(viewModel.isLoading ? "Saving shift" : "Save Shift")
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, Spacing.s24)
                    .padding(.bottom, Spacing.s32)
                }
                .padding(.top, Spacing.s24)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Add Tip")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
            .task {
                await settingsService.load()
                viewModel.autoSelectShiftType(using: settingsService)
            }
        }
        .overlay(successBanner)
    }

    // MARK: - Success banner

    @ViewBuilder
    private var successBanner: some View {
        if viewModel.savedSuccessfully {
            VStack {
                HStack(spacing: Spacing.s8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.semanticSuccess)
                        .accessibilityHidden(true)
                    Text("Shift saved!")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(Spacing.s16)
                .background(Color.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radii.large))
                .shadow(color: .black.opacity(0.08), radius: 8)
                .padding(.top, Spacing.s16)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Shift saved successfully")
                Spacer()
            }
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation { viewModel.savedSuccessfully = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private func formSection<Content: View>(
        title: String,
        accessibilityTitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(title)
                .font(.captionBold)
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, Spacing.s4)
                .accessibilityLabel(accessibilityTitle)
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(.horizontal, Spacing.s16)
    }

    private func tipAmountRow(label: String, text: Binding<String>) -> some View {
        let inputField = HStack(spacing: Spacing.s4) {
            Text("$")
                .font(.bodyMedium)
                .foregroundStyle(Color.textSecondary)
                .accessibilityHidden(true)
            TextField("0.00", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 80)
                .font(.bodyMedium)
                .foregroundStyle(Color.textPrimary)
                .accessibilityLabel("\(label) in dollars")
        }

        return ViewThatFits(in: .horizontal) {
            // Default: label and input on the same line
            HStack {
                Text(label)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityHidden(true)
                Spacer()
                inputField
            }
            // Large text: stack vertically
            VStack(alignment: .leading, spacing: Spacing.s8) {
                Text(label)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityHidden(true)
                inputField
            }
        }
        .padding(.horizontal, Spacing.s16)
        .padding(.vertical, Spacing.s8)
        .frame(minHeight: 48)
    }
}

#Preview {
    AddTipView()
        .environment(AuthService())
        .environment(SettingsService())
}
