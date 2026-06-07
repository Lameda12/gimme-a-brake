import SwiftUI
import AppKit

struct OverlayView: View {
    let cli: String
    let duration: Int
    let reason: String
    let quote: String
    let onDismiss: () -> Void

    @State private var remaining: Int
    @State private var progress: Double = 0
    private let total: Int
    private let thumbSide: CGFloat = 72

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(cli: String, duration: Int, reason: String, quote: String, onDismiss: @escaping () -> Void) {
        self.cli = cli
        self.duration = duration
        self.reason = reason
        self.quote = quote
        self.onDismiss = onDismiss
        let totalSeconds = max(duration, 1) * 60
        self.total = totalSeconds
        _remaining = State(initialValue: totalSeconds)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            AnimatedGIFView(name: "smoking", side: thumbSide)
                .frame(width: thumbSide, height: thumbSide)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    cliLogo
                        .frame(width: 16, height: 16)
                    Text("Smoke Break")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer(minLength: 8)
                    Text(reason)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Text(quote)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(2)
                    .truncationMode(.tail)

                HStack(spacing: 8) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.12))
                            Capsule().fill(.orange)
                                .frame(width: max(4, geo.size.width * progress))
                        }
                    }
                    .frame(height: 4)

                    Text(timeLabel)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                        .fixedSize()
                }
            }
        }
        .padding(12)
        .frame(width: 340, height: 96)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.07))
        )
        .onReceive(timer) { _ in tick() }
        .onAppear { progress = doneFraction }
    }

    private var cliLogo: some View {
        Group {
            if let image = NSImage(contentsOf: logoURL) {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "terminal").foregroundStyle(.white)
            }
        }
    }

    private var logoURL: URL {
        let name = cli.lowercased().contains("codex") ? "codex-color" : "claudecode-color"
        return Bundle.main.url(forResource: name, withExtension: "svg")
            ?? URL(fileURLWithPath: "/dev/null")
    }

    private var doneFraction: Double {
        Double(total - remaining) / Double(total)
    }

    private var timeLabel: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func tick() {
        guard remaining > 0 else {
            onDismiss()
            return
        }
        remaining -= 1
        withAnimation(.linear(duration: 1)) {
            progress = doneFraction
        }
        if remaining == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onDismiss() }
        }
    }
}
