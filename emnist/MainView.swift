import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            ZStack {
                // Dinamik hareketli gradyan arka plan
                AnimatedGradientBackground()
                
                VStack(spacing: 50) {
                    // Başlık
                    Text("Harf Tahmin Uygulaması")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.top, 40)
                        .scaleEffect(1.1)
                        .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: 1.1)

                    Spacer()
                    
                    // Türkçe butonu
                    NavigationLink(destination: ContentView()) {
                        HStack {
                            Image(systemName: "map.fill")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("Türkçe")
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
                    .scaleEffect(1.05)
                    .padding(.horizontal)
                    .animation(.spring(), value: 1.05)

                    // English butonu
                    NavigationLink(destination: ContentViewEnglish()) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title)
                                .foregroundColor(.white)
                            Text("English")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .frame(maxWidth: 350, maxHeight: 60)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#00ADB5"), Color(hex: "#007B83")]),
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: Color(hex: "#00ADB5").opacity(0.6), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)

                    Spacer()
                    //DENEME
                    // Footer
                    VStack {
                        Text("© 2024 Harf Tahmin Uygulaması")
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.8))
                        Text("Made with by Hakods")
                            .font(.footnote)
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .padding(.bottom, 20)
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
