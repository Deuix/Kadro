import SwiftUI

struct GeneratedStyleVisualView: View {
    let result: KadroGeneratedStyleImageResponse
    var useButtonTitle: String? = nil
    var onUse: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let previewAsset {
                        KadroPreviewableGeneratedImage(asset: previewAsset, cornerRadius: 20)
                    }
                    
                    if let useButtonTitle, let onUse {
                        Button {
                            onUse()
                            dismiss()
                        } label: {
                            Text(useButtonTitle)
                                .font(.kadroButton)
                                .foregroundColor(.kadroCharcoal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.kadroLime)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    
                    KadroCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Style visual ready")
                                .font(.kadroTitle3)
                                .foregroundColor(.kadroCharcoal)
                            Text("Style pack: \(result.stylePackID)")
                                .font(.kadroCallout)
                                .foregroundColor(.kadroWarmGray)
                            Text("References used: \(result.referenceCount)")
                                .font(.kadroCallout)
                                .foregroundColor(.kadroWarmGray)
                            Text("Model: \(result.model)")
                                .font(.kadroCaption)
                                .foregroundColor(.kadroWarmGray)
                        }
                    }
                    
                    KadroCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prompt used")
                                .font(.kadroFootnote)
                                .foregroundColor(.kadroWarmGray)
                            Text(result.promptUsed)
                                .font(.kadroCallout)
                                .foregroundColor(.kadroCharcoal)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(Color.kadroIvory)
            .navigationTitle("Визуал")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.kadroLime)
                }
            }
        }
    }
    
    private var imageData: Data? {
        guard let commaIndex = result.imageDataURL.firstIndex(of: ",") else { return nil }
        let base64 = String(result.imageDataURL[result.imageDataURL.index(after: commaIndex)...])
        return Data(base64Encoded: base64)
    }
    
    private var previewAsset: KadroPreviewImageAsset? {
        guard let imageData else { return nil }
        return KadroPreviewImageAsset(
            id: result.id,
            title: result.visualKind.capitalized,
            subtitle: "Style pack: \(result.stylePackID) · References: \(result.referenceCount)",
            filenameStem: "kadro-\(result.visualKind)-\(result.stylePackID)",
            imageData: imageData
        )
    }
}
