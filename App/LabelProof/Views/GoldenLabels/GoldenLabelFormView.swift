import SwiftUI
import LabelProofCore

struct GoldenLabelFormView: View {
    enum Mode {
        case create
        case edit(GoldenLabel)
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    // See HomeView's comment on this same property.
    @EnvironmentObject private var languageStore: LanguageStore

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
                Section(L("goldenLabelForm.section.identity")) {
                    TextField(L("goldenLabelForm.name"), text: $name)
                        .accessibilityIdentifier("goldenLabelForm.name")
                    TextField(L("goldenLabelForm.expectedProductName"), text: $expectedProductName)
                        .accessibilityIdentifier("goldenLabelForm.expectedProductName")
                }

                Section(L("goldenLabelForm.section.values")) {
                    TextField(L("goldenLabelForm.expectedWeight"), text: $expectedWeight)
                        .accessibilityIdentifier("goldenLabelForm.expectedWeight")
                    TextField(L("goldenLabelForm.expectedBarcode"), text: $expectedBarcode)
                        .keyboardType(.numbersAndPunctuation)
                        .accessibilityIdentifier("goldenLabelForm.expectedBarcode")
                }

                Section(L("goldenLabelForm.section.requiredPhrases")) {
                    ForEach(requiredPhrases.indices, id: \.self) { index in
                        Text(requiredPhrases[index])
                    }
                    .onDelete { requiredPhrases.remove(atOffsets: $0) }

                    HStack {
                        TextField(L("goldenLabelForm.newPhrase"), text: $newPhrase)
                            .accessibilityIdentifier("goldenLabelForm.newPhraseField")
                        Button {
                            guard !newPhrase.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            requiredPhrases.append(newPhrase)
                            newPhrase = ""
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .accessibilityLabel(Text("goldenLabelForm.addPhrase"))
                        .accessibilityIdentifier("goldenLabelForm.addPhraseButton")
                    }
                }

                Section(L("goldenLabelForm.section.notes")) {
                    TextField(L("goldenLabelForm.notes"), text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? L("goldenLabelForm.editTitle") : L("goldenLabelForm.createTitle"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L("action.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L("action.save"), action: save)
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
