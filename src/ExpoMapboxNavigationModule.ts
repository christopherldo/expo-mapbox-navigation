import { requireNativeModule } from "expo-modules-core";
import { SystemVoice } from "./ExpoMapboxNavigation.types";

type ExpoMapboxNavigationModuleType = {
  /**
   * Lists on-device text-to-speech voices, optionally filtered to a language
   * tag (e.g. "pt-BR"). Use a returned `id` as the `voiceId` prop.
   */
  getAvailableVoices: (language?: string) => Promise<SystemVoice[]>;
};

export default requireNativeModule<ExpoMapboxNavigationModuleType>(
  "ExpoMapboxNavigation"
);
