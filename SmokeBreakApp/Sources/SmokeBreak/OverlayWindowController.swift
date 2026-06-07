import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController: NSWindowController {
    private let onFinish: () -> Void

    init(cli: String, duration: Int, reason: String, quote: String, onFinish: @escaping () -> Void) {
        self.onFinish = onFinish

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 96),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false

        super.init(window: panel)

        let view = OverlayView(
            cli: cli,
            duration: duration,
            reason: reason,
            quote: quote,
            onDismiss: { [weak self] in self?.dismiss() }
        )
        panel.contentView = NSHostingView(rootView: view)
        positionTopRight(panel)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func positionTopRight(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let origin = NSPoint(
            x: frame.maxX - panel.frame.width - 20,
            y: frame.maxY - panel.frame.height - 20
        )
        panel.setFrameOrigin(origin)
    }

    func show() {
        window?.orderFrontRegardless()
    }

    private func dismiss() {
        window?.animator().alphaValue = 0
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.4
            window?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            MainActor.assumeIsolated {
                self?.window?.orderOut(nil)
                self?.onFinish()
            }
        })
    }
}
