import SwiftUI
import AppKit
import ServiceManagement

@main
struct SmokeBreakApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var overlayController: OverlayWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerAsLoginItem()

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "smoke", accessibilityDescription: "Smoke Break")
                ?? NSImage(systemSymbolName: "pause.circle", accessibilityDescription: "Smoke Break")
            button.toolTip = "Smoke Break — idle"
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "Smoke Break", action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(NSMenuItem.separator())
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit", action: #selector(quit), keyEquivalent: "q")
        for item in menu.items { item.target = self }
        statusItem?.menu = menu

        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func registerAsLoginItem() {
        guard SMAppService.mainApp.status == .notRegistered else { return }
        try? SMAppService.mainApp.register()
    }

    @objc private func toggleLoginItem(_ sender: NSMenuItem) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                sender.state = .off
            } else {
                try SMAppService.mainApp.register()
                sender.state = .on
            }
        } catch {
            sender.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }

    @objc nonisolated func handleGetURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue,
              let components = URLComponents(string: urlString) else { return }

        var params: [String: String] = [:]
        components.queryItems?.forEach { item in
            params[item.name] = item.value
        }

        let cli = params["cli"] ?? "claude"
        let duration = Int(params["duration"] ?? "3") ?? 3
        let reason = params["reason"] ?? "context_limit"
        let quote = params["quote"]?.removingPercentEncoding
        let tokens = params["tokens"].flatMap { Int($0) }

        Task { @MainActor in
            self.showBreak(
                cli: cli,
                duration: duration,
                reason: reason,
                quote: quote ?? self.defaultQuote(for: duration),
                tokens: tokens
            )
        }
    }

    private func defaultQuote(for duration: Int) -> String {
        "My head's full. This ain't a request — we're done for \(duration) minutes."
    }

    private func showBreak(cli: String, duration: Int, reason: String, quote: String, tokens: Int?) {
        statusItem?.button?.toolTip = "Smoke Break — running (\(reason))"

        SoundPlayer.shared.play(tier: SoundTier.forTokenCount(tokens))

        let controller = OverlayWindowController(
            cli: cli,
            duration: duration,
            reason: reason,
            quote: quote
        ) { [weak self] in
            self?.statusItem?.button?.toolTip = "Smoke Break — idle"
            self?.overlayController = nil
        }
        overlayController = controller
        controller.show()
    }
}
