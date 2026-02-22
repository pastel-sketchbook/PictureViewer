import SwiftUI

/// Top header bar with title, image count, and play button.
///
/// 60:30:10 — header background is **30 %** (blue-tinted cream),
/// play button is **10 %** (accent lavender).
struct HeaderView: View {
  let imageCount: Int
  let onPlaySlideshow: () -> Void

  /// App version from the main bundle's Info.plist.
  private var appVersion: String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
  }

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text("Picture Viewer")
            .font(DesignSystem.headerFont)
            .foregroundColor(DesignSystem.headerTitle)

          Text("v\(appVersion)")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(DesignSystem.slideshowButton)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
              Capsule().fill(DesignSystem.slideshowButton.opacity(0.12))
            )
        }

        if imageCount > 0 {
          Text("\(imageCount) pictures")
            .font(DesignSystem.captionSemiboldFont)
            .foregroundColor(DesignSystem.textColor.opacity(0.85))
        }
      }

      Spacer()

      if imageCount > 0 {
        Button(action: onPlaySlideshow) {
          HStack(spacing: 6) {
            PlayIcon()
              .filledIconStyle(color: .white, size: 12)
            Text("Slideshow")
              .font(DesignSystem.bodyFont)
          }
          .foregroundColor(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: DesignSystem.cornerRadius)
              .fill(DesignSystem.slideshowButton)
          )
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 24)
    .padding(.vertical, 16)
    .background(
      LinearGradient(
        stops: DesignSystem.headerGradientStops,
        startPoint: .leading,
        endPoint: .trailing
      )
    )
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(DesignSystem.border.opacity(0.5))
        .frame(height: 1)
    }
    .shadow(color: DesignSystem.border.opacity(0.2), radius: 4, x: 0, y: 2)
  }
}
