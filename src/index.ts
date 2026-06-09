import MapboxNavigationView from "./ExpoMapboxNavigationView";
import ExpoMapboxNavigationModule from "./ExpoMapboxNavigationModule";
import {
  ExpoMapboxNavigationViewProps,
  ExpoMapboxNavigationViewRef,
  SystemVoice,
} from "./ExpoMapboxNavigation.types";

/**
 * Lists on-device text-to-speech voices for a voice-selection UI, optionally
 * filtered to a language tag (e.g. "pt-BR"). Pass a returned `id` to the
 * `voiceId` prop of `MapboxNavigationView`.
 */
export function getAvailableVoices(language?: string): Promise<SystemVoice[]> {
  return ExpoMapboxNavigationModule.getAvailableVoices(language);
}

export {
  MapboxNavigationView,
  ExpoMapboxNavigationViewProps as MapboxNavigationViewProps,
  ExpoMapboxNavigationViewRef as MapboxNavigationViewRef,
  SystemVoice,
};
