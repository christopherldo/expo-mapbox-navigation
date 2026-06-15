import { SystemVoice } from "./ExpoMapboxNavigation.types";
type ExpoMapboxNavigationModuleType = {
    /**
     * Lists on-device text-to-speech voices, optionally filtered to a language
     * tag (e.g. "pt-BR"). Use a returned `id` as the `voiceId` prop.
     */
    getAvailableVoices: (language?: string) => Promise<SystemVoice[]>;
};
declare const _default: ExpoMapboxNavigationModuleType;
export default _default;
//# sourceMappingURL=ExpoMapboxNavigationModule.d.ts.map