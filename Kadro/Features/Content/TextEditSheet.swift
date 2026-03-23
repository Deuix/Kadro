import SwiftUI

struct TextEditSheet: View {
    let title: String
    let text: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var draftText: String
    
    init(title: String, text: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.text = text
        self.onSave = onSave
        _draftText = State(initialValue: text)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $draftText)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
                    .frame(minHeight: 220)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.kadroSoftWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                HStack(spacing: 12) {
                    KadroSecondaryButton(title: "Отмена") {
                        dismiss()
                    }
                    KadroPrimaryButton(title: "Сохранить") {
                        onSave(draftText)
                        dismiss()
                    }
                }
            }
            .padding(20)
            .background(Color.kadroIvory)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
