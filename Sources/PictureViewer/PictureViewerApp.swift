import AppKit
import CoreText
import SwiftUI

@main
struct PictureViewerApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var imageStore = ImageStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(imageStore)
    }
    .windowStyle(.hiddenTitleBar)
    .defaultSize(width: 1100, height: 750)
  }
}

// MARK: - App Delegate

/// Registers bundled fonts and enters full screen on launch.
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var didEnterFullScreen = false

  func applicationDidFinishLaunching(_ notification: Notification) {
    registerBundledFonts()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(windowDidBecomeKey),
      name: NSWindow.didBecomeKeyNotification,
      object: nil
    )
  }

  @objc @MainActor private func windowDidBecomeKey(_ notification: Notification) {
    guard !didEnterFullScreen, let window = notification.object as? NSWindow else { return }
    didEnterFullScreen = true
    window.toggleFullScreen(nil)
  }

  /// Registers all .ttf fonts found in the bundled Fonts resource directory.
  private func registerBundledFonts() {
    guard let fontsURL = Bundle.module.url(forResource: "Fonts", withExtension: nil) else {
      return
    }
    guard
      let enumerator = FileManager.default.enumerator(
        at: fontsURL,
        includingPropertiesForKeys: nil,
        options: [.skipsHiddenFiles]
      )
    else { return }

    for case let fileURL as URL in enumerator where fileURL.pathExtension == "ttf" {
      CTFontManagerRegisterFontsForURL(fileURL as CFURL, .process, nil)
    }
  }
}
