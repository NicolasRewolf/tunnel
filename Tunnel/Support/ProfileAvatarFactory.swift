import UIKit

/// Generates default profile avatar images (gradient + SF Symbol) for fresh installs.
enum ProfileAvatarFactory {
    static func seededJPEG(symbol: String, colors: (UIColor, UIColor)) -> Data? {
        let size = CGSize(width: 600, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let cgColors = [colors.0.cgColor, colors.1.cgColor] as CFArray
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
            } else {
                colors.0.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
            }

            UIColor.black.withAlphaComponent(0.12).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: -120, y: -80, width: 520, height: 520))
            UIColor.black.withAlphaComponent(0.18).setFill()
            ctx.cgContext.fillEllipse(in: CGRect(x: 220, y: 260, width: 560, height: 560))

            let pointSize: CGFloat = 250
            let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .semibold)
            let symbolImage = UIImage(systemName: symbol, withConfiguration: config)
            let tint = UIColor.white.withAlphaComponent(0.95)
            if let rendered = symbolImage?.withTintColor(tint, renderingMode: .alwaysOriginal) {
                let rect = CGRect(
                    x: (size.width - pointSize) / 2,
                    y: (size.height - pointSize) / 2,
                    width: pointSize,
                    height: pointSize
                )
                rendered.draw(in: rect)
            }
        }
        return image.jpegData(compressionQuality: 0.90)
    }

    static func seededProfile(
        name: String,
        subtitle: String,
        symbol: String,
        colors: (UIColor, UIColor)
    ) -> CallProfile {
        var profile = CallProfile()
        profile.contactName = name
        profile.contactSubtitle = subtitle
        profile.contactImageData = seededJPEG(symbol: symbol, colors: colors)
        return profile
    }
}
