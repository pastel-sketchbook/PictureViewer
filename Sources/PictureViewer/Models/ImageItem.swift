import AppKit
import Foundation

/// A single image discovered in the Pictures folder.
struct ImageItem: Identifiable, Hashable {
  let id: UUID
  let url: URL
  let filename: String
  let fileSize: Int64
  let modificationDate: Date

  init(url: URL, fileSize: Int64 = 0, modificationDate: Date = .now) {
    self.id = UUID()
    self.url = url
    self.filename = url.lastPathComponent
    self.fileSize = fileSize
    self.modificationDate = modificationDate
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(url)
  }

  static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
    lhs.url == rhs.url
  }
}

/// The animation types that cycle during slideshow transitions.
///
/// `flip`, `bend`, and `curl` are single-effect transitions.
/// `book` is a realistic page turn — `pageCurl` going forward, `pageUnCurl` going
/// backward — with a natural timing curve that mimics lifting a real page corner.
enum SlideAnimationType: CaseIterable {
  case flip
  case bend
  case curl
  case book
}
