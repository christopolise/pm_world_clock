import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
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
  List<String> places = [
    "athens",
    "provo",
    "ulaanbaatar",
    "moscow",
    "paris",
    "thessaloniki",
    "shanghai",
    "russia",
    "berlin",
    "mexico",
    "johannesburg",
    "guangzhou",
    "brazil",
    "chad",
    "kazakhstan"
  ];

  Future<List<CityPM>> fetchAQI(List<String> locations) async {
    List<CityPM> cityList = <CityPM>[];

    for (int i = 0; i < locations.length; i++) {
      final response = await http.get(Uri.https(
          'api.waqi.info', 'feed/${locations[i]}/', {"token": waqiAPIKey}));

      if (jsonDecode(response.body)["status"] == "error") {
        cityList.add(CityPM(aqi: 999, cityName: "ERR - ${locations[i]}"));
      } else if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        cityList.add(CityPM.fromJson(jsonDecode(response.body)));
      } else {
        // If the server did not return a 200 OK response,
        // then throw an exception.
        throw Exception('Failed to load album');
      }
    }

    return cityList;
  }

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
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
                    data: "Under Construction. Coming Soon!",
                    version: QrVersions.auto,
                    size: 200))
          ])),
      appBar: AppBar(
        toolbarHeight: 110,
        backgroundColor: Colors.white30,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
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
        ]),
      ),
      body: StreamBuilder(
          stream: Stream.periodic(Duration(seconds: 2))
              .asyncMap((event) => fetchAQI(places)),
          builder: (context, snapshot) {
            if (snapshot.data == ConnectionState.none) return Text("BANANA");
            if (snapshot.connectionState == ConnectionState.active) {
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
                              padding: EdgeInsets.fromLTRB(0, 25, 0, 0),
                              alignment: Alignment.center,
                              child: Text(
                                place.cityName + " AQI",
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white),
                              )),
                          footer: Container(
                              alignment: Alignment.center,
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 25),
                              child: Text(
                                _getAirType(place.aqi),
                                style: TextStyle(
                                    fontSize: 50, color: Colors.white),
                              )),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              place.aqi.toString(),
                              style:
                                  TextStyle(fontSize: 200, color: Colors.white),
                            ),
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
