import SwiftUI
import CoreML
import UIKit
import AVFoundation

struct WordChallengeViewTR: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var rastgeleKelime: String = ""
    @State private var mevcutHarfIndex: Int = 0
    @State private var mevcutCizim = [CGPoint]()
    @State private var cizimler = [[CGPoint]]()
    @State private var tahminEdilenHarf: String = "?"
    @State private var mesaj: String = ""
    @State private var kelimeTamamlandi: Bool = false
    @State private var dogruHarfler: [Bool] = []
    @State private var kullanilmisKelimeler: Set<String> = []
    @State private var animasyonGoster = false
    @State private var arkaPlanRengi = Color(hex: "#222831")
    @State private var translation: String = ""
    @State private var waitingForTap = false // Yeni kelimeye geçmek için tıklamayı bekle

    @StateObject private var audioPlayerManagerTr = AudioPlayerManager()
    private let model = try? EMNISTClassifier(configuration: .init())

    private let kelimeler = [
        "GEL", "EV", "OKUL", "YOL", "HAS", "YAZ", "AY", "BAL", "HAN",
        "ALP", "KALP", "ELMA", "OYUN", "KURT", "KASA", "ARABA", "KART",
        "KASAP", "HAYAL", "RENK", "KAVUN", "ANKA", "FERAH", "KEMAL",
        "ERCAN", "SEVGI", "YASAK", "HAKAN", "ANKARA", "SALDA", "YOZGAT",
        "CESUR", "KORKU", "PARLAK", "HIRSIZ", "MUTLU", "SAVSAK",
        "DESTEK", "KALEM", "LALE", "SAVUNMA", "CANATAN", "KURA",
        "SEVGILI", "KASABA", "KAHRAMAN", "DOSTLUK", "KARAMAN"
    ]

    private let translations: [String: String] = [
        "GEL": "Come", "EV": "House", "OKUL": "School", "YOL": "Road",
        "HAS": "Pure", "YAZ": "Summer", "AY": "Moon", "BAL": "Honey",
        "HAN": "Inn", "ALP": "Hero", "KALP": "Heart", "ELMA": "Apple",
        "OYUN": "Game", "KURT": "Wolf", "KASA": "Case", "ARABA": "Car",
        "KART": "Card", "KASAP": "Butcher", "HAYAL": "Dream", "RENK": "Color",
        "KAVUN": "Melon", "ANKA": "Phoenix", "FERAH": "Relief", "KEMAL": "Perfection",
        "ERCAN": "Courage", "SEVGI": "Love", "YASAK": "Ban", "HAKAN": "Ruler",
        "ANKARA": "Ankara", "SALDA": "Lake Salda", "YOZGAT": "Yozgat",
        "CESUR": "Brave", "KORKU": "Fear", "PARLAK": "Bright", "HIRSIZ": "Thief",
        "MUTLU": "Happy", "SAVSAK": "Careless", "DESTEK": "Support",
        "KALEM": "Pen", "LALE": "Tulip", "SAVUNMA": "Defense",
        "CANATAN": "Volunteer", "KURA": "Draw", "SEVGILI": "Beloved",
        "KASABA": "Town", "KAHRAMAN": "Hero", "DOSTLUK": "Friendship",
        "KARAMAN": "Karaman"
    ]

    var body: some View {
        ZStack {
            arkaPlanRengi
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
                    Text("İngilizcesi: \(translation)")
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
            .contentShape(Rectangle())
            .onTapGesture {
                if kelimeTamamlandi && waitingForTap {
                    generateRandomWord() // Yeni kelimeyi başlatmak için
                    waitingForTap = false // Beklemeyi kapat
                }
            }

            if animasyonGoster {
                ConfettiAnimationView()
                    .transition(.scale)
            }
        }
        .onAppear {
            generateRandomWord()
        }
        .navigationBarBackButtonHidden(true) // Varsayılan "Back" butonunu gizle
        .navigationBarItems(leading: backButton) // Özel geri butonu ekle
    }
    
    // Özel "Geri" butonu
    private var backButton: some View {
        Button(action: {
            // Geri gitme işlemi
            self.presentationMode.wrappedValue.dismiss() // NavigationView'dan bir önceki ekrana döner
        }) {
            HStack {
                Image(systemName: "chevron.left") // Geri simgesi
                Text("Geri") // "Geri" yazısı
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
                audioPlayerManagerTr.speakLetter(mevcutHarf) // Doğru harfi seslendir
                dogruHarfler[mevcutHarfIndex] = true
                mevcutHarfIndex += 1
                if mevcutHarfIndex >= rastgeleKelime.count {
                    kelimeTamamlandi = true
                    translation = translations[rastgeleKelime] ?? "Anlamı Bulunamadı"
                    showCelebration()
                    audioPlayerManagerTr.speakWord(from: rastgeleKelime.map { String($0) }) // Kelimeyi seslendir
                    waitingForTap = true // Yeni kelimeye geçmek için tıklama bekle
                }
                mesaj = "Doğru harf!"
            } else {
                mesaj = "Yanlış harf. Tekrar deneyin."
            }
        } catch {
            print("Tahmin başarısız: \(error.localizedDescription)")
        }
        cizimTemizle()
    }

    private func showCelebration() {
        withAnimation(.spring()) {
            animasyonGoster = true
            arkaPlanRengi = Color(hex: "#00ADB5").opacity(0.8)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring()) {
                animasyonGoster = false
                arkaPlanRengi = Color(hex: "#222831")
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

    private func generateRandomWord() {
        let uygunKelimeler = kelimeler.filter { !kullanilmisKelimeler.contains($0) }
        if uygunKelimeler.isEmpty {
            kullanilmisKelimeler.removeAll()
        }
        rastgeleKelime = uygunKelimeler.randomElement() ?? "GEL"
        kullanilmisKelimeler.insert(rastgeleKelime)
        dogruHarfler = Array(repeating: false, count: rastgeleKelime.count)
        mevcutHarfIndex = 0
        kelimeTamamlandi = false
        waitingForTap = false // Yeni kelimeye geçmeden önce beklemeyi sıfırla
    }
}
