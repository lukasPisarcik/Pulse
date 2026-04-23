import SwiftUI

/// Static Pip-on-dark composition for exporting to the macOS AppIcon asset set.
/// Deliberately decoupled from the animated `PipView` so `ImageRenderer` captures a
/// clean resting pose with no timer-driven state.
struct AppIconView: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                background(size: size)
                ecg(size: size)
                pip(size: size * 0.64)
                    .offset(y: -size * 0.02)
                sparkles(size: size)
                border(size: size)
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    // MARK: - Background

    private func background(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [Color(hex: 0x0F2018), Color(hex: 0x060E0A)],
                    center: .center,
                    startRadius: 0,
                    endRadius: size * 0.6
                )
            )
    }

    // MARK: - Owl

    private func pip(size: CGFloat) -> some View {
        ZStack {
            tufts(size: size)
            body(size: size)
            face(size: size)
            cheeks(size: size)
            eyes(size: size)
            beak(size: size)
            feet(size: size)
        }
        .frame(width: size, height: size * 1.1)
    }

    private func tufts(size: CGFloat) -> some View {
        HStack(spacing: size * 0.30) {
            Triangle()
                .fill(Color(hex: 0x8FAD72))
                .frame(width: size * 0.14, height: size * 0.20)
                .rotationEffect(.degrees(-10))
            Triangle()
                .fill(Color(hex: 0x8FAD72))
                .frame(width: size * 0.14, height: size * 0.20)
                .rotationEffect(.degrees(10))
        }
        .offset(y: -size * 0.42)
    }

    private func body(size: CGFloat) -> some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [Color(hex: 0xA8C488), Color(hex: 0x8FAD72)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .frame(width: size * 0.88, height: size * 0.90)
            .offset(y: size * 0.04)
    }

    private func face(size: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [Color(hex: 0xEEF4E4), Color(hex: 0xD8EABF)],
                    center: .center, startRadius: 0, endRadius: size * 0.35
                )
            )
            .frame(width: size * 0.68, height: size * 0.62)
            .offset(y: -size * 0.02)
    }

    private func cheeks(size: CGFloat) -> some View {
        HStack(spacing: size * 0.32) {
            Circle()
                .fill(Color(hex: 0xE89B9B).opacity(0.32))
                .frame(width: size * 0.11, height: size * 0.11)
            Circle()
                .fill(Color(hex: 0xE89B9B).opacity(0.32))
                .frame(width: size * 0.11, height: size * 0.11)
        }
        .offset(y: size * 0.10)
    }

    private func eyes(size: CGFloat) -> some View {
        HStack(spacing: size * 0.14) {
            eye(size: size)
            eye(size: size)
        }
        .offset(y: -size * 0.04)
    }

    private func eye(size: CGFloat) -> some View {
        let eyeSize = size * 0.18
        return ZStack {
            Circle()
                .fill(Color.pulseGreen)
                .frame(width: eyeSize * 2.0, height: eyeSize * 2.0)
                .blur(radius: size * 0.035)
                .opacity(0.55)

            Circle()
                .stroke(Color.pulseGreen, lineWidth: size * 0.010)
                .frame(width: eyeSize, height: eyeSize)

            Circle()
                .fill(Color.pulseDark)
                .frame(width: eyeSize * 0.66, height: eyeSize * 0.66)

            Circle()
                .fill(Color.white)
                .frame(width: eyeSize * 0.22, height: eyeSize * 0.22)
                .offset(x: eyeSize * 0.16, y: -eyeSize * 0.16)
        }
    }

    private func beak(size: CGFloat) -> some View {
        Triangle()
            .fill(Color(hex: 0xF5A623))
            .frame(width: size * 0.11, height: size * 0.09)
            .rotationEffect(.degrees(180))
            .offset(y: size * 0.22)
    }

    private func feet(size: CGFloat) -> some View {
        HStack(spacing: size * 0.18) {
            TalonShape()
                .fill(Color(hex: 0xEF9F27))
                .frame(width: size * 0.11, height: size * 0.06)
            TalonShape()
                .fill(Color(hex: 0xEF9F27))
                .frame(width: size * 0.11, height: size * 0.06)
        }
        .offset(y: size * 0.46)
    }

    // MARK: - Decorative

    private func ecg(size: CGFloat) -> some View {
        ECGShape()
            .stroke(Color.pulseGreen.opacity(0.45), lineWidth: size * 0.010)
            .frame(width: size * 0.72, height: size * 0.05)
            .offset(y: size * 0.34)
    }

    private func sparkles(size: CGFloat) -> some View {
        ZStack {
            sparkle(size: size, x: -0.32, y: -0.28, r: 0.012)
            sparkle(size: size, x: 0.30, y: -0.32, r: 0.010)
            sparkle(size: size, x: 0.36, y: 0.10, r: 0.008)
            sparkle(size: size, x: -0.36, y: 0.12, r: 0.010)
        }
    }

    private func sparkle(size: CGFloat, x: CGFloat, y: CGFloat, r: CGFloat) -> some View {
        Circle()
            .fill(Color.pulseGlowSparkle.opacity(0.7))
            .frame(width: size * r * 2, height: size * r * 2)
            .offset(x: size * x, y: size * y)
    }

    private func border(size: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            .strokeBorder(Color.pulseGreen.opacity(0.22), lineWidth: max(1, size * 0.004))
    }
}

struct ECGShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let segments = 5
        let step = w / CGFloat(segments)
        p.move(to: CGPoint(x: 0, y: h / 2))
        for i in 0..<segments {
            let x = CGFloat(i) * step
            p.addLine(to: CGPoint(x: x + step * 0.25, y: h / 2))
            p.addLine(to: CGPoint(x: x + step * 0.35, y: 0))
            p.addLine(to: CGPoint(x: x + step * 0.50, y: h))
            p.addLine(to: CGPoint(x: x + step * 0.65, y: h / 2))
            p.addLine(to: CGPoint(x: x + step,        y: h / 2))
        }
        return p
    }
}

#Preview {
    AppIconView()
        .frame(width: 256, height: 256)
        .padding()
        .background(Color.gray.opacity(0.2))
}
