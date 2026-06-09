import ExpoModulesCore
import CoreLocation

public class ExpoMapboxNavigationModule: Module {

  public func definition() -> ModuleDefinition {
    Name("ExpoMapboxNavigation")

    // Lists on-device TTS voices, optionally filtered to a language tag (e.g.
    // "pt-BR"), for a voice-selection UI. Each item: { id, name, language }.
    AsyncFunction("getAvailableVoices") { (language: String?) -> [[String: String]] in
      return ExpoSystemSpeechSynthesizer.availableVoices(matchingLanguage: language)
    }

    View(ExpoMapboxNavigationView.self) {
      Events(
        "onRouteProgressChanged",
        "onCancelNavigation",
        "onWaypointArrival",
        "onFinalDestinationArrival",
        "onRouteChanged",
        "onUserOffRoute",
        "onRoutesLoaded",
        "onRouteFailedToLoad",
        "onNavigationStateChanged"
      )

      // ── Route Configuration ──────────────────────────────────────

      Prop("coordinates") { (view: ExpoMapboxNavigationView, coordinates: Array<Dictionary<String, Any>>) in
         var points: Array<CLLocationCoordinate2D> = []
         for coordinate in coordinates {
            let longValue = coordinate["longitude"]
            let latValue = coordinate["latitude"]
            if let long = longValue as? Double, let lat = latValue as? Double {
                points.append(CLLocationCoordinate2D(latitude: lat, longitude: long))
            }
          }
          view.controller.setCoordinates(coordinates: points)
      }

      Prop("vehicleMaxHeight") { (view: ExpoMapboxNavigationView, maxHeight: Double?) in
          view.controller.setVehicleMaxHeight(maxHeight: maxHeight)
      }

      Prop("vehicleMaxWidth") { (view: ExpoMapboxNavigationView, maxWidth: Double?) in
          view.controller.setVehicleMaxWidth(maxWidth: maxWidth)
      }

      Prop("locale") { (view: ExpoMapboxNavigationView, locale: String?) in
          view.controller.setLocale(locale: locale)
      }

      Prop("unitSystem") { (view: ExpoMapboxNavigationView, unitSystem: String?) in
          view.controller.setUnitSystem(unitSystem: unitSystem)
      }

      Prop("useRouteMatchingApi"){ (view: ExpoMapboxNavigationView, useRouteMatchingApi: Bool?) in
          view.controller.setIsUsingRouteMatchingApi(useRouteMatchingApi: useRouteMatchingApi)
      }

      Prop("waypointIndices"){ (view: ExpoMapboxNavigationView, indices: Array<Int>?) in
          view.controller.setWaypointIndices(waypointIndices: indices)
      }

      Prop("routeProfile"){ (view: ExpoMapboxNavigationView, profile: String?) in
          view.controller.setRouteProfile(profile: profile)
      }

      Prop("routeExcludeList"){ (view: ExpoMapboxNavigationView, excludeList: Array<String>?) in
          view.controller.setRouteExcludeList(excludeList: excludeList)
      }

      Prop("disableAlternativeRoutes") { (view: ExpoMapboxNavigationView, disableAlternativeRoutes: Bool?) in
        view.controller.setDisableAlternativeRoutes(disableAlternativeRoutes: disableAlternativeRoutes)
      }

      // ── Map Configuration ────────────────────────────────────────

      Prop("mapStyle"){ (view: ExpoMapboxNavigationView, style: String?) in
          view.controller.setMapStyle(style: style)
      }

      Prop("initialLocation") { (view: ExpoMapboxNavigationView, location: Dictionary<String, Any>?) in
        if(location != nil){
          let longValue = location!["longitude"]
          let latValue = location!["latitude"]
          let zoomValue = location!["zoom"]
          if let long = longValue as? Double, let lat = latValue as? Double, let zoom = zoomValue as? Double? {
              view.controller.setInitialLocation(location: CLLocationCoordinate2D(latitude: lat, longitude: long), zoom: zoom)
          }
        }
      }

      Prop("customRasterSourceUrl") { (view: ExpoMapboxNavigationView, url: String?) in
        view.controller.setCustomRasterSourceUrl(url: url)
      }

      Prop("placeCustomRasterLayerAbove") { (view: ExpoMapboxNavigationView, layerId: String?) in
        view.controller.setPlaceCustomRasterLayerAbove(layerId: layerId)
      }

      // ── Voice Configuration ──────────────────────────────────────

      Prop("mute"){ (view: ExpoMapboxNavigationView, isMuted: Bool?) in
          view.controller.setIsMuted(isMuted: isMuted)
      }

      Prop("voiceId"){ (view: ExpoMapboxNavigationView, voiceId: String?) in
          view.controller.setVoiceId(voiceId: voiceId)
      }

      // ── Camera Configuration ─────────────────────────────────────

      Prop("followingZoom") { (view: ExpoMapboxNavigationView, followingZoom: Double?) in
        view.controller.setFollowingZoom(followingZoom: followingZoom)
      }

      Prop("followingCameraPadding") { (view: ExpoMapboxNavigationView, padding: Dictionary<String, Double>?) in
        view.controller.setFollowingCameraPadding(padding: padding)
      }

      Prop("overviewCameraPadding") { (view: ExpoMapboxNavigationView, padding: Dictionary<String, Double>?) in
        view.controller.setOverviewCameraPadding(padding: padding)
      }

      // ── UI Visibility ────────────────────────────────────────────

      Prop("showTopBanner") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowTopBanner(show: show)
      }

      Prop("showBottomBanner") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowBottomBanner(show: show)
      }

      Prop("showCancelButton") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowCancelButton(show: show)
      }

      Prop("showSpeedLimit") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowSpeedLimit(show: show)
      }

      Prop("showSoundButton") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowSoundButton(show: show)
      }

      Prop("showOverviewButton") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowOverviewButton(show: show)
      }

      Prop("showRecenterButton") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowRecenterButton(show: show)
      }

      Prop("showManeuverArrow") { (view: ExpoMapboxNavigationView, show: Bool?) in
        view.controller.setShowManeuverArrow(show: show)
      }

      // ── UI Styling ───────────────────────────────────────────────

      Prop("topBannerBackgroundColor") { (view: ExpoMapboxNavigationView, color: String?) in
        view.controller.setTopBannerBackgroundColor(hexColor: color)
      }

      Prop("bottomBannerBackgroundColor") { (view: ExpoMapboxNavigationView, color: String?) in
        view.controller.setBottomBannerBackgroundColor(hexColor: color)
      }

      Prop("routeColor") { (view: ExpoMapboxNavigationView, color: String?) in
        view.controller.setRouteColor(hexColor: color)
      }

      Prop("routeAlternateColor") { (view: ExpoMapboxNavigationView, color: String?) in
        view.controller.setRouteAlternateColor(hexColor: color)
      }

      Prop("routeCasingColor") { (view: ExpoMapboxNavigationView, color: String?) in
        view.controller.setRouteCasingColor(hexColor: color)
      }

      Prop("traversedRouteColor") { (view: ExpoMapboxNavigationView, color: String?) in
        view.controller.setTraversedRouteColor(hexColor: color)
      }

      Prop("maneuverArrowColor") { (view: ExpoMapboxNavigationView, color: String?) in
        view.controller.setManeuverArrowColor(hexColor: color)
      }

      // ── Ref Methods ──────────────────────────────────────────────

      AsyncFunction("recenterMap") { (view: ExpoMapboxNavigationView) in
        view.controller.recenterMap()
      }

      AsyncFunction("showRouteOverview") { (view: ExpoMapboxNavigationView) in
        view.controller.showRouteOverview()
      }
    }
  }
}
