import SwiftUI

struct TTFTChartView: View {
    let measurements: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("TTFT Performance")
                .font(.headline)
            
            GeometryReader { geometry in
                Path { path in
                    guard measurements.count > 1 else { return }
                    
                    let maxValue = measurements.max() ?? 1
                    let xStep = geometry.size.width / CGFloat(measurements.count - 1)
                    let yScale = geometry.size.height / CGFloat(maxValue)
                    
                    path.move(to: CGPoint(x: 0, y: geometry.size.height - (measurements[0] * yScale)))
                    
                    for index in 1..<measurements.count {
                        let x = CGFloat(index) * xStep
                        let y = geometry.size.height - (measurements[index] * yScale)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            }
            .frame(height: 100)
            
            HStack {
                Text("Avg: \(Int(measurements.reduce(0, +) / Double(measurements.count)))ms")
                    .font(.caption)
                Spacer()
                Text("Last: \(Int(measurements.last ?? 0))ms")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}
