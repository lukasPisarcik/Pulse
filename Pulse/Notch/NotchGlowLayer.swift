import AppKit
import QuartzCore

final class NotchGlowLayer {
    let borderGlow = CALayer()
    let outerBloom = CALayer()

    private var currentColor: NSColor = .pulseGreen

    init() {
        borderGlow.shadowRadius = 6
        borderGlow.shadowOpacity = 0.7
        borderGlow.shadowOffset = .zero
        borderGlow.masksToBounds = false
        borderGlow.cornerRadius = 16
        borderGlow.backgroundColor = NSColor.black.withAlphaComponent(0.001).cgColor
        borderGlow.shadowColor = currentColor.cgColor

        outerBloom.shadowRadius = 14
        outerBloom.shadowOpacity = 0.45
        outerBloom.shadowOffset = CGSize(width: 0, height: -4)
        outerBloom.masksToBounds = false
        outerBloom.cornerRadius = 16
        outerBloom.backgroundColor = NSColor.black.withAlphaComponent(0.001).cgColor
        outerBloom.shadowColor = currentColor.cgColor
    }

    func attach(to parent: CALayer, frame: CGRect) {
        borderGlow.frame = frame
        outerBloom.frame = frame
        parent.addSublayer(outerBloom)
        parent.addSublayer(borderGlow)
        startBreathingPulse(duration: 3.0)
    }

    func updateFrame(_ frame: CGRect) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        borderGlow.frame = frame
        outerBloom.frame = frame
        CATransaction.commit()
    }

    func setState(color: NSColor, pulseDuration: Double, animated: Bool = true) {
        if animated {
            let colorAnim = CABasicAnimation(keyPath: "shadowColor")
            colorAnim.fromValue = currentColor.cgColor
            colorAnim.toValue = color.cgColor
            colorAnim.duration = 0.5
            borderGlow.add(colorAnim, forKey: "borderColor")
            outerBloom.add(colorAnim, forKey: "bloomColor")
        }
        borderGlow.shadowColor = color.cgColor
        outerBloom.shadowColor = color.cgColor
        currentColor = color
        startBreathingPulse(duration: pulseDuration)
    }

    private func startBreathingPulse(duration: Double) {
        outerBloom.removeAnimation(forKey: "bloomPulse")
        let pulse = CABasicAnimation(keyPath: "shadowOpacity")
        pulse.fromValue = 0.3
        pulse.toValue = 0.6
        pulse.duration = duration
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        outerBloom.add(pulse, forKey: "bloomPulse")
    }
}
