import SwiftUI
import SwiftData
import LabelProofCore

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var goldenLabels: [GoldenLabel] = []
    @State private var selectedGoldenLabel: GoldenLabel?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    GlassCard {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("home.welcomeTitle")
                                .font(.title2.bold())
                            Text("home.welcomeSubtitle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)

                    Text("home.pickGoldenLabel")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    if goldenLabels.isEmpty {
                        emptyState
                    } else {
                        ForEach(goldenLabels) { goldenLabel in
                            Button {
                                selectedGoldenLabel = goldenLabel
                            } label: {
                                GlassCard {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(goldenLabel.name).font(.body.weight(.semibold))
                                            Text(goldenLabel.expectedProductName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "camera.viewfinder")
                                            .font(.title3)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("home.goldenLabel.\(goldenLabel.id.uuidString)")
                            .accessibilityLabel(Text("home.scanAccessibilityLabel \(goldenLabel.name)"))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "home.title"))
            .background(homeBackground)
            .onAppear(perform: reload)
            .sheet(item: $selectedGoldenLabel) { goldenLabel in
                ScannerView(goldenLabel: goldenLabel)
            }
        }
    }

    private var emptyState: some View {
        GlassCard {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("home.emptyTitle").font(.headline)
                Text("home.emptySubtitle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .accessibilityIdentifier("home.emptyState")
    }

    private var homeBackground: some View {
        Color(.systemGroupedBackground).ignoresSafeArea()
    }

    private func reload() {
        let store = GoldenLabelStore(context: modelContext)
        goldenLabels = store.fetchAll()
    }
}
