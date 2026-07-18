import AppKit
import SwiftUI

/// Dupacode fork: hosts the terminal tab bar in the window titlebar via an
/// `NSTitlebarAccessoryViewController`. SwiftUI toolbar items silently refuse
/// to mount the tab bar's view tree (see the strip-tabs commit history for the
/// full bisect), but accessory controllers host any `NSHostingView` without
/// gatekeeping. Width is driven by the measured detail-column width so the bar
/// tracks window, sidebar, and inspector resizes.
struct TitlebarTabBarAccessory<Content: View>: NSViewRepresentable {
  let width: CGFloat
  let height: CGFloat
  @ViewBuilder let content: () -> Content

  func makeNSView(context: Context) -> AccessoryAnchorView {
    AccessoryAnchorView()
  }

  func updateNSView(_ nsView: AccessoryAnchorView, context: Context) {
    nsView.install(
      rootView: AnyView(content()),
      size: NSSize(width: max(width, 0), height: height)
    )
  }

  final class AccessoryAnchorView: NSView {
    private var accessory: NSTitlebarAccessoryViewController?
    private var pendingRoot: AnyView?
    private var pendingSize: NSSize = .zero

    override func viewDidMoveToWindow() {
      super.viewDidMoveToWindow()
      attachIfPossible()
    }

    func install(rootView: AnyView, size: NSSize) {
      pendingRoot = rootView
      pendingSize = size
      attachIfPossible()
    }

    private func attachIfPossible() {
      guard let window, let pendingRoot else { return }
      if accessory == nil {
        let controller = NSTitlebarAccessoryViewController()
        controller.layoutAttribute = .right
        controller.view = NSHostingView(rootView: AnyView(EmptyView()))
        window.addTitlebarAccessoryViewController(controller)
        accessory = controller
      }
      guard let hosting = accessory?.view as? NSHostingView<AnyView> else { return }
      hosting.rootView = pendingRoot
      if pendingSize.width > 0, hosting.frame.size != pendingSize {
        hosting.setFrameSize(pendingSize)
      }
    }
  }
}
