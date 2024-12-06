import SwiftUI

struct ConfettiAnimationView: View {
    var body: some View {
        GeometryReader { geometry in
            ForEach(0..<100, id: \.self) { _ in
                Circle()
                    .frame(width: CGFloat.random(in: 5...10), height: CGFloat.random(in: 5...10))
                    .foregroundColor([Color.red, Color.green, Color.blue, Color.yellow, Color.purple].randomElement()!)
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(0.8)
            }
        }
    }
}
