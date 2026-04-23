import SwiftUI

/// A rounded rectangle whose top corners are typically square and bottom corners
/// are rounded — intended to visually continue the hardware notch downward.
struct NotchShape: Shape {
    var topCornerRadius: CGFloat = 0
    var bottomCornerRadius: CGFloat = 14

    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: topCornerRadius,
                bottomLeading: bottomCornerRadius,
                bottomTrailing: bottomCornerRadius,
                topTrailing: topCornerRadius
            ),
            style: .continuous
        )
        .path(in: rect)
    }
}
