import AppKit
import SwiftUI

/// Fullscreen slideshow with Core Animation page-turn transitions.
///
/// Uses `CATransition` for GPU-composited flip, curl, and bend effects.
/// This is the primary motivation for the Swift rewrite — these transitions
/// run on the Core Animation compositor thread with zero jank, unlike the
/// web-based CSS/WAAPI approach in the Tauri version.
struct SlideshowView: View {
  let startingImage: ImageItem
  let autoPlay: Bool
  let onDismiss: () -> Void

  @EnvironmentObject private var imageStore: ImageStore
  @State private var currentIndex: Int = 0
  @State private var isPlaying = false
  @State private var isAnimating = false
  @State private var animCycleIdx = 0
  @State private var glowCycleIdx = 0
  @State private var navigatingForward = true
  @State private var currentNSImage: NSImage?
  @State private var isSpeedy = false

  // Timer for auto-advance
  @State private var slideTimer: Timer?

  var body: some View {
    ZStack {
      // Glow background
      glowBackground
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 1.2), value: glowCycleIdx)

      // Main content — image + filename + controls
      VStack(spacing: 0) {
        // Top bar — close and counter
        topBar

        Spacer(minLength: 8)

        // Image — sketchbook frame with tape strips
        slideshowFrame

        Spacer(minLength: 32)

        // Bottom control bar
        controlBar
          .padding(.bottom, 20)
      }
      .padding(.vertical, 12)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      LinearGradient(
        stops: DesignSystem.slideshowGradientStops,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .onAppear {
      setupInitialState()
    }
    .onDisappear {
      stopAutoPlay()
    }
    // Keyboard navigation
    .onKeyPress(.leftArrow) {
      navigatePrev()
      return .handled
    }
    .onKeyPress(.rightArrow) {
      navigateNext()
      return .handled
    }
    .onKeyPress(.space) {
      togglePlayPause()
      return .handled
    }
    .onKeyPress(.escape) {
      onDismiss()
      return .handled
    }
  }

  // MARK: - Subviews

  private var glowBackground: some View {
    let idx = glowCycleIdx % DesignSystem.glowMoods.count
    return Rectangle()
      .fill(
        RadialGradient(
          colors: [DesignSystem.glowMoods[idx], Color.clear],
          center: .center,
          startRadius: 100,
          endRadius: 600
        )
      )
  }

  /// Sketchbook-style image — washi-tape strips stuck directly onto the picture.
  private var slideshowFrame: some View {
    SlideshowImageView(
      image: currentNSImage,
      animationType: currentAnimationType,
      isForward: navigatingForward,
      isAnimating: $isAnimating
    )
    // Tape strips — large, stuck directly on picture edges
    .overlay(alignment: .top) {
      TapeStrip(color: slideshowTopTape)
        .scaleEffect(2.4)
        .rotationEffect(.degrees(-7))
        .offset(y: -4)
    }
    .overlay(alignment: .bottomTrailing) {
      TapeStrip(color: slideshowBottomTape)
        .scaleEffect(2.4)
        .rotationEffect(.degrees(11))
        .offset(x: -80, y: -10)
    }
    .padding(.horizontal, 60)
  }

  /// Tape color cycling per slide for variety.
  private var slideshowTopTape: Color {
    DesignSystem.tapeColors[currentIndex % DesignSystem.tapeColors.count]
  }

  private var slideshowBottomTape: Color {
    DesignSystem.tapeColors[(currentIndex + 3) % DesignSystem.tapeColors.count]
  }

  /// Top bar — counter pill (right-aligned).
  private var topBar: some View {
    HStack {
      Spacer()

      Text("\(currentIndex + 1) / \(imageStore.images.count)")
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundColor(DesignSystem.slideshowButton)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(
          Capsule().fill(DesignSystem.controlSurface)
            .shadow(color: DesignSystem.border.opacity(0.3), radius: 3, y: 1)
        )
    }
    .padding(.horizontal, 20)
  }

  /// Bottom control bar — close, left, play, stop, right, speed, delete.
  private var controlBar: some View {
    SlideshowControlBar(
      filename: currentFilename,
      isPlaying: isPlaying,
      isSpeedy: isSpeedy,
      onClose: onDismiss,
      onPrev: navigatePrev,
      onNext: navigateNext,
      onPlay: { if !isPlaying { startAutoPlay() } },
      onStop: { if isPlaying { stopAutoPlay() } },
      onToggleSpeed: toggleSpeedyMode,
      onDelete: deleteCurrentImage
    )
  }

  // MARK: - State

  private var currentAnimationType: SlideAnimationType {
    SlideAnimationType.allCases[animCycleIdx % SlideAnimationType.allCases.count]
  }

  /// Current image filename for display.
  private var currentFilename: String {
    guard currentIndex >= 0, currentIndex < imageStore.images.count else { return "" }
    return imageStore.images[currentIndex].filename
  }

  private func setupInitialState() {
    if let idx = imageStore.images.firstIndex(where: { $0.id == startingImage.id }) {
      currentIndex = idx
    }
    currentNSImage = imageStore.fullImage(for: imageStore.images[currentIndex])

    if autoPlay {
      startAutoPlay()
    }
  }

  // MARK: - Navigation

  private func navigateNext() {
    guard !isAnimating else { return }
    navigatingForward = true
    let nextIndex = (currentIndex + 1) % imageStore.images.count
    advanceSlide(to: nextIndex)
    if isPlaying {
      restartAutoPlayTimer()
    }
  }

  private func navigatePrev() {
    guard !isAnimating else { return }
    navigatingForward = false
    let prevIndex = (currentIndex - 1 + imageStore.images.count) % imageStore.images.count
    advanceSlide(to: prevIndex)
    if isPlaying {
      restartAutoPlayTimer()
    }
  }

  private func advanceSlide(to targetIndex: Int) {
    guard !isAnimating else { return }
    isAnimating = true

    // Preload the target image
    let targetImage = imageStore.fullImage(for: imageStore.images[targetIndex])

    // The SlideshowImageView handles the Core Animation transition.
    // We update state which triggers the CA transition in the NSView.
    currentIndex = targetIndex
    currentNSImage = targetImage
    animCycleIdx += 1
    glowCycleIdx += 1

    // Reset animation flag after transition completes
    DispatchQueue.main.asyncAfter(deadline: .now() + currentTransitionDuration) {
      isAnimating = false
    }
  }

  private var currentTransitionDuration: TimeInterval {
    if isSpeedy {
      switch currentAnimationType {
      case .flip: return DesignSystem.speedyFlipDuration
      case .bend: return DesignSystem.speedyBendDuration
      case .curl: return DesignSystem.speedyCurlDuration
      case .book: return DesignSystem.speedyBookDuration
      }
    } else {
      switch currentAnimationType {
      case .flip: return DesignSystem.flipDuration
      case .bend: return DesignSystem.bendDuration
      case .curl: return DesignSystem.curlDuration
      case .book: return DesignSystem.bookDuration
      }
    }
  }

  // MARK: - Auto-play

  private func togglePlayPause() {
    if isPlaying {
      stopAutoPlay()
    } else {
      startAutoPlay()
    }
  }

  private func startAutoPlay() {
    isPlaying = true
    restartAutoPlayTimer()
  }

  private func stopAutoPlay() {
    isPlaying = false
    slideTimer?.invalidate()
    slideTimer = nil
  }

  private func restartAutoPlayTimer() {
    slideTimer?.invalidate()
    let interval =
      isSpeedy
      ? DesignSystem.speedySlideshowInterval
      : DesignSystem.slideshowInterval
    slideTimer = Timer.scheduledTimer(
      withTimeInterval: interval,
      repeats: true
    ) { _ in
      Task { @MainActor in
        navigateNext()
      }
    }
  }

  private func toggleSpeedyMode() {
    isSpeedy.toggle()
    if isPlaying {
      restartAutoPlayTimer()
    }
  }
}

// MARK: - Auto-play & Delete

extension SlideshowView {

  /// Move the current image to Trash via FileManager and advance to the next slide.
  private func deleteCurrentImage() {
    guard !isAnimating, !imageStore.images.isEmpty else { return }
    let item = imageStore.images[currentIndex]

    // Attempt to trash — FileManager.trashItem moves to Trash safely.
    do {
      var resultingURL: NSURL?
      try FileManager.default.trashItem(at: item.url, resultingItemURL: &resultingURL)
    } catch {
      // Silently fail — the app is read-oriented; show nothing disruptive.
      return
    }

    // Remove from store so gallery also updates
    imageStore.removeImage(item)

    // If no images left, dismiss slideshow
    let remaining = imageStore.images
    if remaining.isEmpty {
      onDismiss()
      return
    }

    // Clamp index and load the next image
    if currentIndex >= remaining.count {
      currentIndex = 0
    }
    currentNSImage = imageStore.fullImage(for: remaining[currentIndex])
  }
}
