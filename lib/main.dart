import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:map_controller/map_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:osm_reports/icons.dart';
import 'package:popup_menu/popup_menu.dart';
import 'package:zoom_widget/zoom_widget.dart';
import 'custom_popup.dart';

LatLng _center = LatLng(38.19394, 15.55256);

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Marker> markers = [];
  int pointIndex;
  List points = [
    _center,
    LatLng(49.8566, 3.3522),
  ];

  MapController mapController;
  StatefulMapController statefulMapController;
  StreamSubscription<StatefulMapControllerStateChange> sub;
  Position _currentPosition;
  String _currentAddress;
  final GlobalKey<PopupMenuButtonState<int>> _key = GlobalKey();

  @override
  void initState() {
    pointIndex = 0;
    markers = [];
    /*
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: points[pointIndex],
        builder: (ctx) => Icon(Icons.pin_drop),
      ),
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: LatLng(53.3498, -6.2603),
        builder: (ctx) => Icon(Icons.pin_drop),
      ),
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: LatLng(53.3488, -6.2613),
        builder: (ctx) => Icon(Icons.pin_drop),
      ),
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: LatLng(53.3488, -6.2613),
        builder: (ctx) => Icon(Icons.pin_drop),
      ),
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: LatLng(48.8566, 2.3522),
        builder: (ctx) => Icon(Icons.pin_drop),
      ),
      Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        height: 30,
        width: 30,
        point: LatLng(49.8566, 3.3522),
        builder: (ctx) => Icon(Icons.pin_drop),
      ),
    ];*/

    mapController = MapController();
    statefulMapController = StatefulMapController(mapController: mapController);

    // wait for the controller to be ready before using it
    statefulMapController.onReady
        .then((_) => print("The map controller is ready"));

    /// [Important] listen to the changefeed to rebuild the map on changes:
    /// this will rebuild the map when for example addMarker or any method
    /// that mutates the map assets is called
    sub = statefulMapController.changeFeed.listen((change) => setState(() {}));
    super.initState();
  }

  // ignore: non_constant_identifier_names
  int selected_value = 0;
  List<int> marker_icon_value = [];

  void set_value(int value) {
    selected_value = value;
  }

  LatLng currentPoint;
  Marker marker(LatLng latlng) {
    Marker obj;
    marker_icon_value.add(selected_value);
    for (int i = 0; i < marker_icon_value.length; i++) {
      obj = Marker(
        width: 150.0,
        height: 150.0,
        point: latlng,
        builder: (ctx) => //Container(
            //child: get_icon(marker_icon_value[i]),
            GestureDetector(
                onDoubleTap: () {
                  setState(() {
                    if (key.currentState != null) {}
                    currentPoint = latlng;
                    infoWindowVisible = !infoWindowVisible;
                  });
                },
                onTap: () {
                  setState(() {});
                },
                child: _buildCustomMarker(
                    get_icon(marker_icon_value[i]), i, currentPoint == latlng)),
        //),
      );
    }
    //markers.add(obj);
    //

    return obj;
  }

  Icon get_icon(int i) {
    switch (i) {
      case 0:
        return Icon(
          MyFlutterApp.icons8_traffic_jam_24,
          color: Colors.red,
          size: 35.0,
        );
      case 1:
        return Icon(
          MyFlutterApp.noun_bulb_3508164,
          color: Colors.red,
          size: 35.0,
        );
      default:
        return Icon(
          MyFlutterApp.icons8_traffic_jam_24,
          color: Colors.red,
          size: 35.0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    PopupMenu.context = context;

    return Scaffold(
        appBar: AppBar(
          actions: [
            PopupMenuButton<int>(
              key: _key,
              onSelected: (value) {
                set_value(value);
              },
              itemBuilder: (context) {
                return <PopupMenuEntry<int>>[
                  PopupMenuItem(child: Text('Traffic jam'), value: 0),
                  PopupMenuItem(child: Text('Broken street lamp'), value: 1),
                ];
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_currentAddress != null) Text(_currentAddress),
              TextButton(
                child: Text("Get location"),
                onPressed: () {
                  _getCurrentLocation();
                },
              )
            ],
          ),
          onPressed: () {
            pointIndex++;
            if (pointIndex >= points.length) {
              pointIndex = 0;
            }
            setState(() {
              markers[0] = Marker(
                point: points[pointIndex],
                anchorPos: AnchorPos.align(AnchorAlign.center),
                height: 30,
                width: 30,
                builder: (ctx) => Icon(Icons.pin_drop),
              );

              // one of this
              markers = List.from(markers);
              // markers = [...markers];
              // markers = []..addAll(markers);
            });
          },
        ),
        body: Column(children: <Widget>[
          ElevatedButton(
            autofocus: false,
            clipBehavior: Clip.none,
            onPressed: () => _key.currentState.showButtonMenu(),
            child: Text('Select type of report'),
          ),
          SizedBox(
              height: 550,
              child: Zoom(
                  height: 1800,
                  width: 1800,
                  enableScroll: true,
                  doubleTapZoom: true,
                  initZoom: 0.0,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                        center: _center,
                        //zoom: 13,
                        onTap: (latlng) {
                          setState(() {
                            //addPoint(latlng);
                            markers.add(
                              marker(latlng),
                            );
                          });
                        }),
                    layers: [
                      TileLayerOptions(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: ['a', 'b', 'c']),
                      MarkerLayerOptions(
                        markers: //_buildMarkersOnMap()
                            [
                          for (int i = 0; i < markers.length; i++) markers[i]
                        ],
                      ),
                    ],
                  )))
        ]));
  }

  _getCurrentLocation() {
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        _getAddressFromLatLng();
        markers.add(Marker(
            point: LatLng(position.latitude, position.longitude),
            anchorPos: AnchorPos.align(AnchorAlign.center),
            height: 30,
            width: 30,
            builder: (ctx) => Icon(Icons.pin_drop)));
      });
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = placemarks[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print(e);
    }
  }

  addPoint(LatLng latlng) {
    points.add(latlng);
  }

  /*List<Marker> _buildMarkersOnMap() {
    List<Marker> markers = [];
    var marker = new Marker(
      point: points[points.length - 1],
      width: 279.0,
      height: 256.0,
      builder: (context) => _buildCustomMarker(
          get_icon(marker_icon_value[points.length - 1]), points.length - 1),
    );

    markers.add(marker);
    return markers;
  }*/

  var infoWindowVisible = false;
  /*List<GlobalKey<State>> josKeys = [
    for (int i = 0; i < markers.length; i++) new GlobalKey()
  ];*/
  GlobalKey<State> key = new GlobalKey();

  Stack _buildCustomMarker(Icon icon, int i, bool addPopUp) {
    return Stack(
      children: addPopUp == true
          ? <Widget>[popup(icon), get_marker(i)]
          : <Widget>[get_marker(i)],
    );
  }

  Opacity popup(Icon icon) {
    return Opacity(
        opacity: infoWindowVisible ? 1.0 : 0.0,
        child: Container(
          alignment: Alignment.bottomCenter,
          width: 279.0,
          height: 256.0,
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage("assets/images/ic_info_window.png"),
                  fit: BoxFit.cover)),
          child: CustomPopup(
            key: key,
            icon: icon,
          ),
        ));
  }

  Opacity get_marker(int i) {
    return Opacity(
      child: Container(
          alignment: Alignment.bottomCenter,
          child: get_icon(marker_icon_value[i])),
      opacity: infoWindowVisible ? 0.0 : 1.0,
    );
  }
}
