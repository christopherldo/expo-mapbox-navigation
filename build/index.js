import MapboxNavigationView from "./ExpoMapboxNavigationView";
import ExpoMapboxNavigationModule from "./ExpoMapboxNavigationModule";
/**
 * Lists on-device text-to-speech voices for a voice-selection UI, optionally
 * filtered to a language tag (e.g. "pt-BR"). Pass a returned `id` to the
 * `voiceId` prop of `MapboxNavigationView`.
 */
export function getAvailableVoices(language) {
    return ExpoMapboxNavigationModule.getAvailableVoices(language);
}
export { MapboxNavigationView, };
//# sourceMappingURL=index.js.map