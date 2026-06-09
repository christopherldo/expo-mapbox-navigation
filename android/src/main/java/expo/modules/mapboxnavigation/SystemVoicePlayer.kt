package expo.modules.mapboxnavigation

import android.content.Context
import android.os.Bundle
import android.speech.tts.TextToSpeech
import java.util.Locale
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

/**
 * On-device text-to-speech player for turn-by-turn voice instructions.
 *
 * Bypasses Mapbox's cloud Voice API (MapboxSpeechApi) so the spoken language
 * always matches the requested locale and so the app can pick a specific system
 * voice (Waze-style). Feed it the raw instruction text from a
 * VoiceInstructionsObserver.
 */
class SystemVoicePlayer(
        context: Context,
        private var locale: Locale,
        private var voiceId: String? = null,
) {
    private var isReady = false
    private var isMuted = false
    private val pending = ArrayDeque<String>()
    private var utteranceCounter = 0L

    private val tts =
            TextToSpeech(context.applicationContext) { status ->
                if (status == TextToSpeech.SUCCESS) {
                    isReady = true
                    applyLanguage()
                    applyVoice()
                    while (pending.isNotEmpty()) {
                        speakInternal(pending.removeFirst())
                    }
                }
            }

    private fun applyLanguage() {
        if (isReady) tts.setLanguage(locale)
    }

    private fun applyVoice() {
        if (!isReady) return
        val id = voiceId ?: return
        tts.voices?.firstOrNull { it.name == id }?.let { tts.voice = it }
    }

    fun setLocale(newLocale: Locale) {
        locale = newLocale
        applyLanguage()
        applyVoice()
    }

    fun setVoice(newVoiceId: String?) {
        voiceId = newVoiceId
        // Reset to the default voice for the language before applying a new one.
        applyLanguage()
        applyVoice()
    }

    fun setMuted(muted: Boolean) {
        isMuted = muted
        if (muted) tts.stop()
    }

    fun play(text: String?) {
        if (text.isNullOrBlank()) return
        if (!isReady) {
            pending.addLast(text)
            return
        }
        speakInternal(text)
    }

    private fun speakInternal(text: String) {
        if (isMuted) return
        tts.speak(text, TextToSpeech.QUEUE_ADD, Bundle(), "mbx-voice-${utteranceCounter++}")
    }

    fun stop() {
        pending.clear()
        if (isReady) tts.stop()
    }

    fun shutdown() {
        pending.clear()
        tts.stop()
        tts.shutdown()
        isReady = false
    }

    companion object {
        /**
         * Enumerates on-device voices for a selection UI. Spins up a temporary
         * TextToSpeech engine, waits for init, then tears it down. Optionally
         * filters to a single language (by primary language subtag).
         */
        fun queryAvailableVoices(
                context: Context,
                languageTag: String?,
        ): List<Map<String, String>> {
            val latch = CountDownLatch(1)
            val result = mutableListOf<Map<String, String>>()
            var engine: TextToSpeech? = null
            val wantLang = languageTag?.let { Locale.forLanguageTag(it).language }

            engine =
                    TextToSpeech(context.applicationContext) { status ->
                        try {
                            if (status == TextToSpeech.SUCCESS) {
                                (engine?.voices ?: emptySet())
                                        .asSequence()
                                        .filterNot { it.isNetworkConnectionRequired }
                                        .filter { v ->
                                            wantLang == null ||
                                                    v.locale.language.equals(wantLang, true)
                                        }
                                        .forEach { v ->
                                            result.add(
                                                    mapOf(
                                                            "id" to v.name,
                                                            "name" to v.name,
                                                            "language" to
                                                                    v.locale.toLanguageTag(),
                                                    )
                                            )
                                        }
                            }
                        } finally {
                            latch.countDown()
                        }
                    }

            latch.await(5, TimeUnit.SECONDS)
            engine?.shutdown()
            return result
        }
    }
}
