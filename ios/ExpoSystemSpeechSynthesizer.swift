import Foundation
import AVFoundation
import Combine
import MapboxNavigationCore

/// On-device speech synthesizer backed by `AVSpeechSynthesizer`.
///
/// Wired into the navigation provider via `TTSConfig.custom` so that the spoken
/// language always matches the requested locale (fixing the English fallback of
/// the cloud voice API) and so the app can pick a specific system voice
/// (Waze-style) by identifier.
@MainActor
final class ExpoSystemSpeechSynthesizer: NSObject, SpeechSynthesizing {
    private let synthesizer = AVSpeechSynthesizer()
    private let voiceInstructionsSubject = PassthroughSubject<any VoiceInstructionEvent, Never>()
    private var currentInstruction: SpokenInstruction?

    /// Identifier of the `AVSpeechSynthesisVoice` to use. When nil, the default
    /// voice for `locale` is used.
    var voiceIdentifier: String?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - SpeechSynthesizing

    var voiceInstructions: AnyPublisher<any VoiceInstructionEvent, Never> {
        voiceInstructionsSubject.eraseToAnyPublisher()
    }

    var muted: Bool = false {
        didSet {
            if muted { interruptSpeaking() }
        }
    }

    var volume: VolumeMode = .system

    var isSpeaking: Bool {
        synthesizer.isSpeaking
    }

    var locale: Locale? = Locale.current

    var managesAudioSession: Bool = true

    func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        // No pre-buffering needed for on-device synthesis.
    }

    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        guard !muted else { return }

        currentInstruction = instruction

        if managesAudioSession {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .voicePrompt, options: [.duckOthers, .mixWithOthers])
            try? session.setActive(true)
        }

        let utterance = AVSpeechUtterance(string: instruction.text)
        utterance.voice = resolveVoice(locale: locale ?? self.locale)
        if case let .override(value) = volume {
            utterance.volume = value
        }

        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .word)
    }

    func interruptSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Voice resolution

    private func resolveVoice(locale: Locale?) -> AVSpeechSynthesisVoice? {
        if let id = voiceIdentifier, let voice = AVSpeechSynthesisVoice(identifier: id) {
            return voice
        }
        let languageCode = (locale ?? Locale.current).identifier.replacingOccurrences(of: "_", with: "-")
        return AVSpeechSynthesisVoice(language: languageCode)
            ?? AVSpeechSynthesisVoice(language: Locale.current.identifier)
    }

    /// Lists installed on-device voices, optionally filtered by primary language
    /// subtag (e.g. "pt" matches "pt-BR"). Each entry: (id, name, language).
    nonisolated static func availableVoices(matchingLanguage languageTag: String?) -> [[String: String]] {
        let wantLang = languageTag.map {
            $0.replacingOccurrences(of: "_", with: "-").split(separator: "-").first.map(String.init) ?? $0
        }?.lowercased()

        return AVSpeechSynthesisVoice.speechVoices()
            .filter { voice in
                guard let wantLang else { return true }
                return voice.language.lowercased().hasPrefix(wantLang)
            }
            .map { voice in
                [
                    "id": voice.identifier,
                    "name": voice.name,
                    "language": voice.language,
                ]
            }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension ExpoSystemSpeechSynthesizer: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard let instruction = self.currentInstruction else { return }
            self.voiceInstructionsSubject.send(VoiceInstructionEvents.WillSpeak(instruction: instruction))
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            guard let instruction = self.currentInstruction else { return }
            self.voiceInstructionsSubject.send(VoiceInstructionEvents.DidSpeak(instruction: instruction))
        }
    }
}
