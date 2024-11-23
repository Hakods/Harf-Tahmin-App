import AVFoundation

class AudioPlayerManagerEnglish: ObservableObject {
    var audioPlayer: AVAudioPlayer?
    private var speechSynthesizer = AVSpeechSynthesizer()

    func playSound(for letter: String) {
        let soundFileName = letter.uppercased()
        guard let soundURL = Bundle.main.url(forResource: soundFileName, withExtension: "mp3") else {
            print("Sound file not found: \(soundFileName).mp3")
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

    func speakWord(from letters: [String]) {
        let word = letters.joined()
        let utterance = AVSpeechUtterance(string: word)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        speechSynthesizer.speak(utterance)
        print("Read word: \(word)")
    }

    func playAllLetters(inputLetters: [String]) {
        speakWord(from: inputLetters)
    }
}
