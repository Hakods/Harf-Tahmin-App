import SwiftUI
import CoreML
import UIKit

struct ContentViewEnglish: View {
    @Environment(\.presentationMode) var presentationMode // SwiftUI ortamını kullanarak geri gitme
    @State private var predictedClassLabel: String = "?"
    @State private var currentDrawing = [CGPoint]()
    @State private var drawings = [[CGPoint]]()
    @State private var inputLetters = [String]() // Store predicted letters

    @StateObject private var audioPlayerManagerEng = AudioPlayerManagerEng()

    private let model = try? EMNISTClassifier(configuration: .init())

    var body: some View {
        ZStack {
            Color(hex: "#222831") // Background color
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Letter Prediction App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#00ADB5"))
                    .padding(.top, 30)

                VStack {
                    Text("Predicted Letter: \(predictedClassLabel)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#393E46").opacity(0.8))
                        .foregroundColor(Color(hex: "#EEEEEE"))
                        .cornerRadius(15)
                        .padding([.leading, .trailing])
                }

                // Show written letters
                if !inputLetters.isEmpty {
                    Text("Entered Letters: \(inputLetters.joined())")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "#EEEEEE"))
                        .padding()
                        .background(Color(hex: "#393E46").opacity(0.8))
                        .cornerRadius(10)
                }

                Canvas { context, size in
                    for line in drawings {
                        var path = Path()
                        path.addLines(line)
                        context.stroke(path, with: .color(Color(hex: "#EEEEEE")), lineWidth: 4)
                    }
                    var path = Path()
                    path.addLines(currentDrawing)
                    context.stroke(path, with: .color(Color(hex: "#EEEEEE")), lineWidth: 4)
                }
                .frame(width: 250, height: 250)
                .background(Color(hex: "#393E46"))
                .cornerRadius(15)
                .shadow(radius: 10)
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
                .padding()

                Button(action: {
                    predictFromCanvas()
                }) {
                    Text("Predict")
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#EEEEEE"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#00ADB5"))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding([.leading, .trailing])

                Button(action: {
                    audioPlayerManagerEng.speakWord(from: inputLetters) // Use correct audio manager
                    inputLetters.removeAll() // Clear the list after reading
                }) {
                    Text("Read Entered Letters")
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#EEEEEE"))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#00ADB5"))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                }
                .padding([.leading, .trailing])
            }
        }
        .navigationBarBackButtonHidden(true) // Varsayılan "Back" butonunu gizle
        .navigationBarItems(leading: backButton) // Özel geri butonu ekle
    }

    // Özel "Back" butonu
    private var backButton: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss() // Geri gitme işlemi
        }) {
            HStack {
                Image(systemName: "chevron.left") // Geri simgesi
                Text("Back") // "Back" yazısı
            }
            .foregroundColor(Color(hex: "#00ADB5"))
        }
    }

    func predictFromCanvas() {
        let canvasImage = renderCanvasToUIImage()

        guard let processedImage = cropTransparency(image: canvasImage),
              let inputBuffer = processedImage.toCVPixelBuffer(),
              let model = model else {
            print("Prediction failed.")
            return
        }

        do {
            let output = try model.prediction(x: inputBuffer)
            predictedClassLabel = output.classLabel
            inputLetters.append(predictedClassLabel)

            // Speak predicted letter
            audioPlayerManagerEng.speakWord(from: [predictedClassLabel])

            print("Prediction successful, class: \(predictedClassLabel)")
        } catch {
            print("Model prediction failed: \(error.localizedDescription)")
        }

        clearDrawing()
    }

    func renderCanvasToUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 28, height: 28))
        return renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))

            let scaleFactor = 28.0 / 250.0
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
    }
}
