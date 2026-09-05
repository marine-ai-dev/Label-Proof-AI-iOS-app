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
                    Picker(String(localized: "settings.appearance"), selection: $settings.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearanceLabel(appearance)).tag(appearance)
                        }
                    }
                    .accessibilityIdentifier("settings.appearancePicker")

                    Picker(String(localized: "settings.accent"), selection: $settings.accent) {
                        ForEach(AppAccent.allCases) { accent in
                            Text(accentLabel(accent)).tag(accent)
                        }
                    }
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
