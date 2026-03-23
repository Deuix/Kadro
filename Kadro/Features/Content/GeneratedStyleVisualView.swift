import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct GeneratedStyleVisualView: View {
    let result: KadroGeneratedStyleImageResponse
    var useButtonTitle: String? = nil
    var onUse: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image = platformImage {
                        imageView(image)
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
    
    #if canImport(UIKit)
    private var platformImage: UIImage? {
        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    private func imageView(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kadroSand, lineWidth: 1)
            )
    }
    #elseif canImport(AppKit)
    private var platformImage: NSImage? {
        guard let imageData else { return nil }
        return NSImage(data: imageData)
    }
    
    private func imageView(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.kadroSand, lineWidth: 1)
            )
    }
    #else
    private var platformImage: Never? { nil }
    #endif
}
