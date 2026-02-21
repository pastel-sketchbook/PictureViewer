import AppKit
import SwiftUI

/// NSViewRepresentable that uses CATransition for GPU-composited page transitions.
///
/// This is where the magic happens. CATransition types like `pageCurl` and `oglFlip`
/// are rendered entirely by Core Animation on the GPU — no CPU compositing, no jank.
///
/// The `book` animation type uses direction-aware transitions:
/// - Forward: `pageCurl` from the right edge (lifting the current page)
/// - Backward: `pageUnCurl` from the left edge (laying a page back down)
/// This mimics the natural feel of turning a real book page.
struct SlideshowImageView: NSViewRepresentable {
  let image: NSImage?
  let animationType: SlideAnimationType
  let isForward: Bool
  @Binding var isAnimating: Bool

  func makeNSView(context: Context) -> NSView {
    let container = NSView()
    container.wantsLayer = true
    container.layer?.backgroundColor = NSColor.clear.cgColor

    let imageLayer = CALayer()
    imageLayer.name = "imageLayer"
    imageLayer.contentsGravity = .resizeAspect
    imageLayer.backgroundColor = NSColor.clear.cgColor

    // Pastel shadow — soft warm tone matching the sketchbook aesthetic
    imageLayer.shadowColor = NSColor(red: 0.72, green: 0.66, blue: 0.58, alpha: 1.0).cgColor
    imageLayer.shadowOpacity = 0.5
    imageLayer.shadowOffset = CGSize(width: 0, height: -6)
    imageLayer.shadowRadius = 16

    container.layer?.addSublayer(imageLayer)

    return container
  }

  func updateNSView(_ nsView: NSView, context: Context) {
    guard let rootLayer = nsView.layer,
      let imageLayer = rootLayer.sublayers?.first(where: { $0.name == "imageLayer" })
    else { return }

    // Resize the image layer to fill the container
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    imageLayer.frame = rootLayer.bounds
    CATransaction.commit()

    guard let newImage = image else {
      imageLayer.contents = nil
      return
    }

    // Only animate if there was a previous image (not first load)
    let hadPreviousImage = imageLayer.contents != nil

    if hadPreviousImage {
      let transition = CATransition()
      transition.duration = transitionDuration
      transition.timingFunction = timingFunction
      transition.type = caTransitionType
      transition.subtype = caTransitionSubtype
      transition.isRemovedOnCompletion = true

      imageLayer.add(transition, forKey: "slideTransition")
    }

    imageLayer.contents = newImage.asCGImage
  }

  private var transitionDuration: CFTimeInterval {
    switch animationType {
    case .flip: return DesignSystem.flipDuration
    case .bend: return DesignSystem.bendDuration
    case .curl: return DesignSystem.curlDuration
    case .book: return DesignSystem.bookDuration
    }
  }

  /// Timing curve per animation type.
  ///
  /// The `book` type uses a custom curve tuned for natural page-turn feel:
  /// slow pickup at the corner (0.4), gentle lift (0.0), smooth swing (0.2),
  /// soft settle onto the opposite page (1.0).
  private var timingFunction: CAMediaTimingFunction {
    switch animationType {
    case .book:
      // Natural page turn: slow lift → smooth swing → gentle settle
      return CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)
    case .flip, .bend, .curl:
      return CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
    }
  }

  private var caTransitionType: CATransitionType {
    switch animationType {
    case .flip:
      return CATransitionType(rawValue: "oglFlip")
    case .bend:
      return CATransitionType(rawValue: "pageCurl")
    case .curl:
      return CATransitionType(rawValue: "pageUnCurl")
    case .book:
      // Forward → page curls up from the right (turning to next page)
      // Backward → page uncurls back from the left (turning to previous page)
      return isForward
        ? CATransitionType(rawValue: "pageCurl")
        : CATransitionType(rawValue: "pageUnCurl")
    }
  }

  /// Direction subtype — book mode flips the subtype for backward navigation
  /// so the curl originates from the correct edge.
  private var caTransitionSubtype: CATransitionSubtype {
    switch animationType {
    case .book:
      return isForward ? .fromRight : .fromLeft
    case .flip, .bend, .curl:
      return .fromRight
    }
  }
}

// MARK: - NSImage CGImage helper

extension NSImage {
  /// Convenience to get a CGImage without needing to manage an inout rect.
  var asCGImage: CGImage? {
    var rect = NSRect(origin: .zero, size: size)
    return cgImage(forProposedRect: &rect, context: nil, hints: nil)
  }
}
