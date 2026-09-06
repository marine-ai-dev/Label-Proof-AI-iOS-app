import SwiftUI
import LabelProofCore

struct ResultView: View {
    // See HomeView's comment on this same property: required so `L(...)`
    // strings actually refresh when language changes while this view is
    // kept alive but not currently visible.
    @EnvironmentObject private var languageStore: LanguageStore
    let goldenLabel: GoldenLabel
    let scan: ExtractedLabelData
    let result: ValidationResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                statusBanner

                if !result.mismatches.isEmpty {
                    Text("result.mismatchesTitle")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(result.mismatches) { mismatch in
                        MismatchRow(mismatch: mismatch)
                    }
                }

                GlassCard {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text("result.rawScanTitle").font(.subheadline.weight(.semibold))
                        Text(scan.rawTextLines.isEmpty ? L("result.noTextRecognized") : scan.rawTextLines.joined(separator: "\n"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle(L("result.title"))
        .accessibilityIdentifier("result.screen")
    }

    @ViewBuilder
    private var statusBanner: some View {
        GlassCard {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: statusIconName)
                    .font(.system(size: 32))
                    .foregroundStyle(statusColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.title3.bold())
                    Text(goldenLabel.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        // Non-color-only PASS/FAIL indication: distinct SF Symbol + text label
        // in addition to color, per accessibility requirements.
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(statusTitle))
        .accessibilityIdentifier("result.statusBanner.\(result.status.rawValue)")
    }

    private var statusIconName: String {
        switch result.status {
        case .pass: return "checkmark.seal.fill"
        case .fail: return "xmark.seal.fill"
        case .insufficientData: return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch result.status {
        case .pass: return .green
        case .fail: return .red
        case .insufficientData: return .orange
        }
    }

    private var statusTitle: String {
        switch result.status {
        case .pass: return L("result.status.pass")
        case .fail: return L("result.status.fail")
        case .insufficientData: return L("result.status.insufficientData")
        }
    }
}

private struct MismatchRow: View {
    let mismatch: LabelMismatch

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(fieldLabel)
                    .font(.subheadline.weight(.semibold))
                Text("result.expected \(mismatch.expected)")
                    .font(.caption)
                Text("result.actual \(mismatch.actual.isEmpty ? L("result.notFound") : mismatch.actual)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("result.mismatch.\(mismatch.field.rawValue).\(mismatch.phraseIndex ?? 0)")
    }

    private var fieldLabel: String {
        switch mismatch.field {
        case .productName: return L("result.field.productName")
        case .weight: return L("result.field.weight")
        case .barcode: return L("result.field.barcode")
        case .requiredPhrase: return L("result.field.requiredPhrase")
        }
    }
}
