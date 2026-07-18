import AppKit
import SwiftUI

/// Dupacode fork: collapses the main window's titlebar/toolbar strip so the
/// terminal tab bar can be the topmost element. Content extends full-size;
/// the traffic lights float over the always-visible sidebar.
struct WindowTitlebarCollapser: NSViewRepresentable {
  func makeNSView(context: Context) -> WindowTitlebarCollapserView {
    WindowTitlebarCollapserView()
  }

  func updateNSView(_ nsView: WindowTitlebarCollapserView, context: Context) {
    nsView.collapseTitlebar()
  }
}

final class WindowTitlebarCollapserView: NSView {
  override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    collapseTitlebar()
    // SwiftUI installs the NavigationSplitView toolbar after view attachment;
    // strip it again on the next runloop turn once it exists.
    DispatchQueue.main.async { [weak self] in
      self?.collapseTitlebar()
    }
  }

  func collapseTitlebar() {
    guard let window else { return }
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    if !window.styleMask.contains(.fullSizeContentView) {
      window.styleMask.insert(.fullSizeContentView)
    }
    if window.toolbar != nil {
      window.toolbar = nil
    }
  }
}
