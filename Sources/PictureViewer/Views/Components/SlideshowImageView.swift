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

  func makeNSView(context: Context) -> SlideshowContainerView {
    let container = SlideshowContainerView()
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

  func updateNSView(_ nsView: SlideshowContainerView, context: Context) {
    guard let rootLayer = nsView.layer,
      let imageLayer = rootLayer.sublayers?.first(where: { $0.name == "imageLayer" })
    else { return }

    guard let newImage = image else {
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      nsView.currentImageSize = .zero
      imageLayer.frame = rootLayer.bounds
      imageLayer.contents = nil
      CATransaction.commit()
      return
    }

    // Store image size so layout() can recalculate on container resize
    nsView.currentImageSize = newImage.size

    // Only animate if there was a previous image (not first load)
    let hadPreviousImage = imageLayer.contents != nil

    if hadPreviousImage, animationType == .blocks {
      // Blocks transition — custom grid of tiles that fade out
      let oldCGImage = imageLayer.contents
      let fittedRect = nsView.fittedImageRect

      // Set new image immediately (hidden under the old-image tiles)
      CATransaction.begin()
      CATransaction.setDisableActions(true)
      imageLayer.frame = fittedRect
      imageLayer.contents = newImage.asCGImage
      CATransaction.commit()

      // Overlay old-image tiles and fade them out
      performBlocksTransition(
        oldImage: oldCGImage, on: imageLayer, in: fittedRect)
      return
    }

    if hadPreviousImage {
      let transition = CATransition()
      transition.duration = transitionDuration
      transition.timingFunction = timingFunction
      transition.type = caTransitionType
      transition.subtype = caTransitionSubtype
      transition.isRemovedOnCompletion = true

      imageLayer.add(transition, forKey: "slideTransition")
    }

    // Size the image layer to the aspect-fitted rect so curl/flip
    // transitions match the visible image bounds — not the full container.
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    imageLayer.frame = nsView.fittedImageRect
    CATransaction.commit()

    imageLayer.contents = newImage.asCGImage
  }

  private var transitionDuration: CFTimeInterval {
    switch animationType {
    case .flip: return DesignSystem.flipDuration
    case .bend: return DesignSystem.bendDuration
    case .curl: return DesignSystem.curlDuration
    case .book: return DesignSystem.bookDuration
    case .blocks: return DesignSystem.blocksDuration
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
    case .flip, .bend, .curl, .blocks:
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
      return isForward
        ? CATransitionType(rawValue: "pageCurl")
        : CATransitionType(rawValue: "pageUnCurl")
    case .blocks:
      // Not used — blocks transition is handled separately
      return .fade
    }
  }

  /// Direction subtype — book mode flips the subtype for backward navigation
  /// so the curl originates from the correct edge.
  private var caTransitionSubtype: CATransitionSubtype {
    switch animationType {
    case .book:
      return isForward ? .fromRight : .fromLeft
    case .flip, .bend, .curl, .blocks:
      return .fromRight
    }
  }
}

// MARK: - Blocks (mosaic dissolve) transition

extension SlideshowImageView {

  /// Overlay a grid of tiles showing the old image, then fade each tile out
  /// with staggered random delays to reveal the new image underneath.
  ///
  /// All animations run on the Core Animation compositor — zero main-thread work.
  func performBlocksTransition(
    oldImage: Any?, on imageLayer: CALayer, in rect: CGRect
  ) {
    // Remove any leftover tiles from a previous blocks transition
    if let tiles = imageLayer.sublayers?.filter({ $0.name == "blockTile" }) {
      for tile in tiles { tile.removeFromSuperlayer() }
    }

    guard let cgImage = oldImage else { return }

    let edge = DesignSystem.blocksEdge
    let cols = max(1, Int(ceil(rect.width / edge)))
    let rows = max(1, Int(ceil(rect.height / edge)))
    let tileW = rect.width / CGFloat(cols)
    let tileH = rect.height / CGFloat(rows)

    let totalDuration = DesignSystem.blocksDuration
    let fadeDuration = DesignSystem.blocksBlockFade
    let maxDelay = totalDuration - fadeDuration

    for row in 0..<rows {
      for col in 0..<cols {
        let tile = CALayer()
        tile.name = "blockTile"
        // Position relative to the imageLayer (origin 0,0)
        tile.frame = CGRect(
          x: CGFloat(col) * tileW,
          y: CGFloat(row) * tileH,
          width: tileW,
          height: tileH
        )
        tile.contents = cgImage
        tile.contentsGravity = .resizeAspect

        // Map this tile's rect to a normalized contentsRect (0..1)
        tile.contentsRect = CGRect(
          x: CGFloat(col) / CGFloat(cols),
          y: CGFloat(row) / CGFloat(rows),
          width: 1.0 / CGFloat(cols),
          height: 1.0 / CGFloat(rows)
        )

        tile.masksToBounds = true
        imageLayer.addSublayer(tile)

        // Staggered fade-out — random delay per tile
        let delay = Double.random(in: 0...maxDelay)
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1.0
        fade.toValue = 0.0
        fade.beginTime = CACurrentMediaTime() + delay
        fade.duration = fadeDuration
        fade.timingFunction = CAMediaTimingFunction(name: .easeIn)
        fade.fillMode = .forwards
        fade.isRemovedOnCompletion = false
        tile.add(fade, forKey: "blockFade")
      }
    }

    // Clean up tiles after the full transition completes
    DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.05) {
      if let tiles = imageLayer.sublayers?.filter({ $0.name == "blockTile" }) {
        for tile in tiles { tile.removeFromSuperlayer() }
      }
    }
  }
}

// MARK: - Container view with aspect-fit layout

/// Custom container that keeps the image layer sized to the aspect-fitted rect.
///
/// On window resize, `layout()` recalculates the fitted rect so the image layer
/// (and its curl/flip transitions) always matches the visible image bounds.
class SlideshowContainerView: NSView {
  var currentImageSize: CGSize = .zero

  override func layout() {
    super.layout()
    guard let imageLayer = layer?.sublayers?.first(where: { $0.name == "imageLayer" })
    else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    imageLayer.frame = fittedImageRect
    CATransaction.commit()
  }

  /// The aspect-fitted rect for the current image within this view's bounds.
  var fittedImageRect: CGRect {
    guard currentImageSize.width > 0, currentImageSize.height > 0,
      bounds.width > 0, bounds.height > 0
    else { return bounds }

    let imageAspect = currentImageSize.width / currentImageSize.height
    let containerAspect = bounds.width / bounds.height

    if imageAspect > containerAspect {
      // Wider image — letterboxed top/bottom
      let width = bounds.width
      let height = width / imageAspect
      let originY = (bounds.height - height) / 2
      return CGRect(x: 0, y: originY, width: width, height: height)
    } else {
      // Taller image — pillarboxed left/right
      let height = bounds.height
      let width = height * imageAspect
      let originX = (bounds.width - width) / 2
      return CGRect(x: originX, y: 0, width: width, height: height)
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
