import SwiftUI

struct SettingsView: View {

    @Environment(SettingsService.self) private var settingsService
    @Environment(AuthService.self)     private var authService
    @State private var viewModel: SettingsViewModel?
    @State private var showEraseConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    form(vm: vm)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.bgPrimary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.bgPrimary)
            .task {
                let vm = SettingsViewModel(service: settingsService)
                viewModel = vm
                await vm.load()
            }
        }
    }

    // MARK: - Form

    @ViewBuilder
    private func form(vm: SettingsViewModel) -> some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(spacing: Spacing.s24) {

                // MARK: Account
                settingsSection(title: "ACCOUNT") {
                    VStack(spacing: 0) {
                        if let username = authService.username {
                            row {
                                HStack {
                                    Text("Signed in as")
                                        .font(.bodyRegular)
                                        .foregroundStyle(Color.textPrimary)
                                    Spacer()
                                    Text("@\(username)")
                                        .font(.bodyMedium)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                            divider
                        }

                        row {
                            Button(role: .destructive) {
                                authService.signOut()
                            } label: {
                                HStack {
                                    Text("Sign Out")
                                        .font(.bodyMedium)
                                        .foregroundStyle(Color.semanticDanger)
                                    Spacer()
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundStyle(Color.semanticDanger)
                                }
                            }
                        }
                    }
                    .tipCardStyle()
                }

                // MARK: Earnings
                settingsSection(title: "EARNINGS") {
                    VStack(spacing: 0) {
                        row {
                            HStack {
                                Text("Tax Rate")
                                    .font(.bodyRegular)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                HStack(spacing: Spacing.s4) {
                                    TextField("3.0", value: Binding(
                                        get: { vm.taxRate * 100 },
                                        set: { vm.taxRate = $0 / 100 }
                                    ), format: .number.precision(.fractionLength(1)))
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                    .font(.bodyMedium)
                                    .foregroundStyle(Color.textPrimary)
                                    Text("%")
                                        .font(.bodyMedium)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        }
                    }
                    .tipCardStyle()
                }

                // MARK: Pay Period
                settingsSection(title: "PAY PERIOD") {
                    VStack(spacing: 0) {
                        row {
                            DatePicker(
                                "Start Date",
                                selection: $vm.payPeriodStartAnchor,
                                displayedComponents: .date
                            )
                            .font(.bodyRegular)
                            .tint(Color.brandPrimary)
                        }

                        divider

                        row {
                            HStack {
                                Text("Length")
                                    .font(.bodyRegular)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                HStack(spacing: Spacing.s12) {
                                    Button {
                                        if vm.payPeriodLengthDays > 1 {
                                            vm.payPeriodLengthDays -= 1
                                        }
                                    } label: {
                                        Image(systemName: "minus.circle")
                                            .foregroundStyle(Color.brandPrimary)
                                            .font(.system(size: 20))
                                    }
                                    Text("\(vm.payPeriodLengthDays) days")
                                        .font(.bodyMedium)
                                        .foregroundStyle(Color.textPrimary)
                                        .frame(minWidth: 64, alignment: .center)
                                    Button {
                                        if vm.payPeriodLengthDays < 31 {
                                            vm.payPeriodLengthDays += 1
                                        }
                                    } label: {
                                        Image(systemName: "plus.circle")
                                            .foregroundStyle(Color.brandPrimary)
                                            .font(.system(size: 20))
                                    }
                                }
                            }
                        }
                    }
                    .tipCardStyle()
                }

                // MARK: Shift Boundaries
                settingsSection(title: "SHIFT BOUNDARIES") {
                    VStack(spacing: 0) {
                        row {
                            DatePicker("Morning", selection: $vm.morningStart, displayedComponents: .hourAndMinute)
                                .font(.bodyRegular)
                                .tint(Color.brandPrimary)
                        }
                        divider
                        row {
                            DatePicker("Evening", selection: $vm.eveningStart, displayedComponents: .hourAndMinute)
                                .font(.bodyRegular)
                                .tint(Color.brandPrimary)
                        }
                        divider
                        row {
                            DatePicker("Night", selection: $vm.nightStart, displayedComponents: .hourAndMinute)
                                .font(.bodyRegular)
                                .tint(Color.brandPrimary)
                        }
                    }
                    .tipCardStyle()
                }

                // MARK: Appearance
                settingsSection(title: "APPEARANCE") {
                    VStack(spacing: 0) {
                        row {
                            HStack {
                                Text("Theme")
                                    .font(.bodyRegular)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Picker("Theme", selection: $vm.theme) {
                                    ForEach(AppTheme.allCases, id: \.self) { t in
                                        Text(t.label).tag(t)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                            }
                        }
                    }
                    .tipCardStyle()
                }

                // MARK: Error
                if let error = vm.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.semanticDanger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.s24)
                }

                // MARK: Save button
                Button {
                    Task { await vm.save() }
                } label: {
                    Group {
                        if vm.isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Save Settings").font(.bodyMedium)
                        }
                    }
                    .tipPrimaryButton()
                }
                .disabled(vm.isSaving)
                .padding(.horizontal, Spacing.s24)

                // MARK: Danger zone
                settingsSection(title: "DATA") {
                    VStack(spacing: 0) {
                        row {
                            Button(role: .destructive) {
                                showEraseConfirm = true
                            } label: {
                                HStack {
                                    Text("Erase Local Data")
                                        .font(.bodyMedium)
                                        .foregroundStyle(Color.semanticDanger)
                                    Spacer()
                                    Image(systemName: "trash")
                                        .foregroundStyle(Color.semanticDanger)
                                }
                            }
                        }
                    }
                    .tipCardStyle()
                }

                Spacer(minLength: Spacing.s32)
            }
            .padding(.top, Spacing.s16)
            .padding(.bottom, Spacing.s32)
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.bgPrimary)
        .overlay(successBanner(vm: vm))
        .confirmationDialog(
            "Erase Local Data?",
            isPresented: $showEraseConfirm,
            titleVisibility: .visible
        ) {
            Button("Erase", role: .destructive) { eraseLocalData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This clears your cached data and signs you out. Nothing on the server is deleted.")
        }
    }

    // MARK: - Success banner

    @ViewBuilder
    private func successBanner(vm: SettingsViewModel) -> some View {
        if vm.savedSuccessfully {
            VStack {
                HStack(spacing: Spacing.s8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.semanticSuccess)
                    Text("Settings saved!")
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
                    withAnimation { vm.savedSuccessfully = false }
                }
            }
        }
    }

    // MARK: - Erase local data

    private func eraseLocalData() {
        authService.signOut()
    }

    // MARK: - Helpers

    private func settingsSection<Content: View>(
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

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, Spacing.s16)
            .frame(minHeight: 52)
    }

    private var divider: some View {
        Divider()
            .background(Color.borderDefault)
            .padding(.horizontal, Spacing.s16)
    }
}

#Preview {
    SettingsView()
        .environment(SettingsService())
        .environment(AuthService())
}
