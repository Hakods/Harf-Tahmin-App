import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(hex: "#222831"), Color(hex: "#393E46")]),
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all) // Gradient background
                
                VStack(spacing: 40) {
                    // Başlık
                    Text("Harf Tahmin Uygulaması")
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundColor(Color(hex: "#00ADB5"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 50)
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)

                    Spacer()
                    
                    // Türkçe butonu
                    NavigationLink(destination: ContentView()) {
                        Text("Türkçe")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#EEEEEE"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#00ADB5"), Color(hex: "#00ADB5").opacity(0.8)]),
                                                       startPoint: .top,
                                                       endPoint: .bottom))
                            .cornerRadius(20)
                            .shadow(color: Color(hex: "#00ADB5").opacity(0.6), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .scaleEffect(1.05)
                    .animation(.spring(), value: 1.05)
                    
                    // English butonu
                    NavigationLink(destination: ContentViewEnglish()) {
                        Text("English")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#EEEEEE"))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(gradient: Gradient(colors: [Color(hex: "#00ADB5"), Color(hex: "#00ADB5").opacity(0.8)]),
                                                       startPoint: .top,
                                                       endPoint: .bottom))
                            .cornerRadius(20)
                            .shadow(color: Color(hex: "#00ADB5").opacity(0.6), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Footer
                    Text("© 2024 Harf Tahmin Uygulaması")
                        .font(.footnote)
                        .foregroundColor(Color(hex: "#EEEEEE").opacity(0.7))
                        .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true) // Navigasyon barını gizle
        }
    }
}
