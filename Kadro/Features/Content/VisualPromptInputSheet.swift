import SwiftUI

struct VisualPromptInputSheet: View {
    let title: String
    @Binding var promptText: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(L10n.Common.visualPromptHint)
                    .font(.kadroCallout)
                    .foregroundColor(.kadroWarmGray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextEditor(text: $promptText)
                    .font(.kadroBody)
                    .foregroundColor(.kadroCharcoal)
                    .frame(minHeight: 160)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(Color.kadroSoftWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                HStack(spacing: 12) {
                    KadroSecondaryButton(title: L10n.Common.cancel) {
                        dismiss()
                    }
                    KadroPrimaryButton(title: L10n.Common.generate) {
                        onSubmit()
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
