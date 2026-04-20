import SwiftUI

struct PipAvatarView: View {
    let state: PipState
    var size: CGFloat = 32

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.pulseNavy, Color.pulseDark],
                        center: .center, startRadius: 0, endRadius: size
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle().stroke(state.eyeColor.opacity(0.35), lineWidth: 1)
                )

            PipView(state: state, size: size * 0.78, animationsEnabled: true)
                .clipShape(Circle())
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack {
        ForEach(PipState.allCases, id: \.self) { s in
            PipAvatarView(state: s, size: 44)
        }
    }
    .padding()
    .background(Color.black)
}
