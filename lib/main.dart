import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(systemNavigationBarColor: Colors.blue));
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        appBarTheme: AppBarTheme(
            color: Colors.blue,
            titleTextStyle: TextStyle(color: Colors.black, fontSize: 20)),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.grey).copyWith(background: Colors.black, ),
        textTheme: TextTheme(bodyMedium: TextStyle(color: Colors.black)),
      ),
      home: const MyHomePage(title: 'Гонки разума'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool showDevices = false;
  List<BluetoothDiscoveryResult> results = <BluetoothDiscoveryResult>[];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double attention = 0;
  double meditation = 0;
  bool status = false;
  String json = "";
  String consoleOutput = "";

  void startDiscovery() {
    var streamSubscription = FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
        setState(() {
          results.add(r);
        });

    });

    streamSubscription.onDone(() {
      //Do something when the discovery process ends
    });
  }

  void findDevices(){
    results.clear();
    setState(() {
      startDiscovery();
    });
  }

  void connectedToDevice(String address, BuildContext context) async {
    // Some simplest connection :F
    //98:D3:31:FC:9B:DA
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress("98:D3:31:FC:9B:DA");
      print('Connected to the device');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Подключение к $address успешно!"), backgroundColor: Colors.green));
      setState(() {
        status = connection.isConnected;
      });

      final ByteData bytes = ByteData(20);
      final Uint8List list = bytes.buffer.asUint8List();
      final Uint8List list1 = Uint8List(500);

      connection.output.add(list);
      connection.input?.listen((list1) {
        setState(() {
          consoleOutput += ascii.decode(list1);
        });
        var temp = ascii.decode(list1);

        if (temp.contains("")){
          json += temp;
        }
        if (json[json.length-1] == "\n"){
          try{
            print(json.toString());
            Map<String, dynamic> map = jsonDecode(json.toString());
            setState(() {
              attention = double.parse(map["Attention"]);
              meditation = double.parse(map["Meditation"]);
            });
          }
          catch (exception) {
            json = '';
            print(exception);
          }
        }
      }).onDone(() {
        print('Disconnected by remote request');
        setState(() {
          status = connection.isConnected;
          attention = 0;
          meditation = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Машинка отключена"), backgroundColor: Colors.blue));
      });
    }
    catch (exception) {
      print('Cannot connect, exception occured');

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка! Переподключись!"), backgroundColor: Colors.red));
    }
  }

  Random r = Random();
  List<_SalesData> dynamicData = [];
  List<_SalesData> dynamicData2 = [];

  Stream<List<_SalesData>> _getStream() async* {
    while(true) {
      await Future.delayed(Duration(seconds: 1));
      if(dynamicData.length == 5) {
        dynamicData.removeAt(0);
        dynamicData2.removeAt(0);
        for(int i = 0; i<dynamicData.length; ++i) {
          dynamicData[i] = _SalesData(i.toDouble(), dynamicData[i].y);
          dynamicData2[i] = _SalesData(i.toDouble(), dynamicData2[i].y);
        }
      }
      dynamicData.add(_SalesData(dynamicData.length.toDouble(), attention));
      dynamicData2.add(_SalesData(dynamicData2.length.toDouble(), meditation)); // добавляем новое случайное значение в список второй линии

      yield dynamicData;
      yield dynamicData2;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if(!status)
                  ElevatedButton(onPressed: () => connectedToDevice("a", context), child: const Text("Подключиться к hc-06")),
                Text("Статус: ${status? "подключено": "отключено"}")
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Вращение левого колеса", style: TextStyle(fontSize: 24)),
                    Text(attention.toString(), style: TextStyle(fontSize: 24))
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Вращение правого колеса", style: TextStyle(fontSize: 24)),
                    Text(meditation.toString(), style: TextStyle(fontSize: 24))
                  ],
                ),
              ]),
            ),

            Container(
              margin: EdgeInsets.only(top: 40),
              child: Column(
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text("Логи", style: TextStyle(fontSize: 26),)),
                  Container(
                      height: 200,
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.all(Radius.circular(20))
                      ),
                      child: SingleChildScrollView(
                        child: Text(consoleOutput),
                      )
                  ),

                ],
              ),
            ),

            Container(
              child: StreamBuilder<List<_SalesData>>(
                  stream: _getStream(),
                  builder: (context, snapshot) {
                    if(snapshot.connectionState == ConnectionState.active) {
                      return SfCartesianChart(
                          isTransposed: false,
                          primaryXAxis: NumericAxis(
                            isVisible: false,
                          ),
                          tooltipBehavior: TooltipBehavior(enable: false),
                          series: <ChartSeries<_SalesData, double>>[
                            SplineSeries<_SalesData, double>(
                                dataSource: dynamicData,
                                xValueMapper: (_SalesData sales, _) => sales.x,
                                yValueMapper: (_SalesData sales, _) => sales.y,
                                name: 'Attention',
                                animationDuration: 0,
                                // Enable data label
                                dataLabelSettings: DataLabelSettings(isVisible: false)),
                            SplineSeries<_SalesData, double>( // новая линия
                                dataSource: dynamicData2, // второй список данных для второй линии
                                xValueMapper: (_SalesData sales, _) => sales.x,
                                yValueMapper: (_SalesData sales, _) => sales.y,
                                name: 'Meditation',
                                animationDuration: 0,
                                // Enable data label
                                dataLabelSettings: DataLabelSettings(isVisible: false))
                          ]);
                    }
                    return Center(child: CircularProgressIndicator());
                  }
              ),

            )



          ],
        ),
      ),
    );



  }
}


class _SalesData {
  _SalesData(this.x, this.y);
  final double x;
  final double y;

}