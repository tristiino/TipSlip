import SwiftUI

struct EditTipView: View {

    @Environment(TipService.self)  private var tipService
    @Environment(\.dismiss)        private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var viewModel: EditTipViewModel
    @State private var showDeleteConfirm = false

    init(entry: TipEntry) {
        _viewModel = State(initialValue: EditTipViewModel(entry: entry))
    }

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
                        Task { await viewModel.save(using: tipService) }
                    } label: {
                        Group {
                            if viewModel.isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Save Changes").font(.bodyMedium)
                            }
                        }
                        .tipPrimaryButton()
                    }
                    .accessibilityLabel(viewModel.isSaving ? "Saving changes" : "Save Changes")
                    .disabled(viewModel.isSaving || viewModel.isDeleting)
                    .padding(.horizontal, Spacing.s24)

                    // MARK: Delete button
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .accessibilityHidden(true)
                            Text("Delete Shift")
                                .font(.bodyMedium)
                        }
                        .foregroundStyle(Color.semanticDanger)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(Color.bgSurface)
                        .clipShape(RoundedRectangle(cornerRadius: Radii.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radii.large)
                                .stroke(Color.semanticDanger.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .accessibilityLabel("Delete this shift")
                    .disabled(viewModel.isSaving || viewModel.isDeleting)
                    .padding(.horizontal, Spacing.s24)
                    .padding(.bottom, Spacing.s32)
                }
                .padding(.top, Spacing.s24)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Edit Shift")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.brandPrimary)
                }
            }
            .confirmationDialog(
                "Delete Shift?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await viewModel.delete(using: tipService)
                            dismiss()
                        } catch {
                            viewModel.errorMessage = "Could not delete. Please try again."
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This shift will be permanently deleted.")
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.savedSuccessfully)
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved { dismiss() }
        }
        .overlay(savingOverlay)
    }

    // MARK: - Saving overlay (dismiss after success)

    @ViewBuilder
    private var savingOverlay: some View {
        if viewModel.isDeleting {
            ZStack {
                Color.black.opacity(0.2).ignoresSafeArea()
                ProgressView("Deleting…")
                    .padding(Spacing.s24)
                    .background(Color.bgSurface)
                    .clipShape(RoundedRectangle(cornerRadius: Radii.large))
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
            HStack {
                Text(label)
                    .font(.bodyRegular)
                    .foregroundStyle(Color.textPrimary)
                    .accessibilityHidden(true)
                Spacer()
                inputField
            }
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
    EditTipView(entry: TipEntry(
        id: 1,
        amount: 120.0,
        cashTips: 50.0,
        creditTips: 70.0,
        date: "2026-05-16",
        shiftType: "Evening",
        notes: nil,
        startTime: nil,
        endTime: nil,
        hoursWorked: 6.5,
        tipOutRecords: nil
    ))
    .environment(TipService())
}
