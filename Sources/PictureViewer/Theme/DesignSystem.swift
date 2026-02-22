import SwiftUI

/// Sketchbook design system — pastel tones, line icons, hand-drawn aesthetic.
///
/// Color distribution follows the **60 : 30 : 10** rule:
/// - **60 % Dominant** — warm cream surfaces (backgrounds, cards, gallery)
/// - **30 % Secondary** — soft blue tones (header, control surfaces, placeholders, borders)
/// - **10 % Accent**   — soft lavender pops (CTA buttons, hover glow, active states)
enum DesignSystem {

  // MARK: - 60 % Dominant (warm cream)

  /// Main page background, gallery scroll area, card surfaces.
  static let background = Color(hex: 0xFDF6E3)  // warm cream

  // MARK: - 30 % Secondary (soft blue family)

  /// Header bar, control pill backgrounds, placeholder fills.
  static let primary = Color(hex: 0xB8D4E3)  // soft blue
  /// Structural borders, dividers, card outlines at rest.
  static let border = Color(hex: 0xE0D5C1)  // pencil gray
  /// Header bar fill — deepened blue-tinted cream for clear separation from gallery.
  static let headerBackground = Color(hex: 0xD8E6F0)  // soft blue wash (was EAF0F5)

  /// Header gradient stops — paper-gray to creamy warm, multi-point.
  static let headerGradientStops: [Gradient.Stop] = [
    .init(color: Color(hex: 0xD8D3CB), location: 0.0),  // paper gray
    .init(color: Color(hex: 0xE2DCD2), location: 0.25),  // warm gray
    .init(color: Color(hex: 0xF3F0DE), location: 0.5),  // warm parchment
    .init(color: Color(hex: 0xF8F2E4), location: 0.75),  // soft cream
    .init(color: Color(hex: 0xFDF6E3), location: 1.0),  // warm cream
  ]
  /// Slideshow control pill background.
  static let controlSurface = Color(hex: 0xE8EEF3)  // soft blue-gray

  // MARK: - 10 % Accent (soft lavender)

  /// CTA buttons (play), hover glow, selected/active states.
  static let accent = Color(hex: 0xC9B1FF)  // soft lavender
  /// Accent button fill — slightly stronger for primary actions.
  static let accentSurface = Color(hex: 0xDDD0FF)  // light lavender fill
  /// Slideshow CTA button — dark cyan for strong contrast against the pastel header.
  static let slideshowButton = Color(hex: 0x008B8B)  // dark cyan

  // MARK: - Semantic Colors

  /// Error and warning indicators.
  static let secondary = Color(hex: 0xF5CAC3)  // soft coral
  /// Body text, icon strokes.
  static let textColor = Color(hex: 0x5C5C5C)  // soft charcoal
  /// Gallery header title.
  static let headerTitle = Color(hex: 0xFF8C00)  // dark orange
  /// Slideshow filename label — dark cyan to match slideshow controls.
  static let slideshowFilename = Color(hex: 0x008B8B)  // dark cyan

  // MARK: - Slideshow Gradient (paper-gray to warm cream, multi-stop)

  static let slideshowGradientStops: [Gradient.Stop] = [
    .init(color: Color(hex: 0xD8D3CB), location: 0.0),  // paper gray
    .init(color: Color(hex: 0xE2DCD2), location: 0.2),  // warm gray
    .init(color: Color(hex: 0xEDE7DB), location: 0.4),  // parchment
    .init(color: Color(hex: 0xF3EDE1), location: 0.6),  // light cream
    .init(color: Color(hex: 0xF8F2E6), location: 0.8),  // soft cream
    .init(color: Color(hex: 0xFDF6E3), location: 1.0),  // warm cream (matches background)
  ]

  // MARK: - Glow Moods (slideshow tinted overlays — 30 % role)

  static let glowMoods: [Color] = [
    Color(hex: 0xB8D4E3).opacity(0.25),  // blue
    Color(hex: 0xF5CAC3).opacity(0.2),  // coral
    Color(hex: 0xC9B1FF).opacity(0.2),  // lavender
    Color(hex: 0xD4E8B8).opacity(0.2),  // sage
  ]

  // MARK: - Typography

  static let headerFont = Font.custom("Gamja Flower", size: 28)
  static let bodyFont = Font.system(size: 14, weight: .regular, design: .rounded)
  static let captionFont = Font.system(size: 12, weight: .regular, design: .rounded)
  static let captionSemiboldFont = Font.system(size: 12, weight: .semibold, design: .rounded)

  // Fallback if Gamja Flower unavailable
  static let headerFontFallback = Font.system(size: 28, weight: .bold, design: .rounded)

  // MARK: - Sketchbook Tape Colors (pastel washi-tape strips)

  /// Cycling tape colors for thumbnail frame decorations.
  static let tapeColors: [Color] = [
    Color(hex: 0xB8D4E3).opacity(0.55),  // soft blue
    Color(hex: 0xF5CAC3).opacity(0.55),  // soft coral
    Color(hex: 0xC9B1FF).opacity(0.50),  // soft lavender
    Color(hex: 0xD4E8B8).opacity(0.55),  // soft sage
    Color(hex: 0xF5E6A3).opacity(0.55),  // soft gold
    Color(hex: 0xFFD6E0).opacity(0.50),  // soft pink
  ]

  // MARK: - Dimensions

  static let thumbnailSize: CGFloat = 180
  static let gridSpacing: CGFloat = 16
  static let cornerRadius: CGFloat = 8
  static let iconStrokeWidth: CGFloat = 1.5
  static let iconSize: CGFloat = 24

  // MARK: - Animation

  static let slideshowInterval: TimeInterval = 5.0
  static let flipDuration: TimeInterval = 1.0
  static let bendDuration: TimeInterval = 1.2
  static let curlDuration: TimeInterval = 1.1
  /// Realistic book page turn — slightly longer for a natural, unhurried feel.
  static let bookDuration: TimeInterval = 1.0
  /// Total wall-clock time for the blocks transition (per-block fade + max stagger).
  static let blocksDuration: TimeInterval = 1.2
  /// How long each individual block takes to fade out.
  static let blocksBlockFade: TimeInterval = 0.35
  /// Target block edge size in points — the grid adapts to the image rect.
  static let blocksEdge: CGFloat = 100

  // MARK: - Speedy Mode

  static let speedySlideshowInterval: TimeInterval = 2.0
  static let speedyFlipDuration: TimeInterval = 0.5
  static let speedyBendDuration: TimeInterval = 0.6
  static let speedyCurlDuration: TimeInterval = 0.55
  static let speedyBookDuration: TimeInterval = 0.5
  static let speedyBlocksDuration: TimeInterval = 0.6
}

// MARK: - Color Hex Extension

extension Color {
  init(hex: UInt, alpha: Double = 1.0) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255.0,
      green: Double((hex >> 8) & 0xFF) / 255.0,
      blue: Double(hex & 0xFF) / 255.0,
      opacity: alpha
    )
  }
}
