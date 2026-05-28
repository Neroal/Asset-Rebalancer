import SwiftUI

struct PieChartView: View {
    let segments: [ChartSegment]
    let centerText: String

    var body: some View {
        let startAngles = computeStartAngles()

        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.42
            let innerRadius = size * 0.28

            ZStack {
                // Draw segments
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                    let startAngle = startAngles[index]
                    let endAngle = startAngle + Angle(degrees: segment.percentage / 100 * 360)

                    Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: startAngle - .degrees(90),
                            endAngle: endAngle - .degrees(90),
                            clockwise: false
                        )
                        path.addArc(
                            center: center,
                            radius: innerRadius,
                            startAngle: endAngle - .degrees(90),
                            endAngle: startAngle - .degrees(90),
                            clockwise: true
                        )
                        path.closeSubpath()
                    }
                    .fill(segment.category.swiftUIColor)

                    // Percentage label
                    if segment.percentage > 5 {
                        let midAngle = startAngle + Angle(degrees: segment.percentage / 100 * 180)
                        let labelRadius = (radius + innerRadius) / 2
                        let labelX = center.x + labelRadius * cos(CGFloat(midAngle.radians - .pi / 2))
                        let labelY = center.y + labelRadius * sin(CGFloat(midAngle.radians - .pi / 2))

                        Text(Rebalancer.formatPercentage(segment.percentage))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .position(x: labelX, y: labelY)
                    }
                }

                // Small gaps between segments
                ForEach(Array(segments.enumerated()), id: \.element.id) { index, _ in
                    let angle = startAngles[index]
                    Path { path in
                        let x1 = center.x + innerRadius * cos(CGFloat(angle.radians - .pi / 2))
                        let y1 = center.y + innerRadius * sin(CGFloat(angle.radians - .pi / 2))
                        let x2 = center.x + radius * cos(CGFloat(angle.radians - .pi / 2))
                        let y2 = center.y + radius * sin(CGFloat(angle.radians - .pi / 2))
                        path.move(to: CGPoint(x: x1, y: y1))
                        path.addLine(to: CGPoint(x: x2, y: y2))
                    }
                    .stroke(Color(.systemBackground), lineWidth: 2)
                }

                // Center text
                VStack(spacing: 2) {
                    Text(centerText)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(width: innerRadius * 1.6)
                .position(center)
            }
        }
    }

    private func computeStartAngles() -> [Angle] {
        var angles: [Angle] = []
        var cumulative = 0.0
        for segment in segments {
            angles.append(Angle(degrees: cumulative / 100 * 360))
            cumulative += segment.percentage
        }
        return angles
    }
}
