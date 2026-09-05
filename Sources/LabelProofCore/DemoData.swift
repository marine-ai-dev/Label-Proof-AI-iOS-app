import Foundation

/// Fully fictional demo/golden-label data used for Settings > "Reset demo data",
/// SwiftUI previews, and as the seed for XCUITest fixture flows. Contains no
/// proprietary or real-brand information.
public enum DemoData {
    public static let goldenLabels: [GoldenLabel] = [
        GoldenLabel(
            name: "Sunrise Oats 500g",
            expectedProductName: "Sunrise Rolled Oats",
            expectedWeight: "500 g",
            expectedBarcode: "5901234123457",
            requiredPhrases: ["Best before end", "Packed in a facility that also handles nuts"],
            notes: "Fictional demo golden label #1."
        ),
        GoldenLabel(
            name: "Blue Valley Honey 340g",
            expectedProductName: "Blue Valley Wildflower Honey",
            expectedWeight: "340 g",
            expectedBarcode: "4006381333931",
            requiredPhrases: ["Product of Ukraine", "Do not feed to infants under 12 months"],
            notes: "Fictional demo golden label #2."
        ),
        GoldenLabel(
            name: "Northpeak Trail Mix 200g",
            expectedProductName: "Northpeak Trail Mix",
            expectedWeight: "200 g",
            expectedBarcode: "9781234567897",
            requiredPhrases: ["May contain peanuts", "Store in a cool, dry place"],
            notes: "Fictional demo golden label #3."
        )
    ]

    /// One demo scenario per `GoldenLabel` above, cycling through the fixture
    /// scenarios so a fresh install's history shows a representative mix.
    public static func seedVerificationRecords() -> [VerificationRecord] {
        let scenarios: [ScanFixtureScenario] = [
            .fullMatch, .wrongProductName, .wrongWeight, .wrongBarcode,
            .missingRequiredPhrase, .multipleMismatches, .emptyRecognition
        ]
        var records: [VerificationRecord] = []
        for (index, goldenLabel) in goldenLabels.enumerated() {
            let scenario = scenarios[index % scenarios.count]
            let scan = scenario.extractedLabelData(for: goldenLabel)
            let result = LabelValidator.validate(scan: scan, against: goldenLabel)
            records.append(
                VerificationRecord(
                    goldenLabelID: goldenLabel.id,
                    goldenLabelNameSnapshot: goldenLabel.name,
                    result: result,
                    scanSource: .fixture,
                    createdAt: Date().addingTimeInterval(TimeInterval(-index * 3600))
                )
            )
        }
        return records
    }
}
