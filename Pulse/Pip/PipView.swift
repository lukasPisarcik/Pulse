import SwiftUI

struct PipView: View {
    let state: PipState
    var size: CGFloat = 80
    var animationsEnabled: Bool = true

    @StateObject private var animator = PipAnimator()

    var body: some View {
        Canvas(opaque: false) { _, _ in } symbols: { }
            .frame(width: size, height: size * 1.1)
            .overlay { pipBody }
            .rotationEffect(.degrees(animator.isNodding ? -4 : 0), anchor: .bottom)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true),
                       value: animator.isNodding)
            .onAppear {
                if animationsEnabled { animator.start(for: state) }
            }
            .onDisappear { animator.stop() }
            .onChange(of: state) { _, newState in
                if animationsEnabled { animator.start(for: newState) }
            }
            .onChange(of: animationsEnabled) { _, enabled in
                if enabled { animator.start(for: state) } else { animator.stop() }
            }
    }

    private var pipBody: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                tufts(w: w, h: h)
                bodyShape(w: w, h: h)
                faceDisc(w: w, h: h)
                cheeks(w: w, h: h)
                eyes(w: w, h: h)
                beak(w: w, h: h)
                feet(w: w, h: h)
                if state == .breakTaken { wingWave(w: w, h: h) }
            }
        }
    }

    private func tufts(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: w * 0.32) {
            Triangle()
                .fill(Color.pulseNavy)
                .frame(width: w * 0.14, height: h * 0.18)
                .rotationEffect(.degrees(-8 + state.tuftAngle))
            Triangle()
                .fill(Color.pulseNavy)
                .frame(width: w * 0.14, height: h * 0.18)
                .rotationEffect(.degrees(8 - state.tuftAngle))
        }
        .offset(y: h * 0.08)
    }

    private func bodyShape(w: CGFloat, h: CGFloat) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0xA8C488), Color(hex: 0x8FAD72)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: w * 0.82, height: h * 0.82)
            .offset(y: h * 0.08)
    }

    private func faceDisc(w: CGFloat, h: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [Color(hex: 0xEEF4E4), Color(hex: 0xD8EABF)],
                    center: .center, startRadius: 0, endRadius: w * 0.35
                )
            )
            .frame(width: w * 0.64, height: h * 0.58)
            .offset(y: h * 0.04)
    }

    private func cheeks(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: w * 0.30) {
            Circle()
                .fill(Color(hex: 0xE89B9B).opacity(0.35))
                .frame(width: w * 0.10, height: w * 0.10)
            Circle()
                .fill(Color(hex: 0xE89B9B).opacity(0.35))
                .frame(width: w * 0.10, height: w * 0.10)
        }
        .offset(y: h * 0.15)
    }

    private func eyes(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: w * 0.14) {
            eye(w: w, h: h)
            eye(w: w, h: h)
        }
        .offset(y: h * 0.04)
    }

    private func eye(w: CGFloat, h: CGFloat) -> some View {
        let eyeSize = w * 0.16
        return ZStack {
            Circle()
                .fill(state.eyeColor)
                .frame(width: eyeSize * 1.6, height: eyeSize * 1.6)
                .blur(radius: 4)
                .opacity(animator.isGlowing ? 0.85 : 0.45)
                .scaleEffect(animator.isGlowing ? 1.08 : 0.92)

            Circle()
                .stroke(state.eyeColor, lineWidth: 1.5)
                .frame(width: eyeSize, height: eyeSize)

            Circle()
                .fill(Color.pulseDark)
                .frame(width: eyeSize * 0.68, height: eyeSize * 0.68)
                .scaleEffect(y: animator.isBlinking ? 0.08 : state.eyelidScale, anchor: .center)

            Circle()
                .fill(Color.white)
                .frame(width: eyeSize * 0.18, height: eyeSize * 0.18)
                .offset(x: eyeSize * 0.14, y: -eyeSize * 0.14)
                .opacity(animator.isBlinking ? 0 : 1)
        }
    }

    private func beak(w: CGFloat, h: CGFloat) -> some View {
        Triangle()
            .fill(Color(hex: 0xF5A623))
            .frame(width: w * 0.10, height: h * 0.08)
            .rotationEffect(.degrees(180))
            .offset(y: h * 0.24)
    }

    private func feet(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: w * 0.18) {
            TalonShape()
                .fill(Color(hex: 0xEF9F27))
                .frame(width: w * 0.11, height: h * 0.07)
            TalonShape()
                .fill(Color(hex: 0xEF9F27))
                .frame(width: w * 0.11, height: h * 0.07)
        }
        .offset(y: h * 0.44)
    }

    private func wingWave(w: CGFloat, h: CGFloat) -> some View {
        Ellipse()
            .fill(Color(hex: 0x8FAD72))
            .frame(width: w * 0.22, height: h * 0.32)
            .offset(x: w * 0.30, y: h * 0.10)
            .rotationEffect(.degrees(animator.isWaving ? -18 : 0),
                            anchor: UnitPoint(x: 0.7, y: 0.3))
            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                       value: animator.isWaving)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct TalonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let step = rect.width / 4
        for i in 0..<3 {
            let x = step + CGFloat(i) * step
            p.move(to: CGPoint(x: x, y: rect.minY))
            p.addLine(to: CGPoint(x: x, y: rect.maxY))
        }
        return p.strokedPath(.init(lineWidth: 2, lineCap: .round))
    }
}

#Preview {
    HStack(spacing: 24) {
        ForEach(PipState.allCases, id: \.self) { s in
            VStack {
                PipView(state: s, size: 90)
                Text(String(describing: s)).font(.caption)
            }
        }
    }
    .padding()
    .background(Color.pulseDark)
}
