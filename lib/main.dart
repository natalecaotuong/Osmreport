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
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert' show json, base64, ascii;

LatLng _center = LatLng(38.19394, 15.55256);
const SERVER_IP =
    'https://osmreports-backend.herokuapp.com'; //'http://10.0.2.2:3000';
final storage = FlutterSecureStorage();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  Future<String> get jwtOrEmpty async {
    var jwt = await storage.read(key: "jwt");
    if (jwt == null) return "";
    return jwt;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSM reports',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
          future: jwtOrEmpty,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return CircularProgressIndicator();
            if (snapshot.data != "") {
              var str = snapshot.data;
              var jwt = str.split(".");

              if (jwt.length != 3) {
                return LoginPage();
              } else {
                var payload = json.decode(
                    ascii.decode(base64.decode(base64.normalize(jwt[1]))));
                if (DateTime.fromMillisecondsSinceEpoch(payload["exp"] * 1000)
                    .isAfter(DateTime.now())) {
                  return HomePage(str, payload);
                } else {
                  return LoginPage();
                }
              }
            } else {
              return LoginPage();
            }
          }),
    );
  }
}

class HomePage extends StatefulWidget {
  final String jwt;
  final Map<String, dynamic> payload;

  factory HomePage.fromBase64(String jwt) => HomePage(
      jwt,
      json.decode(
          ascii.decode(base64.decode(base64.normalize(jwt.split(".")[1])))));

  const HomePage(this.jwt, this.payload);

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
                  //_determinePosition();
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
          FutureBuilder(
              future: http.read('$SERVER_IP/data',
                  headers: {"Authorization": widget.jwt}),
              builder: (context, snapshot) => snapshot.hasData
                  ? Column(
                      children: <Widget>[
                        Text("Welcome " +
                            widget.payload[
                                'username']) /*,
                        Text(snapshot.data,
                            style: Theme.of(context).textTheme.headline4)*/
                      ],
                    )
                  : snapshot.hasError
                      ? Text("An error occurred")
                      : CircularProgressIndicator()),
          ElevatedButton(
            autofocus: false,
            clipBehavior: Clip.none,
            onPressed: () => _key.currentState.showButtonMenu(),
            child: Text('Select type of report'),
          ),
          SizedBox(
              height: 500,
              child: Zoom(
                  height: 1800,
                  width: 1800,
                  enableScroll: true,
                  doubleTapZoom: true,
                  initZoom: 0.0,
                  child: FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                        //controller: mapController, //25_09_21
                        center: _center,
                        //zoom: 13,
                        onTap: (latlng) {
                          setState(() {
                            //addPoint(latlng);
                            /*mapController.move(
                                LatLng(_center.latitude, _center.longitude),
                                13);*/
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
        mapController.move(LatLng(position.latitude, position.longitude), 15);
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

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
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

class LoginPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void displayDialog(context, title, text) => showDialog(
        context: context,
        builder: (context) =>
            AlertDialog(title: Text(title), content: Text(text)),
      );

  Future<String> attemptLogIn(String username, String password) async {
    var res = await http.post("$SERVER_IP/login",
        body: {"username": username, "password": password});
    if (res.statusCode == 200) return res.body;
    return null;
  }

  Future<int> attemptSignUp(String username, String password) async {
    var res = await http.post('$SERVER_IP/signup',
        body: {"username": username, "password": password});
    return res.statusCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Log In"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password'),
              ),
              TextButton(
                  onPressed: () async {
                    var username = _usernameController.text;
                    var password = _passwordController.text;
                    var jwt = await attemptLogIn(username, password);
                    if (jwt != null) {
                      storage.write(key: "jwt", value: jwt);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePage.fromBase64(jwt)));
                    } else {
                      displayDialog(context, "An Error Occurred",
                          "No account was found matching that username and password");
                    }
                  },
                  child: Text("Log In")),
              TextButton(
                  onPressed: () async {
                    var username = _usernameController.text;
                    var password = _passwordController.text;

                    if (username.length < 4)
                      displayDialog(context, "Invalid Username",
                          "The username should be at least 4 characters long");
                    else if (password.length < 4)
                      displayDialog(context, "Invalid Password",
                          "The password should be at least 4 characters long");
                    else {
                      var res = await attemptSignUp(username, password);
                      if (res == 201)
                        displayDialog(context, "Success",
                            "The user was created. Log in now.");
                      else if (res == 409)
                        displayDialog(
                            context,
                            "That username is already registered",
                            "Please try to sign up using another username or log in if you already have an account.");
                      else {
                        displayDialog(
                            context, "Error", "An unknown error occurred.");
                      }
                    }
                  },
                  child: Text("Sign Up"))
            ],
          ),
        ));
  }
}
