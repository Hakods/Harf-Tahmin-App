import AVFoundation

class AudioPlayerManagerEng: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()

    /// Harfleri veya kelimeleri İngilizce Text-to-Speech ile seslendirme
    func speakWord(from letters: [String]) {
        let word = letters.joined() // Harflerden bir kelime oluştur
        let utterance = AVSpeechUtterance(string: word.lowercased()) // Tüm harfleri küçük yaz
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US") // İngilizce seslendirme
        utterance.rate = 0.4 // Okuma hızı
        speechSynthesizer.speak(utterance)
        print("Read word: \(word) - Language: English")
    }

    /// Tek bir harfi İngilizce Text-to-Speech ile seslendirme
    func speakLetter(_ letter: String) {
        // Harf açıklamaları eklenmeden yalnızca harfi okur
        let utterance = AVSpeechUtterance(string: letter.lowercased()) // Küçük harf olarak seslendirme
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        utterance.prefersAssistiveTechnologySettings = false // Ek açıklamaları devre dışı bırak
        utterance.accessibilityHint = "" // Ek açıklamaları tamamen engellemek için
        speechSynthesizer.speak(utterance)
        print("Read letter: \(letter) - Language: English")
    }

    /// Tek bir harfi İngilizce ses dosyası ile oynatma
    func playSound(for letter: String) {
        let soundFileName = "\(letter.uppercased())_ENG"
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "mp3", subdirectory: "LettersEng") else {
            print("Sound file not found: LettersEng/\(soundFileName).mp3")
            return
        }
        
        do {
            if audioPlayer?.isPlaying == true {
                audioPlayer?.stop()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
            print("Playing sound: \(soundFileName).mp3")
        } catch {
            print("Sound playback error: \(error.localizedDescription)")
        }
    }
}
