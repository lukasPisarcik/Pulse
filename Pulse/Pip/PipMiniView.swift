import SwiftUI

struct PipMiniView: View {
    let state: PipState
    var width: CGFloat = 20
    var height: CGFloat = 22

    @StateObject private var animator = PipAnimator()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: height / 2.4)
                .fill(Color.pulseNavy)
                .frame(width: width, height: height * 0.82)
                .offset(y: 2)

            HStack(spacing: width * 0.18) {
                eyeDot()
                eyeDot()
            }
            .offset(y: -1)

            Triangle()
                .fill(Color(hex: 0xF5A623))
                .frame(width: width * 0.15, height: height * 0.12)
                .rotationEffect(.degrees(180))
                .offset(y: height * 0.18)
        }
        .frame(width: width, height: height)
        .onAppear { animator.start(for: state) }
        .onDisappear { animator.stop() }
        .onChange(of: state) { _, s in animator.start(for: s) }
    }

    private func eyeDot() -> some View {
        ZStack {
            Circle()
                .fill(state.eyeColor)
                .frame(width: width * 0.26, height: width * 0.26)
                .blur(radius: 2)
                .opacity(animator.isGlowing ? 0.9 : 0.5)

            Circle()
                .fill(state.eyeColor)
                .frame(width: width * 0.18, height: width * 0.18)
                .scaleEffect(y: animator.isBlinking ? 0.1 : 1.0)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ForEach(PipState.allCases, id: \.self) { s in
            PipMiniView(state: s)
        }
    }
    .padding()
    .background(Color.black)
}
