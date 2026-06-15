import MapboxNavigationView from "./ExpoMapboxNavigationView";
import { ExpoMapboxNavigationViewProps, ExpoMapboxNavigationViewRef, SystemVoice } from "./ExpoMapboxNavigation.types";
/**
 * Lists on-device text-to-speech voices for a voice-selection UI, optionally
 * filtered to a language tag (e.g. "pt-BR"). Pass a returned `id` to the
 * `voiceId` prop of `MapboxNavigationView`.
 */
export declare function getAvailableVoices(language?: string): Promise<SystemVoice[]>;
export { MapboxNavigationView, ExpoMapboxNavigationViewProps as MapboxNavigationViewProps, ExpoMapboxNavigationViewRef as MapboxNavigationViewRef, SystemVoice, };
//# sourceMappingURL=index.d.ts.map