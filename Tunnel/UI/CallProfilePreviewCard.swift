import SwiftUI
import UIKit

/// In-call style preview card for a `CallProfile`.
struct CallProfilePreviewCard: View {
    let profile: CallProfile

    private static let avatarSize: CGFloat = 52

    var body: some View {
        let name = profile.contactName.trimmingCharacters(in: .whitespacesAndNewlines)
        let caption = profile.contactSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        HStack(alignment: .center, spacing: 14) {
            Group {
                if let data = profile.contactImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.12))
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .frame(width: Self.avatarSize, height: Self.avatarSize)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 0.5))

            VStack(alignment: .leading, spacing: 5) {
                Text(name.isEmpty ? "Nom du contact" : name)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(caption.isEmpty ? "Légende (fixe, portable…)" : caption)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .lineLimit(1)

                Text("00:00")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .monospacedDigit()
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.14, green: 0.14, blue: 0.16),
                            Color(red: 0.08, green: 0.08, blue: 0.09),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
    }
}
