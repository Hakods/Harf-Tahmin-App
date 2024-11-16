import AVFoundation

class AudioPlayerManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer() // Text-to-Speech desteği
    
    /// Tek bir harfi ses dosyasından oynatır
    func playSound(for letter: String) {
        let soundFileName = letter.uppercased()
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "mp3") else {
            print("Ses dosyası bulunamadı: \(soundFileName).mp3")
            return
        }
        
        do {
            if audioPlayer?.isPlaying == true {
                audioPlayer?.stop()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
            print("Ses çalınıyor: \(soundFileName).mp3")
        } catch {
            print("Ses çalma hatası: \(error.localizedDescription)")
        }
    }

    /// Harfleri birleştirerek kelimeyi Türkçe seslendirme yapar
    func speakWord(from letters: [String]) {
        let word = letters.joined() // Harfleri birleştirerek bir kelime oluşturur
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR") // Türkçe seslendirme
        utterance.rate = 0.5 // Okuma hızı (insansı hız için 0.5 ideal)
        utterance.pitchMultiplier = 1.0 // Ses tonu
        speechSynthesizer.speak(utterance)
        print("Okunan kelime (Türkçe): \(word)")
    }

    /// Harflerin tamamını sırayla ses dosyası olarak çalar
    func playAllLettersSequentially(inputLetters: [String]) {
        let lettersQueue = DispatchQueue(label: "lettersQueue", attributes: .concurrent)
        
        lettersQueue.async {
            for letter in inputLetters {
                DispatchQueue.main.async {
                    self.playSound(for: letter)
                }
                Thread.sleep(forTimeInterval: 0.8) // Her harf arasında gecikme ekler
            }
        }
    }
}
