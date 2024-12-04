import SwiftUI
import CoreML
import UIKit

struct WordChallengeView: View {
    @Environment(\.presentationMode) var presentationMode // SwiftUI ortamını kullanarak geri gitme
    @State private var randomWord: String = ""
    @State private var currentLetterIndex: Int = 0
    @State private var currentDrawing = [CGPoint]()
    @State private var drawings = [[CGPoint]]()
    @State private var predictedClassLabel: String = "?"
    @State private var message: String = ""
    @State private var isWordCompleted: Bool = false
    @State private var correctLetters: [Bool] = [] // Hangi harflerin doğru olduğunu tutar
    @State private var usedWords: Set<String> = [] // Kullanılmış kelimeleri tutar

    @StateObject private var audioPlayerManagerEng = AudioPlayerManagerEng()
    private let model = try? EMNISTClassifier(configuration: .init())

    private let words = [
        // 4 harfli kelimeler
        "LOVE", "HOPE", "TIME", "NAME", "SONG", "HOME", "LIFE", "MIND",
        "PLAN", "GOAL", "WORK", "PLAY",

        // 5 harfli kelimeler
        "DREAM", "LIGHT", "STORM", "RIVER", "BEACH", "HOUSE", "FLAME", "CLOUD",
        "SOUND", "BRAVE", "GRACE", "PEACE", "FAITH", "UNITY", "TRUTH", "POWER",

        // 6 harfli kelimeler
        "FAMILY", "GROWTH", "FOREST", "FRIEND", "BELOVED", "INSIDE", "STARRY",
        "NATION", "BRIGHT", "STRONG", "VISION", "ACTION", "HEALTH", "CIRCLE",

        // 7 harfli kelimeler
        "FREEDOM", "GLORIFY", "VICTORY", "EMOTION", "DESTINY", "BALANCE",
        "PRIVACY", "EXPLORE", "COURAGE", "PASSION", "JUSTICE", "VILLAGE",
        "CHARITY", "WISDOM", "HARVEST"
    ]

    var body: some View {
        ZStack {
            Color(hex: "#222831")
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Word Challenge Game")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#00ADB5"))

                HStack {
                    ForEach(0..<randomWord.count, id: \.self) { index in
                        let letter = String(randomWord[randomWord.index(randomWord.startIndex, offsetBy: index)])
                        Text(letter)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(correctLetters[index] ? Color(hex: "#00ADB5") : Color(hex: "#EEEEEE"))
                            .padding(.horizontal, 5)
                            .scaleEffect(correctLetters[index] ? 1.2 : 1.0)
                            .animation(.easeInOut, value: correctLetters[index])
                    }
                }

                if !isWordCompleted {
                    Text("Current letter to write: \(currentLetter)")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#EEEEEE"))
                } else {
                    Text("Congratulations! You completed the word.")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#00ADB5"))
                }

                Text(message)
                    .font(.headline)
                    .foregroundColor(message == "Correct letter!" ? Color.green : Color.red)
                    .animation(.easeInOut, value: message)
                    .padding(.top, 10)

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
                    predictLetterFromCanvas()
                    clearCanvas()
                }) {
                    Text("Submit Letter")
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
            .padding()
            .onAppear {
                generateRandomWord()
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

    private var currentLetter: String {
        guard currentLetterIndex < randomWord.count else { return "" }
        return String(randomWord[randomWord.index(randomWord.startIndex, offsetBy: currentLetterIndex)])
    }

    private func predictLetterFromCanvas() {
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

            if predictedClassLabel.uppercased() == currentLetter {
                audioPlayerManagerEng.speakLetter(currentLetter)
                correctLetters[currentLetterIndex] = true
                currentLetterIndex += 1
                if currentLetterIndex >= randomWord.count {
                    isWordCompleted = true
                    audioPlayerManagerEng.speakWord(from: randomWord.map { String($0) })
                    
                    // Gecikmeli yeni kelime başlat
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        generateRandomWord()
                    }
                }
                message = "Correct letter!"
            } else {
                message = "Wrong letter. Try again."
            }
        } catch {
            print("Model prediction failed: \(error.localizedDescription)")
        }
        clearCanvas()
    }

    private func renderCanvasToUIImage() -> UIImage {
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

    private func clearCanvas() {
        drawings = []
        currentDrawing = []
    }

    private func generateRandomWord() {
        let availableWords = words.filter { !usedWords.contains($0) }
        if availableWords.isEmpty {
            usedWords.removeAll()
        }
        randomWord = availableWords.randomElement() ?? "LOVE"
        usedWords.insert(randomWord)
        correctLetters = Array(repeating: false, count: randomWord.count)
        currentLetterIndex = 0
        isWordCompleted = false
    }
}
