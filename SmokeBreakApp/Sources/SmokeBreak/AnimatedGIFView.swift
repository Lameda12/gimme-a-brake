import SwiftUI
import AppKit

/// SwiftUI doesn't animate GIFs via `Image`; NSImageView does natively when
/// given GIF-backed NSImage data with `animates = true`. Fixed-size container
/// forces the view to respect bounds regardless of source image dimensions.
final class FixedSizeImageView: NSView {
    let imageView = NSImageView()
    private let side: CGFloat

    init(side: CGFloat) {
        self.side = side
        super.init(frame: .zero)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.imageFrameStyle = .none
        imageView.animates = true
        imageView.wantsLayer = true
        imageView.layer?.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: NSSize { NSSize(width: side, height: side) }
}

struct AnimatedGIFView: NSViewRepresentable {
    let name: String
    let side: CGFloat

    func makeNSView(context: Context) -> FixedSizeImageView {
        let container = FixedSizeImageView(side: side)
        if let url = Bundle.main.url(forResource: name, withExtension: "gif"),
           let image = NSImage(contentsOf: url) {
            container.imageView.image = image
        }
        return container
    }

    func updateNSView(_ nsView: FixedSizeImageView, context: Context) {}
}
