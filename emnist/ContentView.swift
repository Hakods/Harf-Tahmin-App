import SwiftUI
import CoreML
import UIKit

struct ContentView: View {
    @State private var predictedClassLabel: String = "?"
    @State private var targetClassLabel: String = ""
    @State private var message: String = ""
    @State private var classProbabilities: [String: Double] = [:]
    @State private var currentDrawing = [CGPoint]()
    @State private var drawings = [[CGPoint]]()
    @State private var showMessage = false
    private let model = try? EMNISTClassifier(configuration: .init())
    private let allClassLabels = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    var body: some View {
        ZStack {
            Color(hex: "#222831").edgesIgnoringSafeArea(.all) // Background color

            VStack(spacing: 20) {
                Text("Harf Tahmin Uygulaması")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#00ADB5"))
                    .padding(.top, 30)

                VStack {
                    Text("Hedef Harf: \(targetClassLabel)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#393E46").opacity(0.8))
                        .foregroundColor(Color(hex: "#EEEEEE"))
                        .cornerRadius(15)
                        .padding([.leading, .trailing])

                    Text("Tahmin Edilen Harf: \(predictedClassLabel)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#393E46").opacity(0.8))
                        .foregroundColor(Color(hex: "#EEEEEE"))
                        .cornerRadius(15)
                        .padding([.leading, .trailing])
                }

                if showMessage {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(message == "Doğru çizdin, tebrikler!" ? Color(hex: "#00ADB5") : Color(hex: "#EEEEEE"))
                        .transition(.opacity)
                        .padding()
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

                HStack(spacing: 20) {
                    Button(action: {
                        selectNewTargetClassLabel()
                        clearDrawing()
                    }) {
                        Text("Yeni Harf Belirle")
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#EEEEEE"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#393E46"))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }

                    Button(action: {
                        predictFromCanvas()
                    }) {
                        Text("Tahmin Yap")
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#EEEEEE"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#00ADB5"))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                }
                .padding([.leading, .trailing])
            }
        }
        .onAppear(perform: selectNewTargetClassLabel)
    }

    // Hex kodunu SwiftUI rengine dönüştürme fonksiyonu
    init() {
        UINavigationBar.appearance().tintColor = UIColor(Color(hex: "#00ADB5"))
    }

    func selectNewTargetClassLabel() {
        targetClassLabel = String(allClassLabels.randomElement() ?? "A")
        predictedClassLabel = "?"
        message = ""
        showMessage = false
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
            predictedClassLabel = output.classLabel
            classProbabilities = output.classLabel_probs

            if predictedClassLabel == targetClassLabel {
                message = "Doğru çizdin, tebrikler!"
            } else {
                message = "Yanlış çizdin, tekrar dene!"
                clearDrawing()
            }
            withAnimation {
                showMessage = true
            }
            print("Tahmin başarıyla yapıldı, sınıf: \(predictedClassLabel)")
        } catch {
            print("Model tahmin işlemi başarısız oldu: \(error.localizedDescription)")
        }
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
        classProbabilities = [:]
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
