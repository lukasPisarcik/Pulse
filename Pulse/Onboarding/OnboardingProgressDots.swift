import SwiftUI

struct OnboardingProgressDots: View {
    let total: Int
    let currentIndex: Int
    let onTapCompleted: (Int) -> Void

    @State private var pulse: CGFloat = 0.75

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                dot(for: i)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if i < currentIndex { onTapCompleted(i) }
                    }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = 1.0
            }
        }
    }

    @ViewBuilder
    private func dot(for i: Int) -> some View {
        if i < currentIndex {
            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: 7, height: 7)
        } else if i == currentIndex {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
                    .frame(width: 10, height: 10)
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 5, height: 5)
                    .opacity(Double(pulse))
            }
        } else {
            Circle()
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
                .frame(width: 7, height: 7)
        }
    }
}
