import SwiftUI
import LabelProofCore

struct GoldenLabelFormView: View {
    enum Mode {
        case create
        case edit(GoldenLabel)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: Mode

    @State private var name: String = ""
    @State private var expectedProductName: String = ""
    @State private var expectedWeight: String = ""
    @State private var expectedBarcode: String = ""
    @State private var requiredPhrases: [String] = []
    @State private var newPhrase: String = ""
    @State private var notes: String = ""

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "goldenLabelForm.section.identity")) {
                    TextField(String(localized: "goldenLabelForm.name"), text: $name)
                        .accessibilityIdentifier("goldenLabelForm.name")
                    TextField(String(localized: "goldenLabelForm.expectedProductName"), text: $expectedProductName)
                        .accessibilityIdentifier("goldenLabelForm.expectedProductName")
                }

                Section(String(localized: "goldenLabelForm.section.values")) {
                    TextField(String(localized: "goldenLabelForm.expectedWeight"), text: $expectedWeight)
                        .accessibilityIdentifier("goldenLabelForm.expectedWeight")
                    TextField(String(localized: "goldenLabelForm.expectedBarcode"), text: $expectedBarcode)
                        .keyboardType(.numbersAndPunctuation)
                        .accessibilityIdentifier("goldenLabelForm.expectedBarcode")
                }

                Section(String(localized: "goldenLabelForm.section.requiredPhrases")) {
                    ForEach(requiredPhrases.indices, id: \.self) { index in
                        Text(requiredPhrases[index])
                    }
                    .onDelete { requiredPhrases.remove(atOffsets: $0) }

                    HStack {
                        TextField(String(localized: "goldenLabelForm.newPhrase"), text: $newPhrase)
                            .accessibilityIdentifier("goldenLabelForm.newPhraseField")
                        Button {
                            guard !newPhrase.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            requiredPhrases.append(newPhrase)
                            newPhrase = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .accessibilityIdentifier("goldenLabelForm.addPhraseButton")
                    }
                }

                Section(String(localized: "goldenLabelForm.section.notes")) {
                    TextField(String(localized: "goldenLabelForm.notes"), text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? String(localized: "goldenLabelForm.editTitle") : String(localized: "goldenLabelForm.createTitle"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.save"), action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .accessibilityIdentifier("goldenLabelForm.saveButton")
                }
            }
            .onAppear(perform: populateIfEditing)
        }
    }

    private func populateIfEditing() {
        guard case .edit(let goldenLabel) = mode else { return }
        name = goldenLabel.name
        expectedProductName = goldenLabel.expectedProductName
        expectedWeight = goldenLabel.expectedWeight
        expectedBarcode = goldenLabel.expectedBarcode
        requiredPhrases = goldenLabel.requiredPhrases
        notes = goldenLabel.notes
    }

    private func save() {
        let store = GoldenLabelStore(context: modelContext)
        switch mode {
        case .create:
            let goldenLabel = GoldenLabel(
                name: name,
                expectedProductName: expectedProductName,
                expectedWeight: expectedWeight,
                expectedBarcode: expectedBarcode,
                requiredPhrases: requiredPhrases,
                notes: notes
            )
            store.create(goldenLabel)
        case .edit(var goldenLabel):
            goldenLabel.name = name
            goldenLabel.expectedProductName = expectedProductName
            goldenLabel.expectedWeight = expectedWeight
            goldenLabel.expectedBarcode = expectedBarcode
            goldenLabel.requiredPhrases = requiredPhrases
            goldenLabel.notes = notes
            store.update(goldenLabel)
        }
        dismiss()
    }
}
