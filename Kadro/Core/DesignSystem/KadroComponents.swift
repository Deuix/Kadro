//
//  KadroComponents.swift
//  Kadro
//
//  Design System — Reusable UI Components
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(Photos)
import Photos
#endif
#if canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
#endif

// MARK: - Primary Button

struct KadroPrimaryButton: View {
    let title: String
    let action: () -> Void
    var isFullWidth: Bool = true
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kadroButton)
                .foregroundColor(.kadroCharcoal)
                .frame(maxWidth: isFullWidth ? .infinity : nil)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color.kadroLime)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

// MARK: - Secondary Button

struct KadroSecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kadroButton)
                .foregroundColor(.kadroCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color.kadroSoftWhite)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.kadroSand, lineWidth: 1)
                )
        }
    }
}

// MARK: - Card

struct KadroCard<Content: View>: View {
    var padding: CGFloat = 20
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.kadroSoftWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Action Card (tappable)

struct KadroActionCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.kadroLime)
                    .frame(width: 44, height: 44)
                    .background(Color.kadroCharcoal)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.kadroBodyMedium)
                        .foregroundColor(.kadroCharcoal)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.kadroFootnote)
                            .foregroundColor(.kadroWarmGray)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.kadroSand)
            }
            .padding(16)
            .background(Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Quick Action Card (square, icon + label)

struct KadroQuickActionCard: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.kadroLime)
                
                Text(title)
                    .font(.kadroChip)
                    .foregroundColor(.kadroCharcoal)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color.kadroSoftWhite)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

// MARK: - Chip

struct KadroChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kadroChip)
                .foregroundColor(isSelected ? .kadroCharcoal : .kadroWarmGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.kadroLime : Color.kadroSoftWhite)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color.kadroSand, lineWidth: 1)
                )
        }
    }
}

// MARK: - Section Header

struct KadroSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionTitle: String = "Все"
    
    var body: some View {
        HStack {
            Text(title)
                .font(.kadroTitle3)
                .foregroundColor(.kadroCharcoal)
            
            Spacer()
            
            if let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.kadroCallout)
                        .foregroundColor(.kadroWarmGray)
                }
            }
        }
    }
}

// MARK: - Status Badge

struct KadroStatusBadge: View {
    let title: String
    let color: Color
    
    var body: some View {
        Text(title)
            .font(.kadroCaption)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - Empty State

struct KadroEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    var buttonTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.kadroSand)
            
            Text(title)
                .font(.kadroTitle3)
                .foregroundColor(.kadroCharcoal)
            
            Text(subtitle)
                .font(.kadroCallout)
                .foregroundColor(.kadroWarmGray)
                .multilineTextAlignment(.center)
            
            if let buttonTitle, let action {
                KadroPrimaryButton(title: buttonTitle, action: action, isFullWidth: false)
                    .padding(.top, 8)
            }
        }
        .padding(40)
    }
}

// MARK: - Generated Image Preview & Download

struct KadroPreviewImageAsset: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String?
    let filenameStem: String
    let imageData: Data
    
    var suggestedFilename: String {
        let trimmed = filenameStem.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitized = trimmed
            .replacingOccurrences(of: "[^\\p{L}\\p{N}]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return (sanitized.isEmpty ? "kadro-image" : sanitized) + ".png"
    }
}

struct KadroPreviewableGeneratedImage: View {
    let asset: KadroPreviewImageAsset
    var cornerRadius: CGFloat = 16
    
    @State private var isPreviewPresented = false
    @State private var isDownloading = false
    #if canImport(UIKit)
    @State private var shareExportFile: KadroGeneratedImageExportFile?
    #endif
    @State private var feedbackTitle = "Готово"
    @State private var feedbackMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                isPreviewPresented = true
            } label: {
                KadroGeneratedImageThumbnail(asset: asset, cornerRadius: cornerRadius)
            }
            .buttonStyle(.plain)
            
            HStack(spacing: 10) {
                imageActionButton(
                    title: "Просмотр",
                    systemImage: "plus.magnifyingglass",
                    action: { isPreviewPresented = true }
                )
                
                #if canImport(UIKit)
                imageActionButton(
                    title: "Экспорт",
                    systemImage: "square.and.arrow.up",
                    action: shareAsset
                )
                #endif
                
                imageActionButton(
                    title: isDownloading ? "Сохраняем..." : "Скачать",
                    systemImage: isDownloading ? "arrow.down.circle.fill" : "arrow.down.to.line",
                    action: { Task { await downloadAsset() } },
                    isDisabled: isDownloading
                )
            }
        }
        .sheet(isPresented: $isPreviewPresented) {
            KadroGeneratedImagePreviewSheet(asset: asset)
        }
        #if canImport(UIKit)
        .sheet(item: $shareExportFile) { file in
            KadroGeneratedImageShareSheet(activityItems: [file.url])
        }
        #endif
        .alert(
            feedbackTitle,
            isPresented: Binding(
                get: { feedbackMessage != nil },
                set: { if !$0 { feedbackMessage = nil } }
            ),
            actions: {
                Button("Ок", role: .cancel) {
                    feedbackMessage = nil
                }
            },
            message: {
                Text(feedbackMessage ?? "")
            }
        )
    }
    
    @ViewBuilder
    private func imageActionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void,
        isDisabled: Bool = false
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.kadroFootnote)
                .foregroundColor(.kadroCharcoal)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.kadroIvory)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
    
    @MainActor
    private func downloadAsset() async {
        guard !isDownloading else { return }
        isDownloading = true
        
        do {
            feedbackMessage = try await KadroGeneratedImageDownloadService.download(asset: asset)
            feedbackTitle = "Сохранено"
        } catch is CancellationError {
            feedbackMessage = nil
        } catch {
            feedbackMessage = error.localizedDescription
            feedbackTitle = "Не удалось скачать"
        }
        
        isDownloading = false
    }
    
    #if canImport(UIKit)
    private func shareAsset() {
        do {
            shareExportFile = try KadroGeneratedImageFileService.temporaryExportFile(for: asset)
        } catch {
            feedbackMessage = error.localizedDescription
            feedbackTitle = "Не удалось открыть экспорт"
        }
    }
    #endif
}

struct KadroGeneratedImagePreviewSheet: View {
    let asset: KadroPreviewImageAsset
    
    @Environment(\.dismiss) private var dismiss
    @State private var isDownloading = false
    #if canImport(UIKit)
    @State private var shareExportFile: KadroGeneratedImageExportFile?
    #endif
    @State private var feedbackTitle = "Готово"
    @State private var feedbackMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.opacity(0.96)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Spacer(minLength: 0)
                    
                    KadroZoomableImageView(imageData: asset.imageData)
                    
                    VStack(spacing: 6) {
                        Text(asset.title)
                            .font(.kadroTitle3)
                            .foregroundColor(.white)
                        if let subtitle = asset.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.kadroCallout)
                                .foregroundColor(.white.opacity(0.72))
                                .multilineTextAlignment(.center)
                        }
                        Text("Щипок или двойной тап для zoom.")
                            .font(.kadroFootnote)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItemGroup(placement: .topBarTrailing) {
                    #if canImport(UIKit)
                    Button {
                        shareAsset()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                    #endif
                    
                    Button {
                        Task { await downloadAsset() }
                    } label: {
                        if isDownloading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.to.line")
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(isDownloading)
                }
            }
        }
        #if canImport(UIKit)
        .sheet(item: $shareExportFile) { file in
            KadroGeneratedImageShareSheet(activityItems: [file.url])
        }
        #endif
        .alert(
            feedbackTitle,
            isPresented: Binding(
                get: { feedbackMessage != nil },
                set: { if !$0 { feedbackMessage = nil } }
            ),
            actions: {
                Button("Ок", role: .cancel) {
                    feedbackMessage = nil
                }
            },
            message: {
                Text(feedbackMessage ?? "")
            }
        )
    }
    
    @MainActor
    private func downloadAsset() async {
        guard !isDownloading else { return }
        isDownloading = true
        
        do {
            feedbackMessage = try await KadroGeneratedImageDownloadService.download(asset: asset)
            feedbackTitle = "Сохранено"
        } catch is CancellationError {
            feedbackMessage = nil
        } catch {
            feedbackMessage = error.localizedDescription
            feedbackTitle = "Не удалось скачать"
        }
        
        isDownloading = false
    }
    
    #if canImport(UIKit)
    private func shareAsset() {
        do {
            shareExportFile = try KadroGeneratedImageFileService.temporaryExportFile(for: asset)
        } catch {
            feedbackMessage = error.localizedDescription
            feedbackTitle = "Не удалось открыть экспорт"
        }
    }
    #endif
}

struct KadroDownloadGeneratedImagesButton<Label: View>: View {
    let assets: [KadroPreviewImageAsset]
    var isDisabled: Bool = false
    let label: (_ isDownloading: Bool) -> Label
    
    @State private var isDownloading = false
    @State private var feedbackTitle = "Готово"
    @State private var feedbackMessage: String?
    
    var body: some View {
        Button {
            Task { await downloadAssets() }
        } label: {
            label(isDownloading)
        }
        .disabled(isDisabled || isDownloading || assets.isEmpty)
        .opacity((isDisabled || isDownloading || assets.isEmpty) ? 0.55 : 1)
        .alert(
            feedbackTitle,
            isPresented: Binding(
                get: { feedbackMessage != nil },
                set: { if !$0 { feedbackMessage = nil } }
            ),
            actions: {
                Button("Ок", role: .cancel) {
                    feedbackMessage = nil
                }
            },
            message: {
                Text(feedbackMessage ?? "")
            }
        )
    }
    
    @MainActor
    private func downloadAssets() async {
        guard !isDownloading, !assets.isEmpty else { return }
        isDownloading = true
        
        do {
            feedbackMessage = try await KadroGeneratedImageDownloadService.download(assets: assets)
            feedbackTitle = "Сохранено"
        } catch is CancellationError {
            feedbackMessage = nil
        } catch {
            feedbackMessage = error.localizedDescription
            feedbackTitle = "Не удалось скачать"
        }
        
        isDownloading = false
    }
}

private struct KadroGeneratedImageThumbnail: View {
    let asset: KadroPreviewImageAsset
    let cornerRadius: CGFloat
    
    var body: some View {
        KadroRenderableImage(imageData: asset.imageData)
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.kadroSand, lineWidth: 1)
            )
    }
}

private struct KadroZoomableImageView: View {
    let imageData: Data
    
    @State private var storedScale: CGFloat = 1
    @GestureState private var pinchScale: CGFloat = 1
    @State private var storedOffset: CGSize = .zero
    @GestureState private var dragOffset: CGSize = .zero
    
    private let minScale: CGFloat = 1
    private let maxScale: CGFloat = 5
    
    private var currentScale: CGFloat {
        clampScale(storedScale * pinchScale)
    }
    
    private var currentOffset: CGSize {
        CGSize(width: storedOffset.width + dragOffset.width, height: storedOffset.height + dragOffset.height)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if KadroRenderableImage.canRender(data: imageData) {
                    KadroRenderableImage(imageData: imageData)
                        .scaledToFit()
                        .scaleEffect(currentScale)
                        .offset(currentOffset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .gesture(dragGesture.simultaneously(with: magnificationGesture))
                        .onTapGesture(count: 2) {
                            toggleZoom()
                        }
                        .animation(.easeInOut(duration: 0.18), value: storedScale)
                        .animation(.easeInOut(duration: 0.18), value: storedOffset)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white.opacity(0.72))
                        Text("Не удалось открыть изображение.")
                            .font(.kadroBody)
                            .foregroundColor(.white.opacity(0.72))
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            )
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .updating($pinchScale) { value, state, _ in
                state = value
            }
            .onEnded { value in
                storedScale = clampScale(storedScale * value)
                if storedScale <= minScale {
                    storedOffset = .zero
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                guard currentScale > minScale else { return }
                state = value.translation
            }
            .onEnded { value in
                guard currentScale > minScale else {
                    storedOffset = .zero
                    return
                }
                storedOffset.width += value.translation.width
                storedOffset.height += value.translation.height
            }
    }
    
    private func toggleZoom() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.88)) {
            if storedScale > minScale {
                storedScale = minScale
                storedOffset = .zero
            } else {
                storedScale = 2.2
            }
        }
    }
    
    private func clampScale(_ value: CGFloat) -> CGFloat {
        min(max(value, minScale), maxScale)
    }
}

private struct KadroRenderableImage: View {
    let imageData: Data
    
    var body: some View {
        Group {
            #if canImport(UIKit)
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                placeholder
            }
            #elseif canImport(AppKit)
            if let image = NSImage(data: imageData) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
            } else {
                placeholder
            }
            #else
            placeholder
            #endif
        }
    }
    
    static func canRender(data: Data) -> Bool {
        #if canImport(UIKit)
        return UIImage(data: data) != nil
        #elseif canImport(AppKit)
        return NSImage(data: data) != nil
        #else
        return false
        #endif
    }
    
    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color.kadroSoftWhite)
            .overlay(
                Image(systemName: "photo")
                    .foregroundColor(.kadroWarmGray)
            )
    }
}

private enum KadroGeneratedImageDownloadService {
    @MainActor
    static func download(asset: KadroPreviewImageAsset) async throws -> String {
        try await download(assets: [asset])
    }
    
    @MainActor
    static func download(assets: [KadroPreviewImageAsset]) async throws -> String {
        guard !assets.isEmpty else {
            throw KadroGeneratedImageDownloadError.noImages
        }
        
        #if canImport(UIKit)
        try await ensurePhotoLibraryAccess()
        let images = try assets.map { asset -> UIImage in
            guard let image = UIImage(data: asset.imageData) else {
                throw KadroGeneratedImageDownloadError.unreadableImage
            }
            return image
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges({
                for image in images {
                    PHAssetCreationRequest.creationRequestForAsset(from: image)
                }
            }, completionHandler: { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            })
        }
        
        return assets.count == 1 ? "Изображение сохранено в Фото." : "Сохранено \(assets.count) изображений в Фото."
        #elseif canImport(AppKit)
        if assets.count == 1 {
            guard let asset = assets.first, let pngData = KadroGeneratedImageFileService.exportData(from: asset.imageData) else {
                throw KadroGeneratedImageDownloadError.unreadableImage
            }
            
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.png]
            panel.nameFieldStringValue = asset.suggestedFilename
            
            guard panel.runModal() == .OK, let url = panel.url else {
                throw CancellationError()
            }
            
            try pngData.write(to: url, options: .atomic)
            return "Изображение сохранено."
        }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Сохранить"
        
        guard panel.runModal() == .OK, let folderURL = panel.url else {
            throw CancellationError()
        }
        
        for asset in assets {
            guard let pngData = KadroGeneratedImageFileService.exportData(from: asset.imageData) else {
                throw KadroGeneratedImageDownloadError.unreadableImage
            }
            
            let fileURL = KadroGeneratedImageFileService.uniqueFileURL(
                in: folderURL,
                preferredFilename: asset.suggestedFilename
            )
            try pngData.write(to: fileURL, options: .atomic)
        }
        
        return "Сохранено \(assets.count) файлов."
        #else
        throw KadroGeneratedImageDownloadError.unsupportedPlatform
        #endif
    }
    
    #if canImport(UIKit)
    @MainActor
    private static func ensurePhotoLibraryAccess() async throws {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch currentStatus {
        case .authorized, .limited:
            return
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard newStatus == .authorized || newStatus == .limited else {
                throw KadroGeneratedImageDownloadError.photoLibraryDenied
            }
        default:
            throw KadroGeneratedImageDownloadError.photoLibraryDenied
        }
    }
    #endif
}

private enum KadroGeneratedImageDownloadError: LocalizedError {
    case noImages
    case unreadableImage
    case photoLibraryDenied
    case unsupportedPlatform
    
    var errorDescription: String? {
        switch self {
        case .noImages:
            return "Пока нет изображений для скачивания."
        case .unreadableImage:
            return "Не удалось подготовить изображение к скачиванию."
        case .photoLibraryDenied:
            return "Разрешите доступ к Фото, чтобы сохранить изображение."
        case .unsupportedPlatform:
            return "Скачивание пока не поддерживается на этом устройстве."
        }
    }
}

private struct KadroGeneratedImageExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

private enum KadroGeneratedImageFileService {
    static func temporaryExportFile(for asset: KadroPreviewImageAsset) throws -> KadroGeneratedImageExportFile {
        guard let data = exportData(from: asset.imageData) else {
            throw KadroGeneratedImageDownloadError.unreadableImage
        }
        
        let exportURL = uniqueFileURL(
            in: FileManager.default.temporaryDirectory,
            preferredFilename: asset.suggestedFilename
        )
        try data.write(to: exportURL, options: .atomic)
        return KadroGeneratedImageExportFile(url: exportURL)
    }
    
    static func uniqueFileURL(in directory: URL, preferredFilename: String) -> URL {
        let sanitized = preferredFilename.isEmpty ? "kadro-image.png" : preferredFilename
        let baseURL = directory.appendingPathComponent(sanitized)
        guard FileManager.default.fileExists(atPath: baseURL.path) else { return baseURL }
        
        let stem = baseURL.deletingPathExtension().lastPathComponent
        let ext = baseURL.pathExtension
        
        for index in 2...999 {
            let candidate = directory.appendingPathComponent("\(stem)-\(index)").appendingPathExtension(ext)
            if !FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        
        return directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
    }
    
    static func exportData(from data: Data) -> Data? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        return image.pngData()
        #elseif canImport(AppKit)
        guard
            let image = NSImage(data: data),
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #else
        return nil
        #endif
    }
}

#if canImport(UIKit)
private struct KadroGeneratedImageShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

// MARK: - Previews

#Preview("Components") {
    ScrollView {
        VStack(spacing: 24) {
            KadroPrimaryButton(title: "Создать контент") {}
            
            KadroSecondaryButton(title: "Отмена") {}
            
            KadroCard {
                Text("Заголовок карточки")
                    .font(.kadroTitle3)
                Text("Описание")
                    .font(.kadroCallout)
                    .foregroundColor(.kadroWarmGray)
            }
            
            KadroActionCard(
                icon: "doc.text",
                title: "Instagram Пост",
                subtitle: "Текст с хуком и CTA"
            ) {}
            
            HStack(spacing: 12) {
                KadroQuickActionCard(icon: "text.quote", title: "Пост") {}
                KadroQuickActionCard(icon: "rectangle.split.3x1", title: "Карусель") {}
                KadroQuickActionCard(icon: "video", title: "Reels") {}
            }
            
            HStack(spacing: 8) {
                KadroChip(title: "Обучающий", isSelected: true) {}
                KadroChip(title: "Личный", isSelected: false) {}
                KadroChip(title: "Продающий", isSelected: false) {}
            }
            
            KadroSectionHeader(title: "Последние черновики") {}
            
            HStack(spacing: 8) {
                KadroStatusBadge(title: "Черновик", color: .kadroWarmGray)
                KadroStatusBadge(title: "Готово", color: .kadroSuccess)
                KadroStatusBadge(title: "Запланировано", color: .kadroLime)
            }
            
            KadroEmptyState(
                icon: "doc.text.magnifyingglass",
                title: "Пока пусто",
                subtitle: "Ваши черновики появятся здесь",
                buttonTitle: "Создать первый"
            ) {}
        }
        .padding()
    }
    .background(Color.kadroIvory)
}
