import SwiftUI
import CoreML
import UIKit
import AVFoundation

struct WordChallengeView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var randomWord: String = ""
    @State private var currentLetterIndex: Int = 0
    @State private var currentDrawing = [CGPoint]()
    @State private var drawings = [[CGPoint]]()
    @State private var predictedClassLabel: String = "?"
    @State private var message: String = ""
    @State private var isWordCompleted: Bool = false
    @State private var correctLetters: [Bool] = []
    @State private var usedWords: Set<String> = []
    @State private var showAnimation = false
    @State private var backgroundColor = Color(hex: "#222831")
    @State private var translation: String = "" // Türkçe anlamı göstermek için
    @State private var waitingForTap = false // Kullanıcının ekrana tıklamasını bekliyor

    @StateObject private var audioPlayerManagerEng = AudioPlayerManagerEng()
    private let model = try? EMNISTClassifier(configuration: .init())

    private let words = [
        "LOVE", "HOPE", "TIME", "NAME", "SONG", "HOME", "LIFE", "MIND",
        "PLAN", "GOAL", "WORK", "PLAY", "TASK", "TEAM", "IDEA", "DREAM",
        "STAR", "MOON", "WIND", "RAIN", "FIRE", "WAVE", "TREE", "ROCK",
        "BOOK", "GAME", "CODE", "DATA", "VIEW", "PATH", "LINE", "FACE",
        "HAND", "BODY", "CITY", "TOWN", "ROAD", "LAKE", "SHIP", "FOOD",
        "WINE", "MEAL", "RIDE", "JUMP", "MOVE", "CALL", "LIST", "NOTE"
    ]
    
    private let translations: [String: String] = [
        "LOVE": "Aşk",
        "HOPE": "Umut",
        "TIME": "Zaman",
        "NAME": "İsim",
        "SONG": "Şarkı",
        "HOME": "Ev",
        "LIFE": "Hayat",
        "MIND": "Zihin",
        "PLAN": "Plan",
        "GOAL": "Hedef",
        "WORK": "Çalışma",
        "PLAY": "Oyun",
        "TASK": "Görev",
        "TEAM": "Takım",
        "IDEA": "Fikir",
        "DREAM": "Rüya",
        "STAR": "Yıldız",
        "MOON": "Ay",
        "WIND": "Rüzgar",
        "RAIN": "Yağmur",
        "FIRE": "Ateş",
        "WAVE": "Dalga",
        "TREE": "Ağaç",
        "ROCK": "Kaya",
        "BOOK": "Kitap",
        "GAME": "Oyun",
        "CODE": "Kod",
        "DATA": "Veri",
        "VIEW": "Görünüm",
        "PATH": "Yol",
        "LINE": "Çizgi",
        "FACE": "Yüz",
        "HAND": "El",
        "BODY": "Vücut",
        "CITY": "Şehir",
        "TOWN": "Kasaba",
        "ROAD": "Yol",
        "LAKE": "Göl",
        "SHIP": "Gemi",
        "FOOD": "Yemek",
        "WINE": "Şarap",
        "MEAL": "Öğün",
        "RIDE": "Biniş",
        "JUMP": "Zıplama",
        "MOVE": "Hareket",
        "CALL": "Arama",
        "LIST": "Liste",
        "NOTE": "Not"
    ]

    var body: some View {
        ZStack {
            backgroundColor
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
                    Text("Türkçe Anlamı: \(translation)")
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

            if showAnimation {
                ConfettiAnimationView()
                    .transition(.scale)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isWordCompleted && waitingForTap {
                generateRandomWord() // Yeni kelimeyi başlatmak için
                waitingForTap = false // Beklemeyi kapat
            }
        }
        .onAppear {
            generateRandomWord()
        }
        .navigationBarBackButtonHidden(true) // Varsayılan "Back" butonunu gizle
        .navigationBarItems(leading: backButton) // Özel geri butonu ekle
    }
    private var backButton: some View {
        Button(action: {
            // Geri gitme işlemi
            self.presentationMode.wrappedValue.dismiss() // NavigationView'dan bir önceki ekrana döner
        }) {
            HStack {
                Image(systemName: "chevron.left") // Geri simgesi
                Text("Back") // "Geri" yazısı
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
                audioPlayerManagerEng.speakLetter(currentLetter) // Doğru harfi seslendir
                correctLetters[currentLetterIndex] = true
                currentLetterIndex += 1
                if currentLetterIndex >= randomWord.count {
                    isWordCompleted = true
                    translation = translations[randomWord] ?? "Anlamı Bulunamadı"
                    showCelebration()
                    audioPlayerManagerEng.speakWord(from: randomWord.map { String($0) }) // Tüm kelimeyi seslendir
                    waitingForTap = true // Yeni kelimeyi bekle
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

    private func showCelebration() {
        withAnimation(.spring()) {
            showAnimation = true
            backgroundColor = Color(hex: "#00ADB5").opacity(0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring()) {
                showAnimation = false
                backgroundColor = Color(hex: "#222831")
            }
        }
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
