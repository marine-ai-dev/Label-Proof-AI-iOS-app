import SwiftUI
import SwiftData

@main
struct LabelProofApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: GoldenLabelRecord.self, VerificationHistoryRecord.self)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
        LaunchEnvironment.applyIfNeeded(to: modelContainer)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .tint(AppTheme.shared.accent)
        }
        .modelContainer(modelContainer)
    }
}
