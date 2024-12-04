import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Hareketli gradyan arka plan
                AnimatedGradientBackground()
                
                VStack(spacing: 50) {
                    // Başlık
                    Text("Harf Tahmin Uygulaması")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.top, 40)

                    Spacer()

                    // Türkçe butonu
                    NavigationLink(destination: ContentView()) {
                        NavigationButtonContent(imageName: "character.book.closed.fill", buttonText: "Türkçe")
                    }
                    .padding(.horizontal)

                    // English butonu
                    NavigationLink(destination: ContentViewEnglish()) {
                        NavigationButtonContent(imageName: "globe", buttonText: "English")
                    }
                    .padding(.horizontal)
                    
                    // Word Challenge butonu
                    NavigationLink(destination: LanguageSelectionView()) {
                        NavigationButtonContent(imageName: "pencil.and.outline", buttonText: "Kelime Tahmin Oyunu")
                    }
                    .padding(.horizontal)

                    Spacer()
                    
                    // Footer
                    FooterView()
                }
            }
            .navigationBarHidden(true) // Navigasyon barını gizle
        }
    }
}

// Hareketli gradyan arka plan
struct AnimatedGradientBackground: View {
    @State private var startPoint = UnitPoint.topLeading
    @State private var endPoint = UnitPoint.bottomTrailing

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "#222831"), Color(hex: "#393E46"), Color(hex: "#00ADB5")]),
            startPoint: startPoint,
            endPoint: endPoint
        )
        .animation(Animation.easeInOut(duration: 5).repeatForever(autoreverses: true), value: startPoint)
        .onAppear {
            startPoint = UnitPoint.bottomTrailing
            endPoint = UnitPoint.topLeading
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// Tekrarlayan buton tasarımı için yapı
struct NavigationButtonContent: View {
    let imageName: String
    let buttonText: String

    var body: some View {
        HStack {
            Image(systemName: imageName)
                .font(.title)
                .foregroundColor(.white)
            Text(buttonText)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: 350, maxHeight: 60)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#00ADB5"), Color(hex: "#007B83")]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(30)
        .shadow(color: Color(hex: "#00ADB5").opacity(0.6), radius: 10, x: 0, y: 5)
    }
}

// Footer içeriği
struct FooterView: View {
    var body: some View {
        VStack {
            Text("© 2024 Harf Tahmin Uygulaması")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.8))
            Text("Made with ❤️ by Hakods")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.bottom, 20)
    }
}
// Dil seçimi ekranı
struct LanguageSelectionView: View {
    @Environment(\.presentationMode) var presentationMode // Geri gitmek için

    var body: some View {
        ZStack {
            AnimatedGradientBackground()
            VStack(spacing: 50) {
                HStack {
                    // Geri butonu
                    Button(action: {
                        self.presentationMode.wrappedValue.dismiss() // Geri gitme işlemi
                    }) {
                        HStack {
                            Image(systemName: "chevron.left") // Geri simgesi
                            Text("Geri") // "Geri" yazısı
                        }
                        .foregroundColor(Color(hex: "#00ADB5")) // Yazı ve ikon rengi
                        .padding(.vertical, 12) // Dikey padding
                        .padding(.horizontal, 15) // Yatay padding
                        .background(Color(hex: "#393E46").opacity(0.8)) // Arka plan
                        .cornerRadius(10) // Köşe yuvarlama
                    }
                    Spacer()
                }
                .padding(.top, 20) // Üstten boşluk
                .padding(.leading, 15) // Soldan boşluk

                Spacer()
                
                Text("Kelime Tahmin Oyunu - Dil Seçimi")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)

                Spacer()

                // Türkçe butonu
                NavigationLink(destination: WordChallengeViewTR()) {
                    NavigationButtonContent(imageName: "character.book.closed.fill", buttonText: "Türkçe")
                }
                .padding(.horizontal)

                // English butonu
                NavigationLink(destination: WordChallengeView()) {
                    NavigationButtonContent(imageName: "globe", buttonText: "English")
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationBarHidden(true) // Varsayılan navigasyon barını gizle
    }
}
