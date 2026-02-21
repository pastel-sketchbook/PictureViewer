import SwiftUI

/// Capsule-shaped control bar — close, left, play, stop, right, speed, delete.
///
/// All icons are line-only to match the sketchbook aesthetic.
struct SlideshowControlBar: View {
  let filename: String
  let isPlaying: Bool
  let isSpeedy: Bool
  let onClose: () -> Void
  let onPrev: () -> Void
  let onNext: () -> Void
  let onPlay: () -> Void
  let onStop: () -> Void
  let onToggleSpeed: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 24) {
      // Close (back to gallery)
      controlButton(action: onClose) {
        CloseIcon()
          .lineIconStyle(color: DesignSystem.textColor, size: 18)
      }

      // Divider
      Rectangle()
        .fill(DesignSystem.border)
        .frame(width: 1, height: 24)

      // Filename
      Text(filename)
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundColor(DesignSystem.slideshowFilename)
        .lineLimit(1)
        .truncationMode(.middle)
        .frame(maxWidth: 200)

      // Divider
      Rectangle()
        .fill(DesignSystem.border)
        .frame(width: 1, height: 24)

      // Previous
      controlButton(action: onPrev) {
        ChevronLeftIcon()
          .lineIconStyle(color: DesignSystem.textColor, size: 18)
      }

      // Play
      controlButton(
        action: onPlay,
        icon: {
          let color =
            isPlaying
            ? DesignSystem.textColor.opacity(0.4)
            : DesignSystem.textColor
          PlayIcon()
            .lineIconStyle(color: color, size: 18)
        }
      )

      // Stop
      controlButton(
        action: onStop,
        icon: {
          let color =
            isPlaying
            ? DesignSystem.textColor
            : DesignSystem.textColor.opacity(0.4)
          StopIcon()
            .lineIconStyle(color: color, size: 18)
        }
      )

      // Next
      controlButton(action: onNext) {
        ChevronRightIcon()
          .lineIconStyle(color: DesignSystem.textColor, size: 18)
      }

      // Divider
      Rectangle()
        .fill(DesignSystem.border)
        .frame(width: 1, height: 24)

      // Speed toggle
      controlButton(action: onToggleSpeed) {
        SpeedIcon()
          .lineIconStyle(
            color: isSpeedy ? DesignSystem.slideshowButton : DesignSystem.textColor.opacity(0.4),
            size: 18
          )
      }

      // Delete
      controlButton(action: onDelete) {
        TrashIcon()
          .lineIconStyle(color: DesignSystem.secondary, size: 18)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .background(
      Capsule().fill(DesignSystem.controlSurface)
        .shadow(color: DesignSystem.border.opacity(0.4), radius: 6, y: 3)
    )
  }

  /// Consistent circular hit-target for control buttons.
  private func controlButton<Icon: View>(
    action: @escaping () -> Void,
    @ViewBuilder icon: () -> Icon
  ) -> some View {
    Button(action: action) {
      icon()
        .frame(width: 36, height: 36)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
  }
}
