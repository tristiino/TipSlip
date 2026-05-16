import SwiftUI

struct AddTipView: View {

    @State private var viewModel = AddTipViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.s24) {

                    // MARK: Date & Shift
                    formSection(title: "SHIFT") {
                        VStack(spacing: Spacing.s12) {
                            HStack {
                                Text("Date")
                                    .font(.bodyRegular)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                                    .labelsHidden()
                                    .tint(Color.brandPrimary)
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
                        }
                        .tipCardStyle()
                    }

                    // MARK: Tips
                    formSection(title: "TIPS") {
                        VStack(spacing: Spacing.s12) {
                            tipAmountRow(label: "Cash Tips", text: $viewModel.cashTipsText)

                            Divider().background(Color.borderDefault)

                            tipAmountRow(label: "Credit Tips", text: $viewModel.creditTipsText)
                        }
                        .tipCardStyle()
                    }

                    // MARK: Hours
                    formSection(title: "HOURS") {
                        VStack(spacing: Spacing.s12) {
                            Toggle(isOn: $viewModel.useStartEndTime) {
                                Text("Use start & end time")
                                    .font(.bodyRegular)
                                    .foregroundStyle(Color.textPrimary)
                            }
                            .tint(Color.brandPrimary)
                            .padding(.horizontal, Spacing.s16)
                            .padding(.top, Spacing.s12)

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
                                }
                                .padding(.horizontal, Spacing.s16)
                                .padding(.bottom, Spacing.s12)

                            } else {
                                HStack {
                                    Text("Hours Worked")
                                        .font(.bodyRegular)
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                    TextField("0.0", text: $viewModel.hoursWorkedText)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                        .font(.bodyMedium)
                                        .foregroundStyle(Color.textPrimary)
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
                        Task { await viewModel.save() }
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
                    Text("Shift saved!")
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                }
                .padding(Spacing.s16)
                .background(Color.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radii.large))
                .shadow(color: .black.opacity(0.08), radius: 8)
                .padding(.top, Spacing.s16)
                Spacer()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
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
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s8) {
            Text(title)
                .font(.captionBold)
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, Spacing.s4)
            content()
        }
        .padding(.horizontal, Spacing.s16)
    }

    private func tipAmountRow(label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.bodyRegular)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            HStack(spacing: Spacing.s4) {
                Text("$")
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textSecondary)
                TextField("0.00", text: text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                    .font(.bodyMedium)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(.horizontal, Spacing.s16)
        .frame(minHeight: 48)
    }
}

#Preview {
    AddTipView()
        .environment(AuthService())
}
