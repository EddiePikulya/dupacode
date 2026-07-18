import AppKit
import SwiftUI

/// Dupacode fork: hosts the entire titlebar strip content (add-repository menu
/// + terminal tab bar) in a single `NSTitlebarAccessoryViewController` row next
/// to the traffic lights. With no NSToolbar in the window, this row is the
/// whole strip — the terminal content starts directly below the tabs.
///
/// SwiftUI toolbar items silently refuse to mount the tab bar's view tree (see
/// the strip-tabs commit history for the full bisect), but accessory
/// controllers host any `NSHostingView` without gatekeeping.
struct TitlebarTabBarAccessory<Content: View>: NSViewRepresentable {
  /// Height of the strip row.
  let height: CGFloat
  @ViewBuilder let content: () -> Content

  func makeNSView(context: Context) -> AccessoryAnchorView {
    AccessoryAnchorView()
  }

  func updateNSView(_ nsView: AccessoryAnchorView, context: Context) {
    nsView.install(rootView: AnyView(content()), height: height)
  }

  final class AccessoryAnchorView: NSView {
    /// Horizontal room left for the traffic lights at the leading edge.
    private let trafficLightsReserve: CGFloat = 78

    private var accessory: NSTitlebarAccessoryViewController?
    private var pendingRoot: AnyView?
    private var pendingHeight: CGFloat = 0
    private var resizeObserver: NSObjectProtocol?

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      if let resizeObserver {
        NotificationCenter.default.removeObserver(resizeObserver)
        self.resizeObserver = nil
      }
      guard let window else { return }
      resizeObserver = NotificationCenter.default.addObserver(
        forName: NSWindow.didResizeNotification,
        object: window,
        queue: .main
      ) { [weak self] _ in
        MainActor.assumeIsolated {
          self?.fitToWindow()
        }
      }
      attachIfPossible()
    }

    func install(rootView: AnyView, height: CGFloat) {
      pendingRoot = rootView
      pendingHeight = height
      attachIfPossible()
    }

    private func attachIfPossible() {
      guard let window, let pendingRoot else { return }
      if accessory == nil {
        let controller = NSTitlebarAccessoryViewController()
        controller.layoutAttribute = .left
        controller.view = NSHostingView(rootView: AnyView(EmptyView()))
        window.addTitlebarAccessoryViewController(controller)
        accessory = controller
      }
      guard let hosting = accessory?.view as? NSHostingView<AnyView> else { return }
      hosting.rootView = pendingRoot
      fitToWindow()
    }

    private func fitToWindow() {
      guard let window, let hosting = accessory?.view as? NSHostingView<AnyView> else { return }
      let size = NSSize(
        width: max(window.frame.width - trafficLightsReserve, 0),
        height: pendingHeight
      )
      if hosting.frame.size != size, size.width > 0 {
        hosting.setFrameSize(size)
      }
    }
  }
}
