import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

String waqiAPIKey = "510c278e7faabc1d3b7624d63860cad35acab3f1";

class CityPM {
  final int aqi;
  final String cityName;

  CityPM({@required this.aqi, @required this.cityName});

  Map<String, dynamic> toMap() {
    return {
      'aqi': aqi,
      'cityName': cityName,
    };
  }

  factory CityPM.fromJson(Map<String, dynamic> json) {
    return CityPM(
      aqi: json['data']['aqi'],
      cityName: json['data']['city']['name'],
    );
  }
}

MqttBrowserClient client;
MqttConnectionState connectionState;
Future mqttFuture;
String locationListStr = '';

List<dynamic> coordinateList = <List<double>>[
  [47.916638882615025, 106.9225416482629],
  [40.24626993238064, -111.64780855178833]
];

onConnected() {
  print("HOLY CRAP THIS CONNECTED");
}

onDisconnected() {
  print("WTF IT DISCONNECTED");
  mqttFuture = _getMqtt();
}

onSubscribed(String sub) {
  print("We are subscribed to $sub");
}

_getMqtt() async {
  MqttBrowserClient client = await connect();
  return client;
}

Future<List<CityPM>> fetchAQI(List<dynamic> locations) async {
  mqttFuture.then((value) async =>
      await value.subscribe('aq_display/location_list', MqttQos.exactlyOnce));

  List<CityPM> cityList = <CityPM>[];

  for (int i = 0; i < locations.length; i++) {
    final response = await http.get(Uri.https(
        'api.waqi.info',
        'feed/geo:${locations[i][0]};${locations[i][1]}/',
        {"token": waqiAPIKey}));

    if (jsonDecode(response.body)["status"] == "error") {
      print("ERROR");
      cityList.add(CityPM(aqi: 999, cityName: "ERR - ${locations[i]}"));
    } else if (response.statusCode == 200) {
      cityList.add(CityPM.fromJson(jsonDecode(response.body)));
    } else {
      throw Exception('Failed to load album');
    }
  }

  return cityList;
}

Future<MqttBrowserClient> connect() async {
  MqttBrowserClient client = MqttBrowserClient(
      'wss://mqtt.eclipseprojects.io/mqtt',
      'hjkghjkghjdfh785467856785678578jghjhjkhkj968576543e65787');
  client.port = 443;
  client.logging(on: false);
  client.onConnected = onConnected;
  client.onDisconnected = onDisconnected;
  // client.autoReconnect = true;
  // client.onUnsubscribed = onUnsubscribed;
  client.onSubscribed = onSubscribed;
  client.keepAlivePeriod = 60;
  client.resubscribeOnAutoReconnect = true;
  // client.onSubscribeFail = onSubscribeFail;
  // client.pongCallback = pong;
  // client.on

  final connMessage = MqttConnectMessage()
      .withClientIdentifier(
          'hjkghjkghjdfh785467856785678578jghjhjkhkj968576543e65787')
      // .authenticateAs('username', 'password')
      .keepAliveFor(60)
      // .withWillTopic('willtopic')
      // .withWillMessage('Will message')
      .startClean()
      .withWillQos(MqttQos.exactlyOnce);
  client.connectionMessage = connMessage;

  try {
    await client.connect();
  } catch (e) {
    print('Exception: $e');
    client.disconnect();
  }

  client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage message = c[0].payload;

    final payload =
        MqttPublishPayload.bytesToStringAsString(message.payload.message);

    locationListStr = payload;
    var banana = jsonDecode(payload);
    coordinateList.clear();
    coordinateList = banana["locations"];

    // print('Received message: $payload from topic: ${c[0].topic}>');
  });

  return client;
}

void main() {
  mqttFuture = _getMqtt();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NET Lab - World Air Quality Index',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'NET Lab - World Air Quality Index'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<CityPM>> myCity;

  String _getAirType(int aqiVal) {
    String status;

    if (aqiVal >= 0 && aqiVal <= 50) {
      status = "Good";
    } else if (aqiVal >= 51 && aqiVal <= 100) {
      status = "Moderate";
    } else if (aqiVal >= 101 && aqiVal <= 150) {
      status = "High";
    } else if (aqiVal >= 151 && aqiVal <= 200) {
      status = "Unhealthy";
    } else if (aqiVal >= 201 && aqiVal <= 300) {
      status = "Very Unhealthy";
    } else if (aqiVal >= 301) {
      status = "Hazardous";
    } else {
      status = "ERROR";
    }

    return status;
  }

  Color _getTileColor(int aqiVal) {
    if (aqiVal >= 0 && aqiVal <= 50) return Colors.green;
    if (aqiVal >= 51 && aqiVal <= 100) return Colors.amber;
    if (aqiVal >= 101 && aqiVal <= 150) return Colors.orange;
    if (aqiVal >= 151 && aqiVal <= 200) return Colors.red;
    if (aqiVal >= 201 && aqiVal <= 300) return Colors.purple;
    if (aqiVal > 301) return Color.fromRGBO(128, 0, 0, 1);
    return Colors.white;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    mqttFuture.then((value) => value.disconnect());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      floatingActionButton: Container(
          color: Color.fromARGB(200, 255, 255, 255),
          child: Stack(children: [
            Padding(
                padding: EdgeInsets.fromLTRB(70, 15, 0, 20),
                child: Text("Add your own!",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            Padding(
                padding: EdgeInsets.all(35),
                child: QrImage(
                    data: "https://netlab.byu.edu/submit_pm/",
                    version: QrVersions.auto,
                    size: 200))
          ])),
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.width / 15,
        backgroundColor: Colors.white30,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: FittedBox(
            fit: BoxFit.fitWidth,
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Image.asset(
                'NET_Lab_Logo_v4.png',
                scale: 6,
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(50, 0, 0, 0),
                  child: Text(
                    widget.title,
                    style: TextStyle(color: Colors.white, fontSize: 45),
                  )),
              Padding(
                  padding: EdgeInsets.fromLTRB(900, 0, 0, 0),
                  child: Text(
                    "powered by EPA",
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ))
            ])),
      ),
      body: StreamBuilder(
          stream: Stream.periodic(Duration(seconds: 10)).asyncMap((event) =>
              // await mqttFuture.then((value) async => await value.subscribe(
              //     'aq_display/location_list', MqttQos.atLeastOnce));
              // print("Places: $locationListStr");
              // print(jsonDecode(locationListStr)["locations"]);
              fetchAQI(coordinateList)),
          builder: (context, snapshot) {
            print(snapshot.connectionState);
            if (snapshot.connectionState == ConnectionState.none)
              return Text("BANANA");
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.data == null) return Scaffold();
              return Center(
                // Center is a layout widget. It takes a single child and positions it
                // in the middle of the parent.
                child: GridView.builder(
                    primary: false,
                    padding: const EdgeInsets.all(20),
                    itemCount: snapshot.data.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0),
                    itemBuilder: (context, index) {
                      var place = snapshot.data[index];
                      return GridTile(
                          header: Container(
                            height: widget.,
                              padding: EdgeInsets.fromLTRB(5, 25, 5, 0),
                              alignment: Alignment.center,
                              child: Text(
                                place.cityName + " AQI",
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )),
                          footer: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.fromLTRB(5, 0, 5, 25),
                              child: FittedBox(
                                  fit: BoxFit.fitWidth,
                                  child: Text(
                                    _getAirType(place.aqi),
                                    style: TextStyle(
                                        fontSize: 50, color: Colors.white),
                                  ))),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8),
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  place.aqi.toString(),
                                  style: TextStyle(
                                      fontSize: 200, color: Colors.white),
                                )),
                            color: _getTileColor(place.aqi),
                          ));
                    }),
              );
            } else if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                // Center is a layout widget. It takes a single child and positions it
                // in the middle of the parent.
                child: GridView.builder(
                    primary: false,
                    padding: const EdgeInsets.all(20),
                    itemCount: 1,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0),
                    itemBuilder: (context, index) {
                      return GridTile(
                          child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        child: CircularProgressIndicator(),
                        color: Colors.white30,
                      ));
                    }),
              );
            } else {
              return null;
            }
          }),
    );
  }
}
