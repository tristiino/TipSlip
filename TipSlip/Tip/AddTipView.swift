import SwiftUI

struct AddTipView: View {

    @Environment(SettingsService.self) private var settingsService
    @Environment(TipService.self)      private var tipService
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel = AddTipViewModel()
    @State private var editingEntry: TipEntry? = nil
    @State private var undoEntry: TipEntry? = nil

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
                                DatePicker("", selection: $viewModel.date, in: ...Date.now, displayedComponents: .date)
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

                    // MARK: Recent Shifts
                    recentShiftsSection
                        .padding(.bottom, Spacing.s32)
                }
                .padding(.top, Spacing.s24)
            }
            .background(Color.bgPrimary)
            .navigationTitle("Add Tip")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
            .task {
                await settingsService.load()
                viewModel.autoSelectShiftType(using: settingsService)
                await tipService.fetchRecent()
            }
        }
        .overlay(successBanner)
        .overlay(undoBanner)
        .sensoryFeedback(.success, trigger: viewModel.savedSuccessfully)
        .sheet(item: $editingEntry) { entry in
            EditTipView(entry: entry)
                .environment(tipService)
        }
        .onChange(of: viewModel.savedSuccessfully) { _, saved in
            if saved { Task { await tipService.fetchRecent() } }
        }
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

    // MARK: - Recent Shifts

    @ViewBuilder
    private var recentShiftsSection: some View {
        if !tipService.recentEntries.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.s8) {
                HStack {
                    Text("RECENT SHIFTS")
                        .font(.captionBold)
                        .foregroundStyle(Color.textTertiary)
                        .accessibilityLabel("Recent Shifts")
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text("Last 7")
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, Spacing.s4)

                VStack(spacing: 0) {
                    ForEach(Array(tipService.recentEntries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 {
                            Divider()
                                .background(Color.borderDefault)
                                .padding(.horizontal, Spacing.s16)
                        }
                        recentEntryRow(entry: entry)
                    }
                }
                .tipCardStyle()
            }
            .padding(.horizontal, Spacing.s16)
        }
    }

    private func recentEntryRow(entry: TipEntry) -> some View {
        Button {
            editingEntry = entry
        } label: {
            HStack(spacing: Spacing.s12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "dollarsign")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.brandPrimary)
                }
                .accessibilityHidden(true)

                // Info
                VStack(alignment: .leading, spacing: Spacing.s4) {
                    Text(entry.parsedDate, format: .dateTime.month(.abbreviated).day().year())
                        .font(.bodyMedium)
                        .foregroundStyle(Color.textPrimary)
                    HStack(spacing: Spacing.s4) {
                        Text(entry.shiftType ?? "")
                            .font(.caption)
                            .foregroundStyle(Color.textSecondary)
                        if let cash = entry.cashTips, let credit = entry.creditTips {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(Color.textTertiary)
                            Text("$\(String(format: "%.2f", cash)) cash · $\(String(format: "%.2f", credit)) credit")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                Spacer()

                // Total
                Text(entry.amount, format: .currency(code: "USD"))
                    .font(.bodyMedium)
                    .foregroundStyle(Color.semanticSuccess)
            }
            .padding(.horizontal, Spacing.s16)
            .frame(minHeight: 64)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.shiftType ?? "Shift") on \(entry.parsedDate.formatted(.dateTime.month(.abbreviated).day())), total \(entry.amount.formatted(.currency(code: "USD")))")
        .accessibilityHint("Tap to edit")
    }

    private func deleteEntry(_ entry: TipEntry) {
        withAnimation {
            undoEntry = entry
        }
        Task {
            do {
                try await tipService.delete(id: entry.id)
            } catch {
                // Restore on failure
                await tipService.fetchRecent()
            }
        }
        // Auto-clear undo after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                if undoEntry?.id == entry.id { undoEntry = nil }
            }
        }
    }

    // MARK: - Undo banner

    @ViewBuilder
    private var undoBanner: some View {
        if let entry = undoEntry {
            VStack {
                Spacer()
                HStack(spacing: Spacing.s12) {
                    Text("Shift deleted")
                        .font(.bodyRegular)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Button("Undo") {
                        withAnimation { undoEntry = nil }
                        Task { await tipService.fetchRecent() }
                    }
                    .font(.bodyMedium)
                    .foregroundStyle(Color.brandPrimary)
                }
                .padding(Spacing.s16)
                .background(Color.bgSurface)
                .clipShape(RoundedRectangle(cornerRadius: Radii.large))
                .shadow(color: .black.opacity(0.1), radius: 8)
                .padding(.horizontal, Spacing.s16)
                .padding(.bottom, Spacing.s32)
            }
            .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
            .id(entry.id)
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
        .environment(TipService())
}
