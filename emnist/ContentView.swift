import SwiftUI
import CoreML
import UIKit

struct ContentView: View {
    @State private var predictedClassLabel: String = "?"
    @State private var classProbabilities: [String: Double] = [:]
    @State private var currentDrawing = [CGPoint]()
    @State private var drawings = [[CGPoint]]()
    private let model = try? EMNISTClassifier(configuration: .init())

    var body: some View {
        VStack {
            Text("Tahmin Edilen Harf: \(predictedClassLabel)") // Display predicted class here
                .font(.title)
                .padding()

            Canvas { context, size in
                for line in drawings {
                    var path = Path()
                    path.addLines(line)
                    context.stroke(path, with: .color(.white), lineWidth: 4)
                }
                var path = Path()
                path.addLines(currentDrawing)
                context.stroke(path, with: .color(.white), lineWidth: 4)
            }
            .frame(width: 200, height: 200)
            .background(Color.black)
            .border(Color.gray, width: 1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        currentDrawing.append(value.location)
                    }
                    .onEnded { _ in
                        drawings.append(currentDrawing)
                        currentDrawing = []
                    }
            )

            Button("Tahmin Yap") {
                predictFromCanvas()
                clearDrawing()
            }
            .padding()
        }
    }

    func predictFromCanvas() {
        let canvasImage = renderCanvasToUIImage()

        guard let processedImage = cropTransparency(image: canvasImage),
              let inputBuffer = processedImage.toCVPixelBuffer(),
              let model = model else {
            print("İşlem başarısız oldu.")
            return
        }

        print("Tahmin işlemi başladı")

        do {
            let output = try model.prediction(x: inputBuffer)
            predictedClassLabel = output.classLabel // Update predictedClassLabel with the prediction result
            classProbabilities = output.classLabel_probs
            print("Tahmin başarıyla yapıldı, sınıf: \(predictedClassLabel)") // Confirm prediction in the console
        } catch {
            print("Model tahmin işlemi başarısız oldu: \(error.localizedDescription)")
        }
    }

    func renderCanvasToUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 28, height: 28))
        return renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))

            let scaleFactor = 28.0 / 200.0
            context.cgContext.scaleBy(x: scaleFactor, y: scaleFactor)

            let path = UIBezierPath()
            for line in drawings {
                path.move(to: line.first ?? .zero)
                for point in line.dropFirst() {
                    path.addLine(to: point)
                }
            }
            UIColor.white.setStroke()
            path.lineWidth = 4 / scaleFactor
            path.stroke()
        }
    }

    func clearDrawing() {
        drawings = []
        currentDrawing = []
        classProbabilities = [:]
    }
}
