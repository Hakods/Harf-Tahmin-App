import AVFoundation

class AudioPlayerManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()

    /// Harflerden bir kelime oluşturup Türkçe Text-to-Speech ile seslendirme
    func speakWord(from letters: [String]) {
        let word = letters.joined() // Harflerden bir kelime oluştur
        let utterance = AVSpeechUtterance(string: word.lowercased()) // Tüm harfleri küçük yaz
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR") // Türkçe seslendirme
        utterance.rate = 0.4 // Okuma hızı
        utterance.postUtteranceDelay = 0.5 // Her kelimeden sonra 0.5 saniye duraklama
        speechSynthesizer.speak(utterance)
        print("TTS ile okunan kelime: \(word) - Dil: Türkçe")
    }

    /// Tek bir harfi Türkçe Text-to-Speech ile seslendirme
    func speakLetter(_ letter: String) {
        let utterance = AVSpeechUtterance(string: letter.lowercased()) // Küçük harf olarak seslendirme
        utterance.voice = AVSpeechSynthesisVoice(language: "tr-TR") // Türkçe seslendirme
        utterance.rate = 0.4 // Okuma hızı
        utterance.postUtteranceDelay = 0.5 // Harften sonra 0.5 saniye duraklama
        speechSynthesizer.speak(utterance)
        print("TTS ile okunan harf: \(letter) - Dil: Türkçe")
    }

    /// Tek bir harfi Türkçe ses dosyası ile oynatma
    func playSound(for letter: String) {
        let soundFileName = "\(letter.uppercased())_TR"
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "mp3", subdirectory: "Letters") else {
            print("Ses dosyası bulunamadı: Letters/\(soundFileName).mp3")
            return
        }
        
        do {
            if audioPlayer?.isPlaying == true {
                audioPlayer?.stop()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay() // Sesin daha rahat başlaması için önceden hazırla
            audioPlayer?.play()
            print("Letters dosyasından ses çalınıyor: \(soundFileName).mp3")
        } catch {
            print("Ses çalma hatası: \(error.localizedDescription)")
        }
    }
}
