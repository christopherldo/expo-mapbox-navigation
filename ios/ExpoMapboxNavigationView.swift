import ExpoModulesCore
import MapboxNavigationCore
import MapboxMaps
import MapboxNavigationUIKit
import MapboxDirections
import Combine


class ExpoMapboxNavigationView: ExpoView {
    private let onRouteProgressChanged = EventDispatcher()
    private let onCancelNavigation = EventDispatcher()
    private let onWaypointArrival = EventDispatcher()
    private let onFinalDestinationArrival = EventDispatcher()
    private let onRouteChanged = EventDispatcher()
    private let onUserOffRoute = EventDispatcher()
    private let onRoutesLoaded = EventDispatcher()
    private let onRouteFailedToLoad = EventDispatcher()
    private let onNavigationStateChanged = EventDispatcher()

    let controller = ExpoMapboxNavigationViewController()

    required init(appContext: AppContext? = nil) {
        super.init(appContext: appContext)
        clipsToBounds = true
        addSubview(controller.view)

        controller.onRouteProgressChanged = onRouteProgressChanged
        controller.onCancelNavigation = onCancelNavigation
        controller.onWaypointArrival = onWaypointArrival
        controller.onFinalDestinationArrival = onFinalDestinationArrival
        controller.onRouteChanged = onRouteChanged
        controller.onUserOffRoute = onUserOffRoute
        controller.onRoutesLoaded = onRoutesLoaded
        controller.onRouteFailedToLoad = onRouteFailedToLoad
        controller.onNavigationStateChanged = onNavigationStateChanged
    }

    override func layoutSubviews() {
        controller.view.frame = bounds
    }
}


class ExpoMapboxNavigationViewController: UIViewController {
    static let navigationProvider: MapboxNavigationProvider = MapboxNavigationProvider(coreConfig: CoreConfig(routingConfig: RoutingConfig(fasterRouteDetectionConfig: Optional<FasterRouteDetectionConfig>.none),locationSource: .live ))
    var mapboxNavigation: MapboxNavigation? = nil
    var routingProvider: RoutingProvider? = nil
    var navigation: NavigationController? = nil
    var tripSession: SessionController? = nil
    var navigationViewController: NavigationViewController? = nil

    // ── Route Configuration State ──────────────────────────────────────
    var currentCoordinates: Array<CLLocationCoordinate2D>? = nil
    var initialLocation: CLLocationCoordinate2D? = nil
    var initialLocationZoom: Double? = nil
    var currentWaypointIndices: Array<Int>? = nil
    var currentLocale: Locale = Locale.current
    var currentRouteProfile: String? = nil
    var currentRouteExcludeList: Array<String>? = nil
    var currentMapStyle: String? = nil
    var currentCustomRasterSourceUrl: String? = nil
    var currentPlaceCustomRasterLayerAbove: String? = nil
    var currentDisableAlternativeRoutes: Bool? = nil
    var currentFollowingZoom: Double? = nil
    var isUsingRouteMatchingApi: Bool = false
    var vehicleMaxHeight: Double? = nil
    var vehicleMaxWidth: Double? = nil

    // ── UI Visibility State ────────────────────────────────────────────
    var showTopBanner: Bool = true
    var showBottomBanner: Bool = true
    var showCancelButton: Bool = true
    var showSpeedLimit: Bool = true
    var showSoundButton: Bool = true
    var showOverviewButton: Bool = true
    var showRecenterButton: Bool = true
    var showManeuverArrow: Bool = true

    // ── UI Styling State ───────────────────────────────────────────────
    var topBannerBackgroundColor: UIColor? = nil
    var bottomBannerBackgroundColor: UIColor? = nil
    var routeColor: UIColor? = nil
    var routeAlternateColor: UIColor? = nil
    var routeCasingColor: UIColor? = nil
    var traversedRouteColor: UIColor? = nil
    var maneuverArrowColor: String = "#FFFFFF"

    // ── Camera Padding State ───────────────────────────────────────────
    var followingCameraPadding: UIEdgeInsets? = nil
    var overviewCameraPadding: UIEdgeInsets? = nil

    // ── Event Dispatchers ──────────────────────────────────────────────
    var onRouteProgressChanged: EventDispatcher? = nil
    var onCancelNavigation: EventDispatcher? = nil
    var onWaypointArrival: EventDispatcher? = nil
    var onFinalDestinationArrival: EventDispatcher? = nil
    var onRouteChanged: EventDispatcher? = nil
    var onUserOffRoute: EventDispatcher? = nil
    var onRoutesLoaded: EventDispatcher? = nil
    var onRouteFailedToLoad: EventDispatcher? = nil
    var onNavigationStateChanged: EventDispatcher? = nil

    var calculateRoutesTask: Task<Void, Error>? = nil
    private var routeProgressCancellable: AnyCancellable? = nil
    private var waypointArrivalCancellable: AnyCancellable? = nil
    private var reroutingCancellable: AnyCancellable? = nil
    private var sessionCancellable: AnyCancellable? = nil
    private var cameraStateCancellable: AnyCancellable? = nil

    init() {
        super.init(nibName: nil, bundle: nil)
        mapboxNavigation = ExpoMapboxNavigationViewController.navigationProvider.mapboxNavigation
        routingProvider = mapboxNavigation!.routingProvider()
        navigation = mapboxNavigation!.navigation()
        tripSession = mapboxNavigation!.tripSession()

        routeProgressCancellable = navigation!.routeProgress.sink { progressState in
            if(progressState != nil){
                // Apply maneuver arrow color (or hide arrows entirely)
                if self.showManeuverArrow {
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next",
                        property: "line-color",
                        value: self.maneuverArrowColor
                    )
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next.stroke",
                        property: "line-color",
                        value: self.maneuverArrowColor
                    )
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next.symbol",
                        property: "icon-color",
                        value: self.maneuverArrowColor
                    )
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next.symbol.casing",
                        property: "icon-color",
                        value: self.maneuverArrowColor
                    )
                } else {
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next",
                        property: "visibility",
                        value: "none"
                    )
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next.stroke",
                        property: "visibility",
                        value: "none"
                    )
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next.symbol",
                        property: "visibility",
                        value: "none"
                    )
                    try? self.navigationViewController?.navigationMapView?.mapView.mapboxMap.setLayerProperty(
                        for: "com.mapbox.navigation.arrow.next.symbol.casing",
                        property: "visibility",
                        value: "none"
                    )
                }

                // Apply route line colors if configured
                self.applyRouteLineColors()

               self.onRouteProgressChanged?([
                    "distanceRemaining": progressState!.routeProgress.distanceRemaining,
                    "distanceTraveled": progressState!.routeProgress.distanceTraveled,
                    "durationRemaining": progressState!.routeProgress.durationRemaining,
                    "fractionTraveled": progressState!.routeProgress.fractionTraveled,
                ])
            }
        }

        waypointArrivalCancellable = navigation!.waypointsArrival.sink { arrivalStatus in
            let event = arrivalStatus.event
            if event is WaypointArrivalStatus.Events.ToFinalDestination {
                self.onFinalDestinationArrival?()
            } else if event is WaypointArrivalStatus.Events.ToWaypoint {
                self.onWaypointArrival?()
            }
        }

        reroutingCancellable = navigation!.rerouting.sink { rerouteStatus in
            self.onRouteChanged?()
        }

        sessionCancellable = tripSession!.session.sink { session in
            let state = session.state
            switch state {
                case .activeGuidance(let activeGuidanceState):
                    switch(activeGuidanceState){
                        case .offRoute:
                            self.onUserOffRoute?()
                        default: break
                    }
                default: break
            }
        }

    }

    deinit {
        routeProgressCancellable?.cancel()
        waypointArrivalCancellable?.cancel()
        reroutingCancellable?.cancel()
        sessionCancellable?.cancel()
        cameraStateCancellable?.cancel()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Task { @MainActor in tripSession?.setToIdle() } // Stops navigation
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("This controller should not be loaded through a story board")
    }

    // ── Route Line Color Helpers ───────────────────────────────────────

    private func applyRouteLineColors() {
        guard let mapboxMap = navigationViewController?.navigationMapView?.mapView.mapboxMap else { return }

        if let color = routeColor {
            try? mapboxMap.setLayerProperty(
                for: "com.mapbox.navigation.route.main",
                property: "line-color",
                value: color.hexString
            )
        }
        if let color = routeAlternateColor {
            try? mapboxMap.setLayerProperty(
                for: "com.mapbox.navigation.route.alternative",
                property: "line-color",
                value: color.hexString
            )
        }
        if let color = routeCasingColor {
            try? mapboxMap.setLayerProperty(
                for: "com.mapbox.navigation.route.main.casing",
                property: "line-color",
                value: color.hexString
            )
        }
        if let color = traversedRouteColor {
            try? mapboxMap.setLayerProperty(
                for: "com.mapbox.navigation.route.main.traversed",
                property: "line-color",
                value: color.hexString
            )
        }
    }

    // ── Custom Raster Layer ────────────────────────────────────────────

    func addCustomRasterLayer() {
        let navigationMapView = navigationViewController?.navigationMapView
        let sourceId = "raster-source"
        let layerId = "raster-layer"

        if(currentCustomRasterSourceUrl == nil){
            if let mapView = navigationMapView?.mapView.mapboxMap {
                if mapView.layerExists(withId: layerId) {
                    try? mapView.removeLayer(withId: layerId)
                }
                if mapView.sourceExists(withId: sourceId) {
                    try? mapView.removeSource(withId: sourceId)
                }
            }
            return
        }

        let sourceUrl = currentCustomRasterSourceUrl!

        var rasterSource = RasterSource(id: sourceId)

        rasterSource.tiles = [sourceUrl]
        rasterSource.tileSize = 256

        let rasterLayer = RasterLayer(id: layerId, source: sourceId)


        if let mapView = navigationMapView?.mapView.mapboxMap {
            if mapView.layerExists(withId: layerId) {
                try? mapView.removeLayer(withId: layerId)
            }
            if mapView.sourceExists(withId: sourceId) {
                try? mapView.removeSource(withId: sourceId)
            }

            try? mapView.addSource(rasterSource)
            try? mapView.addLayer(rasterLayer, layerPosition: .above(currentPlaceCustomRasterLayerAbove ?? "water"))
        }
    }

    // ── Route Configuration Setters ────────────────────────────────────

    func setCoordinates(coordinates: Array<CLLocationCoordinate2D>) {
        currentCoordinates = coordinates
        update()
    }

    func setVehicleMaxHeight(maxHeight: Double?) {
        vehicleMaxHeight = maxHeight
        update()
    }

    func setVehicleMaxWidth(maxWidth: Double?) {
        vehicleMaxWidth = maxWidth
        update()
    }

    func setLocale(locale: String?) {
        if(locale != nil){
            currentLocale = Locale(identifier: locale!)
        } else {
            currentLocale = Locale.current
        }
        update()
    }

    func setIsUsingRouteMatchingApi(useRouteMatchingApi: Bool?){
        isUsingRouteMatchingApi = useRouteMatchingApi ?? false
        update()
    }

    func setWaypointIndices(waypointIndices: Array<Int>?){
        currentWaypointIndices = waypointIndices
        update()
    }

    func setRouteProfile(profile: String?){
        currentRouteProfile = profile
        update()
    }

    func setRouteExcludeList(excludeList: Array<String>?){
        currentRouteExcludeList = excludeList
        update()
    }

    func setMapStyle(style: String?){
        currentMapStyle = style
        update()
    }

    func setCustomRasterSourceUrl(url: String?){
        currentCustomRasterSourceUrl = url
        update()
    }

    func setPlaceCustomRasterLayerAbove(layerId: String?){
        currentPlaceCustomRasterLayerAbove = layerId
        update()
    }

    func setDisableAlternativeRoutes(disableAlternativeRoutes: Bool?){
        currentDisableAlternativeRoutes = disableAlternativeRoutes
        update()
    }

    // ── Camera / Map Methods ───────────────────────────────────────────

    func recenterMap(){
        let navigationMapView = navigationViewController?.navigationMapView
        navigationMapView?.navigationCamera.update(cameraState: .following)
    }

    func showRouteOverview(){
        let navigationMapView = navigationViewController?.navigationMapView
        navigationMapView?.navigationCamera.update(cameraState: .overview)
    }

    func setIsMuted(isMuted: Bool?){
        if(isMuted != nil){
            ExpoMapboxNavigationViewController.navigationProvider.routeVoiceController.speechSynthesizer.muted = isMuted!
        }
    }

    func setInitialLocation(location: CLLocationCoordinate2D, zoom: Double?){
        initialLocation = location
        initialLocationZoom = zoom
        let navigationMapView = navigationViewController?.navigationMapView
        if(initialLocation != nil && navigationMapView != nil){
            navigationMapView!.mapView.mapboxMap.setCamera(to: CameraOptions(center: initialLocation!, zoom: initialLocationZoom ?? 15))
        }
    }

    func setFollowingZoom(followingZoom: Double?){
        let navigationMapView = navigationViewController?.navigationMapView
        currentFollowingZoom = followingZoom
        if(navigationMapView != nil && followingZoom != nil){
            let newDataSource = MobileViewportDataSource(navigationMapView!.mapView)
            newDataSource.options.followingCameraOptions.zoomRange = followingZoom!...followingZoom!
            navigationMapView?.navigationCamera.viewportDataSource = newDataSource
        }
    }

    func setFollowingCameraPadding(padding: Dictionary<String, Double>?) {
        guard let padding = padding else {
            followingCameraPadding = nil
            return
        }
        followingCameraPadding = UIEdgeInsets(
            top: CGFloat(padding["top"] ?? 0),
            left: CGFloat(padding["left"] ?? 0),
            bottom: CGFloat(padding["bottom"] ?? 0),
            right: CGFloat(padding["right"] ?? 0)
        )
        applyCameraPadding()
    }

    func setOverviewCameraPadding(padding: Dictionary<String, Double>?) {
        guard let padding = padding else {
            overviewCameraPadding = nil
            return
        }
        overviewCameraPadding = UIEdgeInsets(
            top: CGFloat(padding["top"] ?? 0),
            left: CGFloat(padding["left"] ?? 0),
            bottom: CGFloat(padding["bottom"] ?? 0),
            right: CGFloat(padding["right"] ?? 0)
        )
        applyCameraPadding()
    }

    private func applyCameraPadding() {
        guard let navigationMapView = navigationViewController?.navigationMapView else { return }
        guard let viewportDataSource = navigationMapView.navigationCamera.viewportDataSource as? MobileViewportDataSource else { return }

        if let padding = followingCameraPadding {
            viewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = true
            navigationMapView.navigationCamera.viewportDataSource = viewportDataSource
            let cameraOptions = CameraOptions(padding: padding)
            navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
        }
    }

    // ── UI Visibility Setters ──────────────────────────────────────────

    func setShowTopBanner(show: Bool?) {
        showTopBanner = show ?? true
        applyUIVisibility()
    }

    func setShowBottomBanner(show: Bool?) {
        showBottomBanner = show ?? true
        applyUIVisibility()
    }

    func setShowCancelButton(show: Bool?) {
        showCancelButton = show ?? true
        applyUIVisibility()
    }

    func setShowSpeedLimit(show: Bool?) {
        showSpeedLimit = show ?? true
        applyUIVisibility()
    }

    func setShowSoundButton(show: Bool?) {
        showSoundButton = show ?? true
        applyUIVisibility()
    }

    func setShowOverviewButton(show: Bool?) {
        showOverviewButton = show ?? true
        applyUIVisibility()
    }

    func setShowRecenterButton(show: Bool?) {
        showRecenterButton = show ?? true
        applyUIVisibility()
    }

    func setShowManeuverArrow(show: Bool?) {
        showManeuverArrow = show ?? true
        // Arrow visibility is applied in the routeProgress sink
    }

    private func applyUIVisibility() {
        guard let navVC = navigationViewController else { return }
        let navView = navVC.navigationView

        // Top banner
        navView.topBannerContainerView.isHidden = !showTopBanner

        // Bottom banner (includes cancel button)
        navView.bottomBannerContainerView.isHidden = !showBottomBanner

        // Speed limit
        navView.speedLimitView.isHidden = !showSpeedLimit

        // Cancel button (within bottom banner)
        if showBottomBanner {
            let cancelButtons = navView.bottomBannerContainerView.findViews(subclassOf: CancelButton.self)
            for button in cancelButtons {
                button.isHidden = !showCancelButton
            }
        }

        // Keep way name visible
        navView.wayNameView.isHidden = false
    }

    // ── UI Styling Setters ─────────────────────────────────────────────

    func setTopBannerBackgroundColor(hexColor: String?) {
        topBannerBackgroundColor = hexColor != nil ? UIColor(hex: hexColor!) : nil
        applyUIStyles()
    }

    func setBottomBannerBackgroundColor(hexColor: String?) {
        bottomBannerBackgroundColor = hexColor != nil ? UIColor(hex: hexColor!) : nil
        applyUIStyles()
    }

    func setRouteColor(hexColor: String?) {
        routeColor = hexColor != nil ? UIColor(hex: hexColor!) : nil
    }

    func setRouteAlternateColor(hexColor: String?) {
        routeAlternateColor = hexColor != nil ? UIColor(hex: hexColor!) : nil
    }

    func setRouteCasingColor(hexColor: String?) {
        routeCasingColor = hexColor != nil ? UIColor(hex: hexColor!) : nil
    }

    func setTraversedRouteColor(hexColor: String?) {
        traversedRouteColor = hexColor != nil ? UIColor(hex: hexColor!) : nil
    }

    func setManeuverArrowColor(hexColor: String?) {
        maneuverArrowColor = hexColor ?? "#FFFFFF"
    }

    private func applyUIStyles() {
        guard let navVC = navigationViewController else { return }
        let navView = navVC.navigationView

        if let color = topBannerBackgroundColor {
            navView.topBannerContainerView.backgroundColor = color
        }

        if let color = bottomBannerBackgroundColor {
            navView.bottomBannerContainerView.backgroundColor = color
        }
    }

    // ── Route Calculation ──────────────────────────────────────────────

    func update(){
        calculateRoutesTask?.cancel()

        if(currentCoordinates != nil){
            let waypoints = currentCoordinates!.enumerated().map {
                let index = $0
                let coordinate = $1
                var waypoint = Waypoint(coordinate: coordinate)
                waypoint.separatesLegs = currentWaypointIndices == nil ? true : currentWaypointIndices!.contains(index)
                return waypoint
            }

            if(isUsingRouteMatchingApi){
                calculateMapMatchingRoutes(waypoints: waypoints)
            } else {
                calculateRoutes(waypoints: waypoints)
            }
        }
    }

    func calculateRoutes(waypoints: Array<Waypoint>){
        let routeOptions = NavigationRouteOptions(
            waypoints: waypoints,
            profileIdentifier: currentRouteProfile != nil ? ProfileIdentifier(rawValue: currentRouteProfile!) : nil,
            queryItems: [
                URLQueryItem(name: "exclude", value: currentRouteExcludeList?.joined(separator: ",")),
                URLQueryItem(name: "max_height", value: String(format: "%.1f", vehicleMaxHeight ?? 0.0)),
                URLQueryItem(name: "max_width", value: String(format: "%.1f", vehicleMaxWidth ?? 0.0))
            ],
            locale: currentLocale,
            distanceUnit: currentLocale.usesMetricSystem ? LengthFormatter.Unit.meter : LengthFormatter.Unit.mile
        )

        calculateRoutesTask = Task {
            switch await self.routingProvider!.calculateRoutes(options: routeOptions).result {
            case .failure(let error):
                onRouteFailedToLoad?([
                    "errorMessage": error.localizedDescription
                ])
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                onRoutesCalculated(navigationRoutes: navigationRoutes)
            }
        }
    }

    func calculateMapMatchingRoutes(waypoints: Array<Waypoint>){
        let matchOptions = NavigationMatchOptions(
            waypoints: waypoints,
            profileIdentifier: currentRouteProfile != nil ? ProfileIdentifier(rawValue: currentRouteProfile!) : nil,
            queryItems: [URLQueryItem(name: "exclude", value: currentRouteExcludeList?.joined(separator: ","))],
            distanceUnit: currentLocale.usesMetricSystem ? LengthFormatter.Unit.meter : LengthFormatter.Unit.mile
        )
        matchOptions.locale = currentLocale


        calculateRoutesTask = Task {
            switch await self.routingProvider!.calculateRoutes(options: matchOptions).result {
            case .failure(let error):
                onRouteFailedToLoad?([
                    "errorMessage": error.localizedDescription
                ])
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                onRoutesCalculated(navigationRoutes: navigationRoutes)
            }
        }
    }

    @objc func cancelButtonClicked(_ sender: AnyObject?) {
        onCancelNavigation?()
    }

    func convertRoute(route: Route) -> Any {
        return [
            "distance": route.distance,
            "expectedTravelTime": route.expectedTravelTime,
            "legs": route.legs.map { leg in
                return [
                    "source": leg.source != nil ? [
                        "latitude": leg.source!.coordinate.latitude,
                        "longitude": leg.source!.coordinate.longitude
                    ] : nil,
                    "destination": leg.destination != nil ? [
                        "latitude": leg.destination!.coordinate.latitude,
                        "longitude": leg.destination!.coordinate.longitude
                    ] : nil,
                    "steps": leg.steps.map { step in
                        return [
                            "shape": step.shape != nil ? [
                                "coordinates": step.shape!.coordinates.map { coordinate in
                                    return [
                                        "latitude": coordinate.latitude,
                                        "longitude": coordinate.longitude,
                                    ]
                                }
                            ] : nil
                        ]
                    }
                ]
            }
        ]
    }

    func onRoutesCalculated(navigationRoutes: NavigationRoutes){
        onRoutesLoaded?([
            "routes": [
                "mainRoute": convertRoute(route: navigationRoutes.mainRoute.route),
                "alternativeRoutes": navigationRoutes.alternativeRoutes.map { convertRoute(route: $0.route) }
            ]
        ])

        let topBanner = TopBannerViewController()
        topBanner.instructionsBannerView.distanceFormatter.locale = currentLocale
        let bottomBanner = BottomBannerViewController()
        bottomBanner.distanceFormatter.locale = currentLocale
        bottomBanner.dateFormatter.locale = currentLocale

        let navigationOptions = NavigationOptions(
            mapboxNavigation: self.mapboxNavigation!,
            voiceController: ExpoMapboxNavigationViewController.navigationProvider.routeVoiceController,
            eventsManager: ExpoMapboxNavigationViewController.navigationProvider.eventsManager(),
            styles: [DayStyle()],
            topBanner: topBanner,
            bottomBanner: bottomBanner
        )

        let newNavigationControllerRequired = navigationViewController == nil

        if(newNavigationControllerRequired){
            navigationViewController = NavigationViewController(
                navigationRoutes: navigationRoutes,
                navigationOptions: navigationOptions
            )
        } else {
            navigationViewController!.prepareViewLoading(
                navigationRoutes: navigationRoutes,
                navigationOptions: navigationOptions
            )
        }

        let navigationViewController = navigationViewController!

        navigationViewController.showsContinuousAlternatives = currentDisableAlternativeRoutes != true
        navigationViewController.usesNightStyleWhileInTunnel = false
        navigationViewController.automaticallyAdjustsStyleForTimeOfDay = false

        let navigationMapView = navigationViewController.navigationMapView
        navigationMapView!.puckType = .puck2D(.navigationDefault)

        if(initialLocation != nil && newNavigationControllerRequired){
            navigationMapView!.mapView.mapboxMap.setCamera(to: CameraOptions(center: initialLocation!, zoom: initialLocationZoom ?? 15))
        }

        let style = currentMapStyle != nil ? StyleURI(rawValue: currentMapStyle!) : StyleURI.streets
        navigationMapView!.mapView.mapboxMap.loadStyle(style!, completion: { _ in
            navigationMapView!.localizeLabels(locale: self.currentLocale)
            do{
                try navigationMapView!.mapView.mapboxMap.localizeLabels(into: self.currentLocale)
            } catch {}
            self.addCustomRasterLayer()
        })


        let cancelButton = navigationViewController.navigationView.bottomBannerContainerView.findViews(subclassOf: CancelButton.self)[0]
        cancelButton.addTarget(self, action: #selector(cancelButtonClicked), for: .touchUpInside)

        // Observe camera state changes via Combine
        cameraStateCancellable?.cancel()
        cameraStateCancellable = navigationMapView?.navigationCamera.$state.sink { [weak self] state in
            guard let self = self else { return }
            let stateString: String
            switch state {
            case .idle:
                stateString = "idle"
            case .following:
                stateString = "following"
            case .overview:
                stateString = "overview"
            @unknown default:
                stateString = "idle"
            }
            self.onNavigationStateChanged?(["state": stateString])
        }

        navigationViewController.delegate = self
        addChild(navigationViewController)
        view.addSubview(navigationViewController.view)
        navigationViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            navigationViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            navigationViewController.view.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            navigationViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
        ])
        didMove(toParent: self)
        mapboxNavigation!.tripSession().startActiveGuidance(with: navigationRoutes, startLegIndex: 0)

        // Apply UI visibility and styles after navigation view is set up
        applyUIVisibility()
        applyUIStyles()

        // Apply camera padding if configured
        if let padding = followingCameraPadding {
            if let viewportDataSource = navigationMapView?.navigationCamera.viewportDataSource as? MobileViewportDataSource {
                viewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = true
            }
        }
    }
}

// MARK: - NavigationViewControllerDelegate
extension ExpoMapboxNavigationViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route) {
        onRoutesLoaded?([
            "routes": [
                "mainRoute": convertRoute(route: route),
                "alternativeRoutes": []
            ]
        ])
    }

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) { }
}

// MARK: - UIColor hex extension
extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
                blue: CGFloat(rgb & 0x0000FF) / 255.0,
                alpha: 1.0
            )
        } else if length == 8 {
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255.0,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255.0,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255.0,
                alpha: CGFloat(rgb & 0x000000FF) / 255.0
            )
        } else {
            return nil
        }
    }

    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - UIView helpers
extension UIView {
    func findViews<T: UIView>(subclassOf: T.Type) -> [T] {
        return recursiveSubviews.compactMap { $0 as? T }
    }

    var recursiveSubviews: [UIView] {
        return subviews + subviews.flatMap { $0.recursiveSubviews }
    }
}
