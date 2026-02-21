import AppKit
import Foundation
import SwiftUI

/// Scans the user's Pictures folder for images and provides thumbnail generation.
@MainActor
final class ImageStore: ObservableObject {

  @Published var images: [ImageItem] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private static nonisolated let supportedExtensions: Set<String> = [
    "jpg", "jpeg", "png", "gif", "webp", "bmp", "tiff", "tif", "heic", "heif",
  ]

  private var thumbnailCache: [URL: NSImage] = [:]

  // MARK: - Public API

  func loadImages() async {
    isLoading = true
    errorMessage = nil

    do {
      let picturesURL = try picturesDirectory()
      let items = try await scanDirectory(picturesURL)
      images = items.sorted { $0.modificationDate > $1.modificationDate }
    } catch {
      errorMessage = "Failed to load images: \(error.localizedDescription)"
    }

    isLoading = false
  }

  /// Returns a cached thumbnail or generates one on demand.
  func thumbnail(for item: ImageItem, size: CGFloat = DesignSystem.thumbnailSize) -> NSImage? {
    if let cached = thumbnailCache[item.url] {
      return cached
    }

    guard let image = NSImage(contentsOf: item.url) else { return nil }

    let thumb = image.resized(to: NSSize(width: size, height: size))
    thumbnailCache[item.url] = thumb
    return thumb
  }

  /// Loads the full-size image for a given item.
  func fullImage(for item: ImageItem) -> NSImage? {
    NSImage(contentsOf: item.url)
  }

  /// Remove an image from the store (e.g. after trashing).
  ///
  /// Also evicts the thumbnail cache entry so memory is freed.
  func removeImage(_ item: ImageItem) {
    images.removeAll { $0.url == item.url }
    thumbnailCache.removeValue(forKey: item.url)
  }

  // MARK: - Private

  private func picturesDirectory() throws -> URL {
    let fileManager = FileManager.default
    let url = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first
    guard let picturesURL = url, fileManager.fileExists(atPath: picturesURL.path) else {
      throw ImageStoreError.picturesNotFound
    }
    return picturesURL
  }

  private func scanDirectory(_ root: URL) async throws -> [ImageItem] {
    try await withCheckedThrowingContinuation { continuation in
      DispatchQueue.global(qos: .userInitiated).async {
        var results: [ImageItem] = []
        let fileManager = FileManager.default

        guard
          let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [
              .fileSizeKey, .contentModificationDateKey, .isRegularFileKey,
            ],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
          )
        else {
          continuation.resume(returning: [])
          return
        }

        for case let fileURL as URL in enumerator {
          let ext = fileURL.pathExtension.lowercased()
          guard Self.supportedExtensions.contains(ext) else { continue }

          do {
            let values = try fileURL.resourceValues(
              forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey]
            )
            guard values.isRegularFile == true else { continue }

            let item = ImageItem(
              url: fileURL,
              fileSize: Int64(values.fileSize ?? 0),
              modificationDate: values.contentModificationDate ?? .distantPast
            )
            results.append(item)
          } catch {
            // Skip files we can't read metadata for
            continue
          }
        }

        continuation.resume(returning: results)
      }
    }
  }
}

// MARK: - Errors

enum ImageStoreError: LocalizedError {
  case picturesNotFound

  var errorDescription: String? {
    switch self {
    case .picturesNotFound:
      return "Could not locate the Pictures folder."
    }
  }
}

// MARK: - NSImage Resize

extension NSImage {
  func resized(to targetSize: NSSize) -> NSImage {
    let aspectWidth = targetSize.width / size.width
    let aspectHeight = targetSize.height / size.height
    let scale = min(aspectWidth, aspectHeight)
    let newSize = NSSize(
      width: size.width * scale,
      height: size.height * scale
    )

    let newImage = NSImage(size: newSize)
    newImage.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    draw(
      in: NSRect(origin: .zero, size: newSize),
      from: NSRect(origin: .zero, size: size),
      operation: .copy,
      fraction: 1.0
    )
    newImage.unlockFocus()
    return newImage
  }
}
