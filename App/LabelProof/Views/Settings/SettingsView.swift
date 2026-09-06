import SwiftUI
import LabelProofCore

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var settings: SettingsStore
    @State private var showingClearHistoryConfirmation = false
    @State private var showingResetDemoConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "settings.section.appearance")) {
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
                    Picker(String(localized: "settings.appearance"), selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearanceLabel(appearance)).tag(appearance)
                        }
                    }
                    .tint(settings.accent.color)
                    .id(settings.accent)
                    .accessibilityIdentifier("settings.appearancePicker")

                    Picker(String(localized: "settings.accent"), selection: $settings.accent) {
                        ForEach(AppAccent.allCases) { accent in
                            Text(accentLabel(accent)).tag(accent)
                        }
                    }
                    .tint(settings.accent.color)
                    .id(settings.accent)
                    .accessibilityIdentifier("settings.accentPicker")
                }

                Section(String(localized: "settings.section.history")) {
                    Stepper(
                        String(localized: "settings.keepHistoryDays \(settings.keepHistoryDays == 0 ? String(localized: "settings.forever") : "\(settings.keepHistoryDays)")"),
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
                        String(localized: "settings.clearHistoryConfirmTitle"),
                        isPresented: $showingClearHistoryConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(String(localized: "settings.clearHistoryConfirmAction"), role: .destructive) {
                            VerificationHistoryStore(context: modelContext).clearAll()
                        }
                        Button(String(localized: "action.cancel"), role: .cancel) {}
                    }
                }

                Section(String(localized: "settings.section.demo")) {
                    Button {
                        showingResetDemoConfirmation = true
                    } label: {
                        Text("settings.resetDemoData")
                    }
                    .accessibilityIdentifier("settings.resetDemoDataButton")
                    .confirmationDialog(
                        String(localized: "settings.resetDemoConfirmTitle"),
                        isPresented: $showingResetDemoConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(String(localized: "settings.resetDemoConfirmAction")) {
                            resetDemoData()
                        }
                        Button(String(localized: "action.cancel"), role: .cancel) {}
                    }
                }

                Section {
                    NavigationLink(String(localized: "settings.about")) {
                        AboutView()
                    }
                    .accessibilityIdentifier("settings.aboutLink")
                }
            }
            .navigationTitle(String(localized: "settings.title"))
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
        case .system: return String(localized: "settings.appearance.system")
        case .light: return String(localized: "settings.appearance.light")
        case .dark: return String(localized: "settings.appearance.dark")
        case .black: return String(localized: "settings.appearance.black")
        }
    }

    private func accentLabel(_ accent: AppAccent) -> String {
        switch accent {
        case .teal: return String(localized: "settings.accent.teal")
        case .indigo: return String(localized: "settings.accent.indigo")
        case .coral: return String(localized: "settings.accent.coral")
        case .mint: return String(localized: "settings.accent.mint")
        case .amber: return String(localized: "settings.accent.amber")
        }
    }
}
