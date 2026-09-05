import SwiftUI
import LabelProofCore

struct ResultView: View {
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
                        Text(scan.rawTextLines.isEmpty ? String(localized: "result.noTextRecognized") : scan.rawTextLines.joined(separator: "\n"))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .navigationTitle(String(localized: "result.title"))
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
        case .pass: return String(localized: "result.status.pass")
        case .fail: return String(localized: "result.status.fail")
        case .insufficientData: return String(localized: "result.status.insufficientData")
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
                Text("result.actual \(mismatch.actual.isEmpty ? String(localized: "result.notFound") : mismatch.actual)")
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
        case .productName: return String(localized: "result.field.productName")
        case .weight: return String(localized: "result.field.weight")
        case .barcode: return String(localized: "result.field.barcode")
        case .requiredPhrase: return String(localized: "result.field.requiredPhrase")
        }
    }
}
