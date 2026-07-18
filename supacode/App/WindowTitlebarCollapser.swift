import AppKit
import SwiftUI

/// Dupacode fork: collapses the main window's titlebar/toolbar strip so the
/// terminal tab bar can be the topmost element. Content extends full-size;
/// the traffic lights float over the always-visible sidebar's top row.
///
/// SwiftUI re-applies window styling (title visibility, style mask) on scene
/// updates, so a one-shot configuration gets reverted — the view re-asserts
/// the collapsed state on every `didUpdate` notification. All writes are
/// guarded, so the steady-state cost is a few boolean checks.
struct WindowTitlebarCollapser: NSViewRepresentable {
  func makeNSView(context: Context) -> WindowTitlebarCollapserView {
    WindowTitlebarCollapserView()
  }

  func updateNSView(_ nsView: WindowTitlebarCollapserView, context: Context) {
    nsView.collapseTitlebar()
  }
}

final class WindowTitlebarCollapserView: NSView {
  private var observer: NSObjectProtocol?

  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if let observer {
      NotificationCenter.default.removeObserver(observer)
      self.observer = nil
    }
    guard let window else { return }
    collapseTitlebar()
    observer = NotificationCenter.default.addObserver(
      forName: NSWindow.didUpdateNotification,
      object: window,
      queue: .main
    ) { [weak self] _ in
      MainActor.assumeIsolated {
        self?.collapseTitlebar()
      }
    }
  }

  deinit {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  func collapseTitlebar() {
    guard let window else { return }
    if window.titleVisibility != .hidden {
      window.titleVisibility = .hidden
    }
    if !window.titlebarAppearsTransparent {
      window.titlebarAppearsTransparent = true
    }
    if !window.styleMask.contains(.fullSizeContentView) {
      window.styleMask.insert(.fullSizeContentView)
    }
    if window.toolbar != nil {
      window.toolbar = nil
    }
  }
}
