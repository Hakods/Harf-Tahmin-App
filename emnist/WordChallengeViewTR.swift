import SwiftUI
import CoreML
import UIKit

struct WordChallengeViewTR: View {
    @Environment(\.presentationMode) var presentationMode // SwiftUI ortamını kullanarak geri gitme
    @State private var rastgeleKelime: String = ""
    @State private var mevcutHarfIndex: Int = 0
    @State private var mevcutCizim = [CGPoint]()
    @State private var cizimler = [[CGPoint]]()
    @State private var tahminEdilenHarf: String = "?"
    @State private var mesaj: String = ""
    @State private var kelimeTamamlandi: Bool = false
    @State private var dogruHarfler: [Bool] = [] // Hangi harflerin doğru olduğunu tutar
    @State private var kullanilmisKelimeler: Set<String> = [] // Kullanılmış kelimeleri tutar

    @StateObject private var sesYoneticisi = AudioPlayerManager()
    private let model = try? EMNISTClassifier(configuration: .init())

    private let kelimeler = [
        // 3-4 harfli kelimeler
        "GEL", "EV", "OKUL", "YOL", "HAS", "YAZ", "AY", "BAL", "HAN",
        "ALP", "KALP", "ELMA", "OYUN", "KURT","KASA",

        // 5 harfli kelimeler
        "ARABA", "KART", "KASAP", "HAYAL", "RENK", "KAVUN", "ANKA", "FERAH","KEMAL","ERCAN","SEVGI","YASAK",

        // 6 harfli kelimeler
        "HAKAN", "ANKARA", "SALDA", "YOZGAT", "CESUR", "KORKU", "TURUNC",
        "PARLAK", "HIRSIZ", "MUTLU", "SAVSAK","DESTEK","TAYYIP",

        // 7 harfli kelimeler
        "MUSTAFA", "SAVUNMA", "CANATAN","BURAKHAN", "SEVGILI","KASABA",
        "KAHRAMAN", "DOSTLUK", "KARAMAN"
    ]


    var body: some View {
        ZStack {
            Color(hex: "#222831")
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Text("Kelime Tahmin Oyunu")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "#00ADB5"))

                HStack {
                    ForEach(0..<rastgeleKelime.count, id: \.self) { index in
                        let harf = String(rastgeleKelime[rastgeleKelime.index(rastgeleKelime.startIndex, offsetBy: index)])
                        Text(harf)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(dogruHarfler[index] ? Color(hex: "#00ADB5") : Color(hex: "#EEEEEE"))
                            .padding(.horizontal, 5)
                            .scaleEffect(dogruHarfler[index] ? 1.2 : 1.0)
                            .animation(.easeInOut, value: dogruHarfler[index])
                    }
                }

                if !kelimeTamamlandi {
                    Text("Sıradaki Harf: \(mevcutHarf)")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#EEEEEE"))
                } else {
                    Text("Tebrikler! Kelimeyi Tamamladınız.")
                        .font(.title3)
                        .foregroundColor(Color(hex: "#00ADB5"))
                }

                Text(mesaj)
                    .font(.headline)
                    .foregroundColor(mesaj == "Doğru harf!" ? Color.green : Color.red)
                    .animation(.easeInOut, value: mesaj)
                    .padding(.top, 10)

                Canvas { context, size in
                    for cizim in cizimler {
                        var path = Path()
                        path.addLines(cizim)
                        context.stroke(path, with: .color(Color(hex: "#EEEEEE")), lineWidth: 4)
                    }
                    var path = Path()
                    path.addLines(mevcutCizim)
                    context.stroke(path, with: .color(Color(hex: "#EEEEEE")), lineWidth: 4)
                }
                .frame(width: 250, height: 250)
                .background(Color(hex: "#393E46"))
                .cornerRadius(15)
                .shadow(radius: 10)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { deger in
                            mevcutCizim.append(deger.location)
                        }
                        .onEnded { _ in
                            cizimler.append(mevcutCizim)
                            mevcutCizim = []
                        }
                )
                .padding()

                Button(action: {
                    harfiTahminEt()
                    cizimTemizle()
                }) {
                    Text("Harfi Gönder")
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
                yeniKelimeUret()
            }
        }
        .navigationBarBackButtonHidden(true) // Varsayılan "Back" butonunu gizle
        .navigationBarItems(leading: geriButonu) // Özel geri butonu ekle
    }

    private var geriButonu: some View {
        Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Geri")
            }
            .foregroundColor(Color(hex: "#00ADB5"))
        }
    }

    private var mevcutHarf: String {
        guard mevcutHarfIndex < rastgeleKelime.count else { return "" }
        return String(rastgeleKelime[rastgeleKelime.index(rastgeleKelime.startIndex, offsetBy: mevcutHarfIndex)])
    }

    private func harfiTahminEt() {
        let canvasImage = renderCanvasToUIImage()

        guard let processedImage = cropTransparency(image: canvasImage),
              let inputBuffer = processedImage.toCVPixelBuffer(),
              let model = model else {
            print("Tahmin başarısız.")
            return
        }

        do {
            let output = try model.prediction(x: inputBuffer)
            tahminEdilenHarf = output.classLabel

            if tahminEdilenHarf.uppercased() == mevcutHarf {
                sesYoneticisi.speakLetter(mevcutHarf)
                dogruHarfler[mevcutHarfIndex] = true
                mevcutHarfIndex += 1
                if mevcutHarfIndex >= rastgeleKelime.count {
                    kelimeTamamlandi = true
                    sesYoneticisi.speakWord(from: rastgeleKelime.map { String($0) })
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        yeniKelimeUret()
                    }
                }
                mesaj = "Doğru harf!"
            } else {
                mesaj = "Yanlış harf. Tekrar deneyin."
            }
        } catch {
            print("Model tahmin işlemi başarısız: \(error.localizedDescription)")
        }
        cizimTemizle()
    }

    private func renderCanvasToUIImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 28, height: 28))
        return renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: 28, height: 28)))

            let scaleFactor = 28.0 / 250.0
            context.cgContext.scaleBy(x: scaleFactor, y: scaleFactor)

            let path = UIBezierPath()
            for line in cizimler {
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

    private func cizimTemizle() {
        cizimler = []
        mevcutCizim = []
    }

    private func yeniKelimeUret() {
        let uygunKelimeler = kelimeler.filter { !kullanilmisKelimeler.contains($0) }
        if uygunKelimeler.isEmpty {
            kullanilmisKelimeler.removeAll()
        }
        rastgeleKelime = uygunKelimeler.randomElement() ?? "KAPI"
        kullanilmisKelimeler.insert(rastgeleKelime)
        dogruHarfler = Array(repeating: false, count: rastgeleKelime.count)
        mevcutHarfIndex = 0
        kelimeTamamlandi = false
    }
}
