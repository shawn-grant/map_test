import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:map_test/osrm_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenMaps Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  static const maxZoom = 18.4,
      minZoom = 17.8,
      nearbyDistance = 30,
      arrivalDistance = 15;
  bool _isNearby = false;
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late Location location;
  late StreamSubscription<LocationData> positionStream;
  late MapController mapController;
  // LatLng destination = LatLng(18.017947, -76.743655); // utech
  LatLng destination = LatLng(17.933893, -76.901083); //
  late LatLng? myPosition, startPosition;

  double distanceBetweenPoints = 1000,
      bearingToDestination = 0,
      compassDirection = 0;
  String directionText = '';
  List<LatLng>? polylines;

  @override
  void dispose() {
    positionStream.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    location = Location();
    mapController = MapController();
    myPosition = null;

    location.changeSettings(interval: 500);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await getPermissions();
      await setupMap();
    });
  }

  Future<void> getPermissions() async {
    log('requestion permissions annd service');

    _permissionGranted = await location.hasPermission();

    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();

      if (_permissionGranted == PermissionStatus.denied) {
        // your App should show an explanatory UI now.
        // return Future.error('Location permissions are denied');
      }
    }

    _serviceEnabled = await location.serviceEnabled();

    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();

      // show UI asking for service
    }

    setState(() {
      _serviceEnabled;
      _permissionGranted;
    });
  }

  Future<void> setupMap() async {
    log('getting map data....');
    if (!_serviceEnabled || _permissionGranted != PermissionStatus.granted) {
      log('no permissions, quitting');
      return;
    }

    var locationData = await location.getLocation();
    myPosition = LatLng(locationData.latitude!, locationData.longitude!);
    startPosition = myPosition;

    // get route to destination
    polylines = await ApiOSRM().getpoints(
      myPosition!.longitude.toString(),
      myPosition!.latitude.toString(),
      destination.longitude.toString(),
      destination.latitude.toString(),
    );

    if (polylines == null) {
      // alert route could not be found
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("No Route Found"),
          content: Text(
              "We couldn't find a route to your destination. Check your internet connection"),
        ),
      );
    }

    setState(() {
      myPosition;
      polylines;
    });

    positionStream = location.onLocationChanged.listen(
      (LocationData? event) {
        myPosition = LatLng(event!.latitude!, event.longitude!);

        // get distance to destination
        distanceBetweenPoints = Geolocator.distanceBetween(
          myPosition!.latitude,
          myPosition!.longitude,
          destination.latitude,
          destination.longitude,
        );

        bearingToDestination = Geolocator.bearingBetween(
          myPosition!.latitude,
          myPosition!.longitude,
          destination.latitude,
          destination.longitude,
        );

        compassDirection = (bearingToDestination + mapController.rotation);
        if (compassDirection < 0) compassDirection = 360 + compassDirection;
        compassDirection /= 360;

        if (compassDirection >= 0.875 || compassDirection <= 0.125) {
          directionText = "Just Ahead";
        } else if (compassDirection >= 0.125 && compassDirection <= 0.375) {
          directionText = "To The Right";
        } else if (compassDirection >= 0.375 && compassDirection <= 0.625) {
          directionText = "Behind You!";
        } else {
          directionText = "On Your Left";
        }

        // update the states
        setState(() {
          myPosition;
          distanceBetweenPoints;
          bearingToDestination;
          compassDirection;
        });

        if (distanceBetweenPoints <= nearbyDistance) {
          // WE ARE NEARBY, SHOW COMPASS VIEW
          setState(() => _isNearby = true);
        } else {
          // NOT CLOSE, HIDE COMPASS IF SHOWING
          // setState(() => _isNearby = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 0,
      ),
      body: Column(
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: (myPosition != null)
                ? FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      maxZoom: maxZoom,
                      minZoom: minZoom,
                      center: myPosition,
                      plugins: const [
                        LocationMarkerPlugin(
                          turnOnHeadingUpdate: TurnOnHeadingUpdate.always,
                          centerOnLocationUpdate: CenterOnLocationUpdate.always,
                        ),
                      ],
                    ),
                    nonRotatedChildren: [
                      // we must give attribution to the developers
                      AttributionWidget(
                        attributionBuilder: (BuildContext context) => Container(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                          color: const Color.fromARGB(85, 0, 0, 0),
                          child: const Text(
                            "© OpenStreetMap contributors",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      AttributionWidget(
                        alignment: Alignment.bottomLeft,
                        attributionBuilder: (BuildContext context) => Container(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                          color: const Color.fromARGB(85, 0, 0, 0),
                          child: const Text(
                            "flutter_map",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                    layers: [
                      TileLayerOptions(
                        // use this for dark map
                        // 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
                        urlTemplate:
                            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                        userAgentPackageName:
                            'dev.fleaflet.flutter_map.example',
                        evictErrorTileStrategy:
                            EvictErrorTileStrategy.notVisible,
                      ),
                      PolylineLayerOptions(
                        polylineCulling: true,
                        polylines: [
                          if (polylines != null)
                            Polyline(
                              points: polylines!,
                              strokeWidth: 6,
                              gradientColors: [
                                Colors.blue,
                                Colors.deepPurple,
                                Colors.red,
                              ],
                              strokeJoin: StrokeJoin.bevel,
                            ),
                          if (polylines != null)
                            Polyline(
                              points: [polylines!.last, destination],
                              strokeWidth: 6,
                              isDotted: true,
                              color: Colors.red,
                            ),
                          if (polylines != null)
                            Polyline(
                              points: [startPosition!, polylines!.first],
                              strokeWidth: 6,
                              isDotted: true,
                              color: Colors.blue,
                            ),
                        ],
                      ),
                      MarkerLayerOptions(
                        rotate: true,
                        markers: [
                          Marker(
                            point: destination,
                            builder: (BuildContext context) => const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                      LocationMarkerLayerOptions(),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(),
                      Text(
                        'GETTING LOCATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: _isNearby ? MediaQuery.of(context).size.height * 0.6 : 80,
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide()),
              color: Colors.white,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${distanceBetweenPoints.round()} m Away',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.blue,
                  ),
                ),
                if (_isNearby)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedRotation(
                          curve: Curves.easeInOut,
                          duration: const Duration(milliseconds: 400),
                          turns: compassDirection,
                          child: Image.asset(
                            'assets/images/spinning_rocket.gif',
                            // Icons.arrow_upward_rounded,
                            width: 200,
                            height: 200,
                          ),
                        ),
                        const Text(
                          "You're Near!",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          directionText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // log(polylines.toString());
          // recenter the map
          if (myPosition != null) {
            mapController.move(myPosition!, maxZoom);
          }

          setState(() => _isNearby = !_isNearby);
        },
        tooltip: 'Re-center',
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
