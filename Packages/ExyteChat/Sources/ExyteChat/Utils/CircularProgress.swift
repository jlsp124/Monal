// based on https://gist.github.com/iroyo/a407d7930d7d2582de11e89fe1664af9/46e6420f0d2b47209b28fbdf7070786b8bcb5a5c
import SwiftUI

struct CircularProgress: View {

    let size: CGFloat
    let color: Color

    private var border: CGFloat {
        size / 19
    }

    private var radius: CGFloat {
        (size / 2) - (border / 2)
    }

    @State private var angle: Double = 0
    @State private var rotation: Double = -90

    var repeatingAnimation: Animation {
        Animation.linear(duration: 6).repeatForever(autoreverses: false)
    }

    init(size: CGFloat = 50, color: Color = .primary) {
        self.size = size
        self.color = color
    }

    var body: some View {
        CircularProgressShape(angle, rotation, radius)
                .stroke(color, lineWidth: border)
                .onAppear {
                    withAnimation(repeatingAnimation) {
                        self.angle = CircularProgressShape.MAX_ANGLE
                        self.rotation = 540
                    }
                }

    }
}

struct CircularProgressShape: Shape {
    static let MAX_ANGLE: Double = 270 * 6

    private let minDegreeDistance: Double = 22.5
    private let maxDegreeDistance: Double = 270
    private let circleRadius: CGFloat

    private var angle: Double
    private var rotation: Double

    init(_ angle: Double, _ rotation: Double, _ radius: CGFloat) {
        circleRadius = radius
        self.angle = angle
        self.rotation = rotation
    }

    public var animatableData: AnimatablePair<Double, Double> {
        get {
            AnimatablePair(Double(angle), Double(rotation))
        }
        set {
            angle = Double(newValue.first)
            rotation = Double(newValue.second)
        }
    }

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        let start: Double, end: Double
        let revolution: Int = Int(angle / maxDegreeDistance)
        if revolution % 2 == 0 {
            start = Double(revolution / 2) * maxDegreeDistance
            end = angle + minDegreeDistance - start
        } else {
            let factor = Double((revolution + 1) / 2)
            start = angle - factor * maxDegreeDistance
            end = maxDegreeDistance * factor + minDegreeDistance
        }
        p.addArc(center: center, radius: circleRadius, startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false)
        return p.rotation(.degrees(rotation)).path(in: rect)
    }
}

