//@ts-ignore
import { ViewStyle, StyleProp } from "react-native/types";
import { Ref } from "react";

type ProgressEvent = {
  distanceRemaining: number;
  distanceTraveled: number;
  durationRemaining: number;
  fractionTraveled: number;
};

type Route = {
  distance: number;
  expectedTravelTime: number;
  legs: Array<{
    source?: { latitude: number; longitude: number };
    destination?: { latitude: number; longitude: number };
    steps: Array<{
      shape?: {
        coordinates: Array<{ latitude: number; longitude: number }>;
      };
    }>;
  }>;
};

type Routes = {
  mainRoute: Route;
  alternativeRoutes: Route[];
};

/**
 * Padding values for camera viewport configuration.
 * All values are in logical pixels.
 */
type CameraPadding = {
  top?: number;
  left?: number;
  bottom?: number;
  right?: number;
};

/**
 * Navigation camera state, emitted by the onNavigationStateChanged event.
 */
type NavigationStateEvent = {
  state: "idle" | "following" | "overview";
};

/**
 * An on-device text-to-speech voice, as returned by `getAvailableVoices()`.
 */
export type SystemVoice = {
  /** Stable identifier to pass to the `voiceId` prop. */
  id: string;
  /** Human-readable voice name (may equal the id on Android). */
  name: string;
  /** BCP-47 language tag of the voice (e.g., "pt-BR"). */
  language: string;
};

export type ExpoMapboxNavigationViewRef = {
  /** Recenters the map camera to follow the user's location. */
  recenterMap: () => void;
  /** Switches the camera to route overview mode showing the entire route. */
  showRouteOverview: () => void;
};

export type ExpoMapboxNavigationViewProps = {
  ref?: Ref<ExpoMapboxNavigationViewRef>;

  // ── Route Configuration ──────────────────────────────────────────────

  /** Array of coordinates defining the route waypoints. Minimum 2 points required. */
  coordinates: Array<{ latitude: number; longitude: number }>;
  /** Indices of coordinates that should be treated as waypoints (default: all). */
  waypointIndices?: number[];
  /** Use the Map Matching API instead of standard routing for snapping to roads. */
  useRouteMatchingApi?: boolean;
  /** Language/locale code for labels, directions and voice instructions (e.g., "en-US", "pt-BR"). */
  locale?: string;
  /**
   * Measurement system for spoken and displayed distances.
   * When omitted, it is derived from the locale's region.
   */
  unitSystem?: "metric" | "imperial";
  /** Route profile identifier (e.g., "mapbox/driving-traffic", "mapbox/walking"). */
  routeProfile?: string;
  /** Road types to exclude from routing (e.g., ["toll", "motorway", "ferry"]). */
  routeExcludeList?: string[];
  /** Maximum vehicle height in meters for route restrictions. */
  vehicleMaxHeight?: number;
  /** Maximum vehicle width in meters for route restrictions. */
  vehicleMaxWidth?: number;
  /** Disable calculation and display of alternative routes. */
  disableAlternativeRoutes?: boolean;

  // ── Map Configuration ────────────────────────────────────────────────

  /** Mapbox style URL or preset (e.g., "mapbox://styles/mapbox/streets-v12"). */
  mapStyle?: string;
  /** Initial map camera position before navigation starts. */
  initialLocation?: { latitude: number; longitude: number; zoom?: number };
  /**
   * The URL of the custom raster source to use for the map.
   * Should be a template string with {x}, {y}, {z} placeholders.
   * Example: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
   */
  customRasterSourceUrl?: string;
  /** Layer ID to place the custom raster layer above (default: "water"). */
  placeCustomRasterLayerAbove?: string;

  // ── Voice Configuration ──────────────────────────────────────────────

  /** Mute voice instructions. */
  mute?: boolean;
  /**
   * Identifier of the on-device system voice used for spoken instructions.
   * Obtain valid identifiers from `getAvailableVoices()`. When omitted, the
   * default system voice for the current locale is used.
   */
  voiceId?: string;

  // ── Camera Configuration ─────────────────────────────────────────────

  /** Zoom level while following the route (overrides default zoom behavior). */
  followingZoom?: number;
  /**
   * Padding for the camera viewport in following mode (logical pixels).
   * Controls how much space is reserved around the edges of the map.
   */
  followingCameraPadding?: CameraPadding;
  /**
   * Padding for the camera viewport in overview mode (logical pixels).
   * Controls how much space is reserved around the edges when showing the full route.
   */
  overviewCameraPadding?: CameraPadding;

  // ── UI Visibility ────────────────────────────────────────────────────

  /**
   * Show or hide the top instruction banner.
   * On iOS this is the TopBannerViewController; on Android the ManeuverView.
   * @default true
   */
  showTopBanner?: boolean;
  /**
   * Show or hide the bottom trip progress banner.
   * On iOS this is the BottomBannerViewController; on Android the TripProgressView.
   * @default true
   */
  showBottomBanner?: boolean;
  /**
   * Show or hide the cancel/close navigation button.
   * @default true
   */
  showCancelButton?: boolean;
  /**
   * Show or hide the speed limit indicator.
   * iOS only — Android does not have a built-in speed limit view in this implementation.
   * @default true
   */
  showSpeedLimit?: boolean;
  /**
   * Show or hide the mute/unmute sound button.
   * @default true
   */
  showSoundButton?: boolean;
  /**
   * Show or hide the route overview button.
   * @default true
   */
  showOverviewButton?: boolean;
  /**
   * Show or hide the recenter/follow button (appears when map is panned away from the route).
   * @default true
   */
  showRecenterButton?: boolean;
  /**
   * Show or hide the maneuver arrow drawn on the map at upcoming turns.
   * @default true
   */
  showManeuverArrow?: boolean;

  // ── UI Styling ───────────────────────────────────────────────────────

  /**
   * Background color of the top instruction banner (CSS hex string, e.g., "#FFFFFF").
   */
  topBannerBackgroundColor?: string;
  /**
   * Background color of the bottom trip progress banner (CSS hex string, e.g., "#FFFFFF").
   */
  bottomBannerBackgroundColor?: string;
  /**
   * Color of the main route line (CSS hex string, e.g., "#56A8FB").
   */
  routeColor?: string;
  /**
   * Color of alternative route lines (CSS hex string, e.g., "#8694A5").
   */
  routeAlternateColor?: string;
  /**
   * Color of the route line casing/outline (CSS hex string, e.g., "#3B7AC4").
   */
  routeCasingColor?: string;
  /**
   * Color of the already-traveled portion of the route (CSS hex string, e.g., "#999999").
   */
  traversedRouteColor?: string;
  /**
   * Color of the maneuver arrow on the map (CSS hex string, e.g., "#FFFFFF").
   */
  maneuverArrowColor?: string;

  // ── Events ───────────────────────────────────────────────────────────

  /** Fired on every location update during navigation with route progress details. */
  onRouteProgressChanged?: (event: { nativeEvent: ProgressEvent }) => void;
  /** Fired when the user taps the cancel/close button. */
  onCancelNavigation?: () => void;
  /** Fired when the user arrives at an intermediate waypoint. */
  onWaypointArrival?: (event: {
    nativeEvent: ProgressEvent | undefined;
  }) => void;
  /** Fired when the user arrives at the final destination. */
  onFinalDestinationArrival?: () => void;
  /** Fired when the route is changed (e.g., due to rerouting). */
  onRouteChanged?: () => void;
  /** Fired when the user goes off the planned route. */
  onUserOffRoute?: () => void;
  /** Fired when routes are loaded with full route geometry data. */
  onRoutesLoaded?: (event: { nativeEvent: { routes: Routes } }) => void;
  /** Fired when route calculation fails. */
  onRouteFailedToLoad?: (event: {
    nativeEvent: { errorMessage: string };
  }) => void;
  /**
   * Fired when the navigation camera state changes.
   * Possible states: "idle", "following", "overview".
   */
  onNavigationStateChanged?: (event: {
    nativeEvent: NavigationStateEvent;
  }) => void;

  /** React Native style prop for the container view. */
  style?: StyleProp<ViewStyle>;
};
