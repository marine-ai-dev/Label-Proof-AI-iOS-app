import SwiftUI
import LabelProofCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var languageStore: LanguageStore
    @State private var showingClearHistoryConfirmation = false
    @State private var showingResetDemoConfirmation = false
    @State private var showingLanguageSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section(L("settings.section.language")) {
                    Button {
                        showingLanguageSheet = true
                    } label: {
                        HStack {
                            Text("settings.language")
                                .foregroundStyle(.primary)
                            Spacer()
                            if let language = languageStore.selectedLanguage {
                                Text("\(language.symbol) \(language.displayName)")
                                    .foregroundStyle(settings.accent.color)
                            }
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(settings.accent.color)
                        }
                    }
                    .id(settings.accent)
                    .accessibilityIdentifier("settings.languageButton")
                    .accessibilityLabel(Text("settings.language"))
                    .accessibilityValue(Text(languageStore.selectedLanguage?.displayName ?? ""))
                }

                Section(L("settings.section.appearance")) {
                    // `.tint` is bound directly on each Picker (not just
                    // inherited from an ancestor's `.tint`/environment) —
                    // SwiftUI's Form/List-hosted Picker renders its trailing
                    // value + chevron through a UIKit-bridged accessory that
                    // does not reliably re-color on an ancestor's tint
                    // changing alone. Binding `settings.accent.color`
                    // directly here gives this specific view a live
                    // dependency on the accent, so it re-renders immediately
                    // when the user picks a new one.
                    //
                    // `.id(settings.accent)` is additionally required: SwiftUI
                    // only actually refreshes a Picker's UIKit-bridged
                    // accessory tintColor when that Picker's own *selection*
                    // just changed. A sibling Picker whose selection didn't
                    // change (e.g. Appearance, when only Accent Color was
                    // just picked) otherwise keeps its stale tint even though
                    // its `.tint(...)` modifier re-evaluated to a new value.
                    // Changing `.id()` forces SwiftUI to fully discard and
                    // recreate the underlying cell whenever the accent
                    // changes, so every Picker picks up the new tint
                    // immediately, not just the one the user just touched.
                    Picker(L("settings.appearance"), selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearanceLabel(appearance)).tag(appearance)
                        }
                    }
                    .tint(settings.accent.color)
                    .id(settings.accent)
                    .accessibilityIdentifier("settings.appearancePicker")

                    Picker(L("settings.accent"), selection: $settings.accent) {
                        ForEach(AppAccent.allCases) { accent in
                            Text(accentLabel(accent)).tag(accent)
                        }
                    }
                    .tint(settings.accent.color)
                    .id(settings.accent)
                    .accessibilityIdentifier("settings.accentPicker")
                }

                Section {
                    NavigationLink(L("settings.backupSync")) {
                        BackupSettingsView()
                    }
                    .accessibilityIdentifier("settings.backupSyncLink")
                }

                Section(L("settings.section.history")) {
                    Stepper(
                        L("settings.keepHistoryDays \(settings.keepHistoryDays == 0 ? L("settings.forever") : "\(settings.keepHistoryDays)")"),
                        value: $settings.keepHistoryDays,
                        in: 0...365,
                        step: 30
                    )
                    Button(role: .destructive) {
                        showingClearHistoryConfirmation = true
                    } label: {
                        Text("settings.clearHistory")
                    }
                    .accessibilityIdentifier("settings.clearHistoryButton")
                    .confirmationDialog(
                        L("settings.clearHistoryConfirmTitle"),
                        isPresented: $showingClearHistoryConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(L("settings.clearHistoryConfirmAction"), role: .destructive) {
                            VerificationHistoryStore(context: modelContext).clearAll()
                        }
                        Button(L("action.cancel"), role: .cancel) {}
                    }
                }

                Section(L("settings.section.demo")) {
                    Button {
                        showingResetDemoConfirmation = true
                    } label: {
                        Text("settings.resetDemoData")
                    }
                    .accessibilityIdentifier("settings.resetDemoDataButton")
                    .confirmationDialog(
                        L("settings.resetDemoConfirmTitle"),
                        isPresented: $showingResetDemoConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(L("settings.resetDemoConfirmAction")) {
                            resetDemoData()
                        }
                        Button(L("action.cancel"), role: .cancel) {}
                    }
                }

                Section {
                    NavigationLink(L("settings.about")) {
                        AboutView()
                    }
                    .accessibilityIdentifier("settings.aboutLink")
                }
            }
            .navigationTitle(L("settings.title"))
            .sheet(isPresented: $showingLanguageSheet) {
                NavigationStack {
                    LanguageSelectionView(onDismiss: { showingLanguageSheet = false })
                        .navigationTitle(L("settings.language"))
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button(L("action.done")) { showingLanguageSheet = false }
                            }
                        }
                }
            }
        }
    }

    private func resetDemoData() {
        try? modelContext.delete(model: GoldenLabelRecord.self)
        try? modelContext.delete(model: VerificationHistoryRecord.self)
        let goldenLabelStore = GoldenLabelStore(context: modelContext)
        goldenLabelStore.seedDemoDataIfEmpty()
        VerificationHistoryStore(context: modelContext).seedDemoDataIfEmpty()
    }

    private func appearanceLabel(_ appearance: AppAppearance) -> String {
        switch appearance {
        case .system: return L("settings.appearance.system")
        case .light: return L("settings.appearance.light")
        case .dark: return L("settings.appearance.dark")
        case .black: return L("settings.appearance.black")
        }
    }

    private func accentLabel(_ accent: AppAccent) -> String {
        switch accent {
        case .teal: return L("settings.accent.teal")
        case .indigo: return L("settings.accent.indigo")
        case .coral: return L("settings.accent.coral")
        case .mint: return L("settings.accent.mint")
        case .amber: return L("settings.accent.amber")
        }
    }
}
