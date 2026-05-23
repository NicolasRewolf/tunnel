import SwiftUI
import UIKit

/// Circular avatar for a call profile (photo or placeholder).
struct ProfileAvatarView: View {
    let imageData: Data?
    var size: CGFloat = 34
    var placeholderIconSize: CGFloat?

    private var iconSize: CGFloat {
        placeholderIconSize ?? size * 0.47
    }

    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "person.fill")
                        .font(.system(size: iconSize))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
