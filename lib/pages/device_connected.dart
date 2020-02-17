import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:math';
import 'package:linalg/linalg.dart';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';


class DeviceConnected extends StatefulWidget {
  DeviceConnected({Key key, this.device}) : super(key: key);



  final BluetoothDevice device;

  @override
  _DeviceConnectedState createState() => _DeviceConnectedState();
}

class _DeviceConnectedState extends State<DeviceConnected> with TickerProviderStateMixin{

  AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration : Duration(milliseconds: 1000),
      lowerBound: 0.1,

    )..forward();

    readFileAsync('assets/convMat.json').then((val)=> _assignConvMat(val['convMat'])) ;
    readFileAsync('assets/transMat.json').then((val){
      _assignTransMat(val['transMat']);
    });
    readFileAsync('assets/convMat2.json').then((val){
      _assignConv2Mat(val['convMat2']);
    });

    chartData.add(FlSpot(0.0, 0.0));
    readingSpectrum = false;
    currentSPM.add(0.01);
    luxData = [0,0,0,0,0,0];
    CCTData = [0,0,0];
    _characteristicSet = false;
    _deviceConnectedAndReady = false;

    _controller.addListener(() {
      setState(() {
        spotSize = _controller.value*10;
      });
    }
    );
    _controller.addStatusListener((status) {
      setState(() {
        if (status == AnimationStatus.completed) {
          _controller.repeat();
        } /*else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }*/
      });
    });

    ///connect to device and discover services
    widget.device.connect().then((val) {
      widget.device.state.listen((BluetoothDeviceState connectionState){
        switch (connectionState) {
          case BluetoothDeviceState.connected:

            print("Connected!");
            ///search for services
            widget.device.discoverServices().then((val){

              widget.device.services.listen( (List<BluetoothService> bluetoothServices) {
                bluetoothServices.forEach((service){
                  List<BluetoothCharacteristic> bluetoothCharacteristics;
                  bluetoothCharacteristics = service.characteristics;
                  bluetoothCharacteristics.forEach((characteristic){
                    if (characteristic.uuid.toString().contains('0000cccc-5555-8888-2299-ba0987654321')){
                      print("Correct Service and characterisic found!");
                      deviceCharacteristic = characteristic;
                      characteristic.setNotifyValue(true).then((val){
                        _deviceConnectedAndReady = true;
                        print("Notification Set!");
                      });

                    }
                  });
                });
              });
            });
            break;
          case BluetoothDeviceState.disconnected:
            print("DisConnected");
            break;
          default:
            print("Connecting");
            break;
        }
      });
    });



  }


  List<double> currentSPM = [];
  int testVal;
  List<FlSpot> chartData = [];
  List<dynamic> convMat;
  List<dynamic> convMat2;
  List<dynamic> transMat;
  bool _characteristicSet;
  Future <String> data;
  bool loading = true;
  bool readingSpectrum ;
  List<double> luxData;
  List<double> CCTData;
  List<charts.Series<dynamic, String>> barData;
  bool _isLoading (){
    setState(() {

    });
    return loading;
  }
  double spotSize;
  bool _deviceConnectedAndReady;
  BluetoothCharacteristic deviceCharacteristic;
  void _assignConvMat(List<dynamic> val){
    setState(() {
      convMat = val;
    });
  }
  void _assignTransMat(List<dynamic> val){
    setState(() {
      transMat = val;
    });
  }
  void _assignConv2Mat(List<dynamic> val){
    setState(() {
      convMat2 = val;
    });
  }

  List<int> allValues;

  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];

  LineChartData mainData() {
    return LineChartData(
//      gridData: FlGridData(
//        show: true,
//        drawVerticalLine: true,
//        getDrawingHorizontalLine: (value) {
//          return const FlLine(
//            color: Color(0xff37434d),
//            strokeWidth: 1,
//          );
//        },
//        getDrawingVerticalLine: (value) {
//          return const FlLine(
//            color: Color(0xff37434d),
//            strokeWidth: 1,
//          );
//        },
//      ),

      axisTitleData: FlAxisTitleData(
        bottomTitle: AxisTitle(
          showTitle: true,
            textStyle:
            TextStyle(color: const Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
          titleText: "Wavelength /nm"
        ),
        leftTitle: AxisTitle(
            showTitle: false,
            textStyle:
            TextStyle(color: const Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
            titleText: "Irradiance W/m2/nm"
        ),
      ),
      titlesData: FlTitlesData(
        show: false,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle:
          TextStyle(color: const Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
          getTitles: (value) {
            switch (value.toInt()) {
              case 5:
                return 'Wavelength/nm';
            }
            return '';
          },
          margin: 8,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          textStyle: TextStyle(
            color: const Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '10k';
              case 3:
                return '30k';
              case 5:
                return '50k';
            }
            return '';
          },
          reservedSize: 28,
          margin: 12,
        ),
      ),
      borderData:
      FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 360,
      maxX: 780,
      minY: 0,
      maxY: (currentSPM != null) ? currentSPM.reduce(max): 1.0,
      lineBarsData: [
        LineChartBarData(
          spots: chartData,
          isCurved: true,
          colors: [ Colors.purpleAccent,Colors.indigo, Colors.blue, Colors.green,  Colors.yellow, Colors.orange,Colors.red ],
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            colors: [ Colors.purpleAccent,Colors.indigo, Colors.blue, Colors.green,  Colors.yellow, Colors.orange,Colors.red ].map((color) => color.withOpacity(0.9)).toList(),
          ),
        ),
      ],
    );
  }
  LineChartData colorChartData(double spotSize) {

    return LineChartData(
      extraLinesData: ExtraLinesData(
          horizontalLines: [],
          verticalLines: []
      ),
      axisTitleData: FlAxisTitleData(
        bottomTitle: AxisTitle(
            showTitle: false,
            textStyle:
            TextStyle(color: const Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
            titleText: "Wavelength /nm"
        ),
        leftTitle: AxisTitle(
            showTitle: false,
            textStyle:
            TextStyle(color: const Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
            titleText: "Irradiance W/m2/nm"
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          textStyle:
          TextStyle(color: const Color(0xff68737d), fontWeight: FontWeight.bold, fontSize: 16),
          getTitles: (value) {
            return '';
          },
          margin: 8,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          textStyle: TextStyle(
            color: const Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {

            return '';
          },
          reservedSize: 28,
          margin: 12,
        ),
      ),
      borderData:
      FlBorderData(show: false, border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: 0.8,
      minY: 0,
      maxY: 0.9,
      lineBarsData: [
        LineChartBarData(

          dotData:  FlDotData(
            show: true,
            dotColor: Colors.black,
            dotSize: spotSize,

          ),
          spots: [FlSpot(CCTData[1],CCTData[2])],
        ),
      ],
    );
  }
//  Future<String>  readFileAsync() async{
//      String string = await rootBundle.loadString('assets/convMat.json');
//      return string;
//      }
  Future<Map<String, dynamic>> readFileAsync(String assetsPath) async {

    return rootBundle.loadString(assetsPath)
        .then((jsonStr) => jsonDecode(jsonStr));
  }


  List<double> interp(List<double> x, List<double> y, List<double>xx){
    double dx,dy,dist, newDist;
    int i,j, idx,indiceEnVector;
    List<double> slope = [],intercept = [];
    List<double> yy = [];

    if (slope != null && intercept != null) {
      slope.clear();
      intercept.clear();
    }

    for(i = 0; i < x.length; i++)
    {
      if(i < x.length - 1)
      {
        dx = x[i + 1] - x[i];
        dy = y[i + 1] - y[i];
        slope.add(dy / dx);
        intercept.add(y[i] - x[i] * slope[i]);
      }
      else
      {
        slope.add(slope[i - 1]);
        intercept.add(intercept[i - 1]);
      }
    }
    for (i = 0; i < xx.length; i++)
    {
      idx = -1;
      dist = 1000;

      for ( j = 0; j < x.length; j++)
      {
        newDist = (xx[0]+(i*(xx[1]-xx[0]))) - x[j];
        if (newDist > 0 && newDist < dist)
        {
          dist = newDist;
          idx = j;
        }
      }
      indiceEnVector = idx;
      if(indiceEnVector != -1) yy.add(slope[indiceEnVector] * (xx[0]+(i * (xx[1]-xx[0]))) + intercept[indiceEnVector]);
      else yy.add(0);
    }

    return yy;
  }
  @override
  Widget build(BuildContext context){
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text("WLSS Gamma"),
          actions: <Widget>[
            /*StreamBuilder<BluetoothDeviceState>(
              stream:  widget.device.state.asBroadcastStream(),
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) {
                VoidCallback onPressed;
                String text;
                switch (snapshot.data) {
                  case BluetoothDeviceState.connected:
                    onPressed = () =>  widget.device.disconnect();
                    text = 'DISCONNECT';

                    break;
                  case BluetoothDeviceState.disconnected:
                    onPressed = () =>  widget.device.connect();
                    text = 'CONNECT';
                    break;
                  default:
                    onPressed = null;
                    text = snapshot.data.toString().substring(21).toUpperCase();
                    break;
                }
                return FlatButton(
                    onPressed: onPressed,
                    child: Text(
                      text,
                      style: Theme.of(context)
                          .primaryTextTheme
                          .button
                          .copyWith(color: Colors.white),
                    ));
              },
            )*/
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                  child: Text("SPD"),
                  icon: Icon(Icons.show_chart)),
              Tab(
                  child: Text("Illuminance"),
                  icon: Icon(Icons.flare)),
              Tab(
                  child: Text("Quality"),
                  icon: Icon(Icons.note)),
            ],
          ),
        ),

        body: Center(
          child: TabBarView(
              children: [
                _deviceConnectedAndReady ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      child: LineChart(
                        mainData(),
                      ),
                      width: double.infinity,
                    ),
                    Container(
                      child:RaisedButton(
                        //color: Colors.green,
                          shape:RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),

                          ),
                          child: Text(
                            "Measure",
                            style:TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                          ),

                          onPressed: () {
                            setState(() {
                              readingSpectrum = true;
                            });
                            List<double> spm = [];
                            deviceCharacteristic.write([0x35]);
                            int val = 0;
                            print("Written to Device");
                            deviceCharacteristic.value.distinct()
                                .asBroadcastStream()
                                .listen((v) {
                              if (v.length > 1) {
                                if (v[1] == val &&
                                    v[0] == 207) {
                                  ByteBuffer buffer = new Int8List
                                      .fromList(v).buffer;
                                  ByteData byteData1 = new ByteData
                                      .view(buffer, 2, 4);
                                  ByteData byteData2 = new ByteData
                                      .view(buffer, 6, 4);
                                  ByteData byteData3 = new ByteData
                                      .view(buffer, 10, 4);
                                  ByteData byteData4 = new ByteData
                                      .view(buffer, 14, 4);
                                  double x;
                                  x = byteData1.getFloat32(
                                      0);
                                  spm.add(x);
                                  x = byteData2.getFloat32(
                                      0);
                                  spm.add(x);
                                  x = byteData3.getFloat32(
                                      0);
                                  spm.add(x);
                                  x = byteData4.getFloat32(
                                      0);
                                  spm.add(x);
                                  val++;
                                  if (v[1] == 6) {
                                    List<double> spm14 = [];
                                    spm14.addAll(
                                        spm.take(14));
                                    print('data: $spm14');
                                    double sum = 0;
                                    spm14.forEach((f) => sum += f);

                                    if (sum > 0) {
                                      LinkedHashMap map = LinkedHashMap();
                                      map['spm14'] = spm14;
                                      map['convMat'] =
                                          convMat;
                                      map['transMat'] =
                                          transMat;
                                      //map['convMat2'] = convMat2.toList().cast<double>().toList().cast<double>();
                                      _getSPM(map);
                                      if (currentSPM !=
                                          null) {
                                        print(currentSPM);
                                        setState(() {
                                          currentSPM = null;
                                        });
                                      }
                                    }else{
                                      setState(() {
                                        FlSpot val;
                                        chartData.clear();
                                        currentSPM = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
                                        for(int i=0;i<401;i++){
                                          val = FlSpot(
                                              i.toDouble()+360,
                                              currentSPM[i]);
                                          chartData.add(val);
                                        }
                                        //luxData = calculateLux(currentSPM);
                                        luxData =[0,0,0,0,0,0];
                                        CCTData =[0,0,0];
                                        //CCTData = calculateCCT(currentSPM);
                                        readingSpectrum = false;
                                      });
                                    }
                                  }
                                }
                              }
                            });
                          }
                      ),
                      margin: EdgeInsets.only(top: 50.0),
                      height: 80.0,
                      width: 300,
                    ),

                    /*Container(

                      //height: 500,
                      margin: new EdgeInsets.only(left: 5, right: 5),
                      child: StreamBuilder<BluetoothDeviceState>(
                        stream:  widget.device.state.asBroadcastStream(),
                        initialData: BluetoothDeviceState.connected,
                        builder: (c, snapshot) {
                          if(snapshot.data == BluetoothDeviceState.connected){
                            widget.device.discoverServices();
                            return StreamBuilder<List<BluetoothService>>(
                              stream: widget.device.services.asBroadcastStream(),
                              initialData: [],
                              builder: (c, snapshot) {
                                for (int i =0; i<snapshot.data.length; i++){
                                  if (snapshot.data.map((r) => r.characteristics.map((c) => c.uuid.toString())).toList()[i].contains('0000cccc-5555-8888-2299-ba0987654321')){
                                    BluetoothCharacteristic c = snapshot.data.map((r) => r.characteristics.map((c) => c)).toList()[i].first;
                                    //if(r.uuid.toString().contains(0000beeb-5555-8888-2299-ba0987654321''))

                                    if(_characteristicSet == false){
                                      c.setNotifyValue(true).then((val){
                                          setState(() {
                                            _characteristicSet = true;
                                          });
                                      });

                                    }


                                    if(readingSpectrum == false && _characteristicSet == true) {
                                      return Column(
                                        //crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Container(
                                            child: LineChart(
                                            mainData(),
                                          ),
                                            width: double.infinity,
                                          ),

                                          Container(
                                            child:RaisedButton(
                                            //color: Colors.green,
                                              shape:RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),

                                              ),
                                              child: Text(
                                                  "Measure",
                                                  style:TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                              ),

                                              onPressed: () {
                                                setState(() {
                                                  readingSpectrum = true;
                                                });
                                                List<double> spm = [];
                                                c.write([0x35]);
                                                int val = 0;
                                                print("Written to Device");
                                                c.value.distinct()
                                                    .asBroadcastStream()
                                                    .listen((v) {
                                                  if (v.length > 1) {
                                                    if (v[1] == val &&
                                                        v[0] == 207) {
                                                      ByteBuffer buffer = new Int8List
                                                          .fromList(v).buffer;
                                                      ByteData byteData1 = new ByteData
                                                          .view(buffer, 2, 4);
                                                      ByteData byteData2 = new ByteData
                                                          .view(buffer, 6, 4);
                                                      ByteData byteData3 = new ByteData
                                                          .view(buffer, 10, 4);
                                                      ByteData byteData4 = new ByteData
                                                          .view(buffer, 14, 4);
                                                      double x;
                                                      x = byteData1.getFloat32(
                                                          0);
                                                      spm.add(x);
                                                      x = byteData2.getFloat32(
                                                          0);
                                                      spm.add(x);
                                                      x = byteData3.getFloat32(
                                                          0);
                                                      spm.add(x);
                                                      x = byteData4.getFloat32(
                                                          0);
                                                      spm.add(x);
                                                      val++;
                                                      if (v[1] == 6) {
                                                        List<double> spm14 = [];
                                                        spm14.addAll(
                                                            spm.take(14));
                                                        print('data: $spm14');
                                                        double sum = 0;
                                                        spm14.forEach((f) => sum += f);

                                                        if (sum > 0) {
                                                          LinkedHashMap map = LinkedHashMap();
                                                          map['spm14'] = spm14;
                                                          map['convMat'] =
                                                              convMat;
                                                          map['transMat'] =
                                                              transMat;
                                                          //map['convMat2'] = convMat2.toList().cast<double>().toList().cast<double>();
                                                          _getSPM(map);
                                                          if (currentSPM !=
                                                              null) {
                                                            print(currentSPM);
                                                            setState(() {
                                                              currentSPM = null;
                                                            });
                                                          }
                                                        }else{
                                                          setState(() {
                                                            FlSpot val;
                                                            chartData.clear();
                                                          currentSPM = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
                                                          for(int i=0;i<401;i++){
                                                            val = FlSpot(
                                                                i.toDouble()+360,
                                                                currentSPM[i]);
                                                            chartData.add(val);
                                                          }
                                                          //luxData = calculateLux(currentSPM);
                                                            luxData =[0,0,0,0,0,0];
                                                            CCTData =[0,0,0];
                                                          //CCTData = calculateCCT(currentSPM);
                                                          readingSpectrum = false;
                                                          });
                                                        }
                                                      }
                                                    }
                                                  }
                                                });
                                              }
                                          ),
                                            margin: EdgeInsets.only(top: 50.0),
                                            height: 80.0,
                                            width: 300,
                                          ),

                                        ],
                                      );
                                    }else{
                                      return Column(
                                        children: <Widget>[
                                          SpinKitWave(
                                            color: Colors.red,
                                            size: 100.0,
                                          )
                                        ],
                                      );
                                    }
                                    return RaisedButton(
                                        color: Colors.green,
                                        child: Text("Read SPM"),
                                        onPressed: (){
                                          //c.setNotifyValue(true);
                                          List<double> spm = [];
                                          c.write([0x35]);
                                          int val = 0;
                                          print("Written to Device");
                                          c.value.distinct().asBroadcastStream().listen((v){
                                            if(v[1] == val) {
                                              ByteBuffer buffer = new Int8List
                                                  .fromList(v).buffer;
                                              ByteData byteData1 = new ByteData
                                                  .view(buffer, 2, 4);
                                              ByteData byteData2 = new ByteData
                                                  .view(buffer, 6, 4);
                                              ByteData byteData3 = new ByteData
                                                  .view(buffer, 10, 4);
                                              ByteData byteData4 = new ByteData
                                                  .view(buffer, 14, 4);
                                              double x;
                                              x = byteData1.getFloat32(0);
                                              spm.add(x);
                                              x = byteData2.getFloat32(0);
                                              spm.add(x);
                                              x = byteData3.getFloat32(0);
                                              spm.add(x);
                                              x = byteData4.getFloat32(0);
                                              spm.add(x);
                                              val++;
                                              if (v[1] == 6) {
                                                List<double> spm14 = [];
                                                spm14.addAll(spm.take(14));
                                                print('data: $spm14');}
                                            }
                                          });
                                        }
                                    );
                                    //   ]
                                    // );


                                  }
                                  else {

                                    if (i == snapshot.data.length-1) return Text ("HAve NOT Found it!");

                                    //return Text("It Doesnt Match");

                                  }
                                }
                                //print(snapshot.data.map((r) => r.characteristics.map((c) => c.uuid.toString())).toList()[2]);
                                return SpinKitWave(
                                  color: Colors.red,
                                  size: 100.0,
                                );
                              },
                            );

                          }
                          else return SpinKitWave(
                            color: Colors.red,
                            size: 100.0,
                          );
                          //return Text("now");
                        },
                      ),
                    ),*/
                  ],
                ): SpinKitWave(
                  color: Colors.red,
                  size: 100.0,
                ),
                AspectRatio(
                aspectRatio: 1.7,
                child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)

                ),
                color: Colors.white,
                child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: luxData.reduce(max)+(luxData.reduce(max)*(20/100)),
                            barTouchData: BarTouchData(
                              enabled: false,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.transparent,
                                tooltipPadding: const EdgeInsets.all(0),
                                tooltipBottomMargin: 8,
                                getTooltipItem: (
                                    BarChartGroupData group,
                                    int groupIndex,
                                    BarChartRodData rod,
                                    int rodIndex,
                                    ) {
                                  return BarTooltipItem(
                                    rod.y.round().toString(),
                                    TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: SideTitles(
                                showTitles: true,
                                textStyle: TextStyle(
                                    color: const Color(0xff7589a2), fontWeight: FontWeight.bold, fontSize: 14),
                                margin: 20,
                                getTitles: (double value) {
                                  switch (value.toInt()) {
                                    case 0:
                                      return 'S-Cone';
                                    case 1:
                                      return 'MEDI';
                                    case 2:
                                      return 'Photopic';
                                    case 3:
                                      return 'L-Cone';
                                    case 4:
                                      return 'M-Cone';
                                    case 5:
                                      return 'Rhodopic';
                                    default:
                                      return '';
                                  }
                                },
                              ),
                              leftTitles: const SideTitles(showTitles: false),
                            ),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            barGroups: [
                              BarChartGroupData(
                                  x: 0,
                                  barRods: [BarChartRodData(y: luxData[0], color: Colors.blue)],
                                  showingTooltipIndicators: [0]),
                              BarChartGroupData(
                                  x: 1,
                                  barRods: [BarChartRodData(y: luxData[1], color: Colors.blueAccent)],
                                  showingTooltipIndicators: [0]),
                              BarChartGroupData(
                                  x: 2,
                                  barRods: [BarChartRodData(y: luxData[2], color: Colors.yellow)],
                                  showingTooltipIndicators: [0]),
                              BarChartGroupData(
                                  x: 3,
                                  barRods: [BarChartRodData(y: luxData[3], color: Colors.green)],
                                  showingTooltipIndicators: [0]),
                              BarChartGroupData(
                                  x: 4,
                                  barRods: [BarChartRodData(y: luxData[4], color: Colors.red)],
                                  showingTooltipIndicators: [0]),
                              BarChartGroupData(
                                  x: 5,
                                  barRods: [BarChartRodData(y: luxData[5], color: Colors.grey)],
                                  showingTooltipIndicators: [0]),
                            ],
                          ),
                        ),
                ),
                ),
                //Quality Tab
                ListView(
                  physics: const BouncingScrollPhysics(),
                  children: ListTile.divideTiles(
                    context: context,
                    tiles: [
                      Card(
                        child:ListTile(
                          leading: Text('CCT',

                            style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16,
                            ),
                          ),
                          //subtitle: Text('Here is a second line'),
                          title: Text(CCTData[0].ceil().toString(),
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),

                        ),
                      ),
                      Card(
                        child:ListTile(
                          leading: Text('CRI',

                            style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16,
                            ),
                          ),
                          //subtitle: Text('Here is a second line'),
                          title: Text(CCTData[0].ceil().toString(),
                            style: TextStyle(
                              fontSize: 20,
                            ),
                          ),

                        ),
                      ),
                      Card(
                          child:ListTile(
                          leading: Text('x'),
                          title: Text(CCTData[1].toStringAsPrecision(3)),
                        ),
                      ),
                      Card(
                        child:ListTile(
                        leading: Text('y'),
                        title: Text(CCTData[2].toStringAsPrecision(3)),
                      ),
                    ),

                      Card(
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                          Image(image: AssetImage('assets/colorChart.png')),
                          Container(
                            padding: EdgeInsets.only(top: 15, right: 25),

                            child: LineChart(
                              colorChartData(spotSize),
                            ),
                            width: 375,
                            height: 393
                          ),
                        ],
                        ),
                      ),
                    ],
                  ).toList(),
                ),
                //Text("Tab 3"),
              ]
          ),
        ),
      ),
    );
  }



 void _getSPM(LinkedHashMap map) async {
    //print(map['spm14']);
     await compute(spmRead,map).then((value){
      setState(() {
        FlSpot val;
        chartData.clear();
        currentSPM=value;
        for(int i=0;i<401;i++){
          val = FlSpot(
              i.toDouble()+360,
              currentSPM[i]);
          chartData.add(val);
        }
        luxData = calculateLux(currentSPM);
        CCTData = calculateCCT(currentSPM);
        readingSpectrum = false;
      });
      return null;
    }).catchError((error) {
       setState(() {
         FlSpot val;
         chartData.clear();
         currentSPM = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
         for(int i=0;i<401;i++){
           val = FlSpot(
               i.toDouble()+360,
               currentSPM[i]);
           chartData.add(val);
         }
         //luxData = calculateLux(currentSPM);
         luxData =[0,0,0,0,0,0];
         CCTData =[0,0,0];
         //CCTData = calculateCCT(currentSPM);
         readingSpectrum = false;
       });
     }).timeout(const Duration(seconds: 10));

    //chartData.clear();
//   await Future.delayed(Duration(seconds: 1));
   //int result = await compute(_calculate, 5);


  }

  List<double> calculateCCT(List<double> spmData){
    List<double> xDash = [0.00136800000000000,0.00223600000000000,0.00424300000000000,0.00765000000000000,0.0143100000000000,0.0231900000000000,0.0435100000000000,0.0776300000000000,0.134380000000000,0.214770000000000,0.283900000000000,0.328500000000000,0.348280000000000,0.348060000000000,0.336200000000000,0.318700000000000,0.290800000000000,0.251100000000000,0.195360000000000,0.142100000000000,0.0956400000000000,0.0579500000000000,0.0320100000000000,0.0147000000000000,0.00490000000000000,0.00240000000000000,0.00930000000000000,0.0291000000000000,0.0632700000000000,0.109600000000000,0.165500000000000,0.225750000000000,0.290400000000000,0.359700000000000,0.433450000000000,0.512050000000000,0.594500000000000,0.678400000000000,0.762100000000000,0.842500000000000,0.916300000000000,0.978600000000000,1.02630000000000,1.05670000000000,1.06220000000000,1.04560000000000,1.00260000000000,0.938400000000000,0.854450000000000,0.751400000000000,0.642400000000000,0.541900000000000,0.447900000000000,0.360800000000000,0.283500000000000,0.218700000000000,0.164900000000000,0.121200000000000,0.0874000000000000,0.0636000000000000,0.0467700000000000,0.0329000000000000,0.0227000000000000,0.0158400000000000,0.0113590000000000,0.00811100000000000,0.00579000000000000,0.00410900000000000,0.00289900000000000,0.00204900000000000,0.00144000000000000,0.00100000000000000,0.000690000000000000,0.000476000000000000,0.000332000000000000,0.000235000000000000,0.000166000000000000,0.000117000000000000,8.30000000000000e-05,5.90000000000000e-05,4.20000000000000e-05];
    List<double> yDash = [3.90000000000000e-05,6.40000000000000e-05,0.000120000000000000,0.000217000000000000,0.000396000000000000,0.000640000000000000,0.00121000000000000,0.00218000000000000,0.00400000000000000,0.00730000000000000,0.0116000000000000,0.0168400000000000,0.0230000000000000,0.0298000000000000,0.0380000000000000,0.0480000000000000,0.0600000000000000,0.0739000000000000,0.0909800000000000,0.112600000000000,0.139020000000000,0.169300000000000,0.208020000000000,0.258600000000000,0.323000000000000,0.407300000000000,0.503000000000000,0.608200000000000,0.710000000000000,0.793200000000000,0.862000000000000,0.914850000000000,0.954000000000000,0.980300000000000,0.994950000000000,1,0.995000000000000,0.978600000000000,0.952000000000000,0.915400000000000,0.870000000000000,0.816300000000000,0.757000000000000,0.694900000000000,0.631000000000000,0.566800000000000,0.503000000000000,0.441200000000000,0.381000000000000,0.321000000000000,0.265000000000000,0.217000000000000,0.175000000000000,0.138200000000000,0.107000000000000,0.0816000000000000,0.0610000000000000,0.0445800000000000,0.0320000000000000,0.0232000000000000,0.0170000000000000,0.0119200000000000,0.00821000000000000,0.00572300000000000,0.00410200000000000,0.00292900000000000,0.00209100000000000,0.00148400000000000,0.00104700000000000,0.000740000000000000,0.000520000000000000,0.000361000000000000,0.000249000000000000,0.000172000000000000,0.000120000000000000,8.50000000000000e-05,6.00000000000000e-05,4.20000000000000e-05,3.00000000000000e-05,2.10000000000000e-05,1.50000000000000e-05];
    List<double> zDash = [0.00645000000000000,0.0105500000000000,0.0200500000000000,0.0362100000000000,0.0678500000000000,0.110200000000000,0.207400000000000,0.371300000000000,0.645600000000000,1.03905000000000,1.38560000000000,1.62296000000000,1.74706000000000,1.78260000000000,1.77211000000000,1.74410000000000,1.66920000000000,1.52810000000000,1.28764000000000,1.04190000000000,0.812950000000000,0.616200000000000,0.465180000000000,0.353300000000000,0.272000000000000,0.212300000000000,0.158200000000000,0.111700000000000,0.0782500000000000,0.0572500000000000,0.0421600000000000,0.0298400000000000,0.0203000000000000,0.0134000000000000,0.00875000000000000,0.00575000000000000,0.00390000000000000,0.00275000000000000,0.00210000000000000,0.00180000000000000,0.00165000000000000,0.00140000000000000,0.00110000000000000,0.00100000000000000,0.000800000000000000,0.000600000000000000,0.000340000000000000,0.000240000000000000,0.000190000000000000,0.000100000000000000,5.00000000000000e-05,3.00000000000000e-05,2.00000000000000e-05,1.00000000000000e-05,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    List<double> x = [380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,571,572,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,768,769,770,771,772,773,774,775,776,777,778,779,780];
    List<double> xx = [380,385,390,395,400,405,410,415,420,425,430,435,440,445,450,455,460,465,470,475,480,485,490,495,500,505,510,515,520,525,530,535,540,545,550,555,560,565,570,575,580,585,590,595,600,605,610,615,620,625,630,635,640,645,650,655,660,665,670,675,680,685,690,695,700,705,710,715,720,725,730,735,740,745,750,755,760,765,770,775,780];
    List<double> yy = [];
    yy = interp(x,spmData,xx);
    List<double> output = [];
    double sumX =0, sumY =0 , sumZ = 0;
    double X,Y,Z;
    double cie_x,cie_y,n,CCT;

    for (int i=0; i<81 ; i++){
      sumX = sumX + xDash[i]*yy[i];
      sumY = sumY + yDash[i]*yy[i];
      sumZ = sumZ + zDash[i]*yy[i];
    }
    X = sumX; Y = sumY; Z = sumZ;

    cie_x= X/(X+Y+Z);
    cie_y= Y/(X+Y+Z);

    n = (cie_x-0.3320)/(0.1858-cie_y);
    CCT = 437*n*n*n + 3601*n*n + 6861*n + 5517;

    output.add(CCT);
    output.add(cie_x);
    output.add(cie_y);

    return output;
  }
  List<double> calculateLux (List<double> spmData){
    List<double> x = [380,381,382,383,384,385,386,387,388,389,390,391,392,393,394,395,396,397,398,399,400,401,402,403,404,405,406,407,408,409,410,411,412,413,414,415,416,417,418,419,420,421,422,423,424,425,426,427,428,429,430,431,432,433,434,435,436,437,438,439,440,441,442,443,444,445,446,447,448,449,450,451,452,453,454,455,456,457,458,459,460,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,477,478,479,480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496,497,498,499,500,501,502,503,504,505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,540,541,542,543,544,545,546,547,548,549,550,551,552,553,554,555,556,557,558,559,560,561,562,563,564,565,566,567,568,569,570,571,572,573,574,575,576,577,578,579,580,581,582,583,584,585,586,587,588,589,590,591,592,593,594,595,596,597,598,599,600,601,602,603,604,605,606,607,608,609,610,611,612,613,614,615,616,617,618,619,620,621,622,623,624,625,626,627,628,629,630,631,632,633,634,635,636,637,638,639,640,641,642,643,644,645,646,647,648,649,650,651,652,653,654,655,656,657,658,659,660,661,662,663,664,665,666,667,668,669,670,671,672,673,674,675,676,677,678,679,680,681,682,683,684,685,686,687,688,689,690,691,692,693,694,695,696,697,698,699,700,701,702,703,704,705,706,707,708,709,710,711,712,713,714,715,716,717,718,719,720,721,722,723,724,725,726,727,728,729,730,731,732,733,734,735,736,737,738,739,740,741,742,743,744,745,746,747,748,749,750,751,752,753,754,755,756,757,758,759,760,761,762,763,764,765,766,767,768,769,770,771,772,773,774,775,776,777,778,779,780];
    List<double> Erythropic_data = [0,0,0.000407619000000000,0.00106921000000000,0.00254073000000000,0.00531546000000000,0.00998835000000000,0.0160130000000000,0.0233957000000000,0.0309104000000000,0.0397810000000000,0.0494172000000000,0.0594619000000000,0.0686538000000000,0.0795647000000000,0.0907704000000000,0.106663000000000,0.128336000000000,0.151651000000000,0.177116000000000,0.207940000000000,0.244046000000000,0.282752000000000,0.334786000000000,0.391705000000000,0.456252000000000,0.526538000000000,0.599867000000000,0.675313000000000,0.737108000000000,0.788900000000000,0.837403000000000,0.890871000000000,0.926660000000000,0.944527000000000,0.970703000000000,0.985636000000000,0.996979000000000,0.999543000000000,0.987057000000000,0.957841000000000,0.939781000000000,0.906693000000000,0.859605000000000,0.803173000000000,0.740680000000000,0.668991000000000,0.593248000000000,0.517449000000000,0.445125000000000,0.369168000000000,0.300316000000000,0.242316000000000,0.193730000000000,0.149509000000000,0.112638000000000,0.0838077000000000,0.0616384000000000,0.0448132000000000,0.0321660000000000,0.0227738000000000,0.0158939000000000,0.0109123000000000,0.00759453000000000,0.00528607000000000,0.00366675000000000,0.00251327000000000,0.00172108000000000,0.00118900000000000,0.000822396000000000,0.000572917000000000,0.000399670000000000,0.000278553000000000,0.000196528000000000,0.000138482000000000,9.81226000000000e-05,6.98827000000000e-05,4.98430000000000e-05,3.57781000000000e-05,2.56411000000000e-05,1.85766000000000e-05];
    List<double> Chloropic_data = [0,0,0.000358227000000000,0.000964828000000000,0.00237208000000000,0.00512316000000000,0.00998841000000000,0.0172596000000000,0.0273163000000000,0.0396928000000000,0.0555384000000000,0.0750299000000000,0.0957612000000000,0.116220000000000,0.139493000000000,0.162006000000000,0.193202000000000,0.232275000000000,0.271441000000000,0.310372000000000,0.355066000000000,0.405688000000000,0.456137000000000,0.522970000000000,0.591003000000000,0.666404000000000,0.743612000000000,0.816808000000000,0.889214000000000,0.934977000000000,0.961962000000000,0.981481000000000,0.998931000000000,0.991383000000000,0.961876000000000,0.935829000000000,0.890949000000000,0.840969000000000,0.776526000000000,0.700013000000000,0.611728000000000,0.531825000000000,0.454142000000000,0.376527000000000,0.304378000000000,0.239837000000000,0.185104000000000,0.140431000000000,0.104573000000000,0.0765841000000000,0.0554990000000000,0.0397097000000000,0.0280314000000000,0.0194366000000000,0.0137660000000000,0.00954315000000000,0.00650455000000000,0.00442794000000000,0.00306050000000000,0.00211596000000000,0.00145798000000000,0.000998424000000000,0.000677653000000000,0.000467870000000000,0.000325278000000000,0.000225641000000000,0.000155286000000000,0.000107388000000000,7.49453000000000e-05,5.24748000000000e-05,3.70443000000000e-05,2.62088000000000e-05,1.85965000000000e-05,1.33965000000000e-05,9.63397000000000e-06,6.96522000000000e-06,5.06711000000000e-06,3.68617000000000e-06,2.69504000000000e-06,1.96864000000000e-06,1.45518000000000e-06];
    List<double> Cyanopic_data = [0,0,0.00614265000000000,0.0159515000000000,0.0396308000000000,0.0897612000000000,0.178530000000000,0.305941000000000,0.462692000000000,0.609570000000000,0.756885000000000,0.869984000000000,0.966960000000000,0.993336000000000,0.991329000000000,0.906735000000000,0.823726000000000,0.737043000000000,0.610456000000000,0.470894000000000,0.350108000000000,0.258497000000000,0.185297000000000,0.135351000000000,0.0967990000000000,0.0649614000000000,0.0412337000000000,0.0271300000000000,0.0176298000000000,0.0113252000000000,0.00717089000000000,0.00454287000000000,0.00283352000000000,0.00175573000000000,0.00108230000000000,0.000664512000000000,0.000408931000000000,0.000251918000000000,0.000155688000000000,9.67045000000000e-05,6.04705000000000e-05,3.81202000000000e-05,2.42549000000000e-05,1.55924000000000e-05,1.01356000000000e-05,6.66657000000000e-06,4.43906000000000e-06,2.99354000000000e-06,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0];
    List<double> Rhodopic_data = [0.000589000000000000,0.00110800000000000,0.00220900000000000,0.00453000000000000,0.00929000000000000,0.0185200000000000,0.0348400000000000,0.0604000000000000,0.0966000000000000,0.143600000000000,0.199800000000000,0.262500000000000,0.328100000000000,0.393100000000000,0.455000000000000,0.513000000000000,0.567000000000000,0.620000000000000,0.676000000000000,0.734000000000000,0.793000000000000,0.851000000000000,0.904000000000000,0.949000000000000,0.982000000000000,0.998000000000000,0.997000000000000,0.975000000000000,0.935000000000000,0.880000000000000,0.811000000000000,0.733000000000000,0.650000000000000,0.564000000000000,0.481000000000000,0.402000000000000,0.328800000000000,0.263900000000000,0.207600000000000,0.160200000000000,0.121200000000000,0.0899000000000000,0.0655000000000000,0.0469000000000000,0.0331500000000000,0.0231200000000000,0.0159300000000000,0.0108800000000000,0.00737000000000000,0.00497000000000000,0.00333500000000000,0.00223500000000000,0.00149700000000000,0.00100500000000000,0.000677000000000000,0.000459000000000000,0.000312900000000000,0.000214600000000000,0.000148000000000000,0.000102600000000000,7.15000000000000e-05,5.01000000000000e-05,3.53300000000000e-05,2.50100000000000e-05,1.78000000000000e-05,1.27300000000000e-05,9.14000000000000e-06,6.60000000000000e-06,4.78000000000000e-06,3.48200000000000e-06,2.54600000000000e-06,1.87000000000000e-06,1.37900000000000e-06,1.02200000000000e-06,7.60000000000000e-07,5.67000000000000e-07,4.25000000000000e-07,3.19600000000000e-07,2.41300000000000e-07,1.82900000000000e-07,1.39000000000000e-07];
    List<double> Melanopic_data = [0.000918165000000000,0.00166724000000000,0.00309442000000000,0.00588035000000000,0.0114277000000000,0.0228112000000000,0.0461550000000000,0.0794766000000000,0.137237000000000,0.187096000000000,0.253865000000000,0.320679000000000,0.401587000000000,0.474002000000000,0.553715000000000,0.629654000000000,0.708049000000000,0.785216000000000,0.860291000000000,0.917734000000000,0.965605000000000,0.990621000000000,1,0.992022000000000,0.965952000000000,0.922299000000000,0.862888000000000,0.785233000000000,0.699628000000000,0.609422000000000,0.519309000000000,0.432533000000000,0.351707000000000,0.279135000000000,0.215722000000000,0.162056000000000,0.118526000000000,0.0843457000000000,0.0587013000000000,0.0400089000000000,0.0268747000000000,0.0178624000000000,0.0117901000000000,0.00773430000000000,0.00506686000000000,0.00331766000000000,0.00217698000000000,0.00143314000000000,0.000947313000000000,0.000627648000000000,0.000417955000000000,0.000279801000000000,0.000188341000000000,0.000127337000000000,8.65751000000000e-05,5.91914000000000e-05,4.06945000000000e-05,2.81320000000000e-05,1.95535000000000e-05,1.36480000000000e-05,9.57637000000000e-06,6.75425000000000e-06,4.78804000000000e-06,3.40841000000000e-06,2.43819000000000e-06,1.75252000000000e-06,1.26560000000000e-06,9.18078000000000e-07,6.68991000000000e-07,4.89531000000000e-07,3.59766000000000e-07,2.65493000000000e-07,1.96740000000000e-07,1.46370000000000e-07,1.09332000000000e-07,8.19587000000000e-08,6.16749000000000e-08,4.65916000000000e-08,3.53272000000000e-08,2.68803000000000e-08,2.05258000000000e-08];
    List<double> Photopic_data = [ 3.90000000000000e-05, 6.40000000000000e-05, 0.000120000000000000, 0.000217000000000000, 0.000396000000000000, 0.000640000000000000, 0.00121000000000000, 0.00218000000000000, 0.00400000000000000, 0.00730000000000000, 0.0116000000000000, 0.0168400000000000, 0.0230000000000000, 0.0298000000000000, 0.0380000000000000, 0.0480000000000000, 0.0600000000000000, 0.0739000000000000, 0.0909800000000000, 0.112600000000000, 0.139020000000000, 0.169300000000000, 0.208020000000000, 0.258600000000000, 0.323000000000000, 0.407300000000000, 0.503000000000000, 0.608200000000000, 0.710000000000000, 0.793200000000000, 0.862000000000000, 0.914850000000000, 0.954000000000000, 0.980300000000000, 0.994950000000000, 1, 0.995000000000000, 0.978600000000000, 0.952000000000000, 0.915400000000000, 0.870000000000000, 0.816300000000000, 0.757000000000000, 0.694900000000000, 0.631000000000000, 0.566800000000000, 0.503000000000000, 0.441200000000000, 0.381000000000000, 0.321000000000000, 0.265000000000000, 0.217000000000000, 0.175000000000000, 0.138200000000000, 0.107000000000000, 0.0816000000000000, 0.0610000000000000, 0.0445800000000000, 0.0320000000000000, 0.0232000000000000, 0.0170000000000000, 0.0119200000000000, 0.00821000000000000, 0.00572300000000000, 0.00410200000000000, 0.00292900000000000, 0.00209100000000000, 0.00148400000000000, 0.00104700000000000, 0.000740000000000000, 0.000520000000000000, 0.000361000000000000, 0.000249000000000000, 0.000172000000000000, 0.000120000000000000, 8.50000000000000e-05, 6.00000000000000e-05, 4.20000000000000e-05, 3.00000000000000e-05, 2.10000000000000e-05, 1.50000000000000e-05 ];
    List<double> xx = [380,385,390,395,400,405,410,415,420,425,430,435,440,445,450,455,460,465,470,475,480,485,490,495,500,505,510,515,520,525,530,535,540,545,550,555,560,565,570,575,580,585,590,595,600,605,610,615,620,625,630,635,640,645,650,655,660,665,670,675,680,685,690,695,700,705,710,715,720,725,730,735,740,745,750,755,760,765,770,775,780];

    List<double> luxes = [];
    List<double> yy = [];


    double sum_m = 0, sum_p = 0, sum_e = 0, sum_ch = 0, sum_cy = 0, sum_r = 0;
    //double Melanopic_lux,Photopic_lux,Erythropic_lux,Chloropic_lux,Cyanopic_lux,Rhodopic_lux;
    yy = interp(x,spmData,xx);
    for (int i=0; i<81 ; i++){
      sum_m = sum_m + Melanopic_data[i]* yy[i] * 1000;
      sum_p = sum_p + Photopic_data[i] * yy[i] * 100;
      sum_e = sum_e + Erythropic_data[i] * yy[i] * 1000;
      sum_ch = sum_ch + Chloropic_data[i] * yy[i] * 1000;
      sum_cy = sum_cy + Cyanopic_data[i] * yy[i] * 1000;
      sum_r = sum_r + Rhodopic_data[i] * yy[i] * 1000;

    }



    luxes.add ((sum_m* 5)/1.3262);
    luxes.add(6.83 * sum_p * 5);
    luxes.add((sum_e*5)/1.6289);
    luxes.add((sum_ch*5)/1.4558);
    luxes.add((sum_cy*5)/0.8173);
    luxes.add((sum_r*5)/1.4497);

    return luxes;
  }


}


int _calculate(int value) {
  // this runs on another isolate
  return value * 2;
}


List<double> spmRead (LinkedHashMap map ) {

  List<double> xx = [410,417,424,431,438,445,452,459,466,473,480,487,494,501,508,515,522,529,536,543,550,557,564,571,578,585,592,599,606,613,620,627,634,641,648,655,662,669,676,683,690,697,704,711,718,725,732,739,746,753,760];
  List<double> gammaWavelength = [410,435,460,485,510,535,560,585,610,645,680,705,730,760];
  List<double> recon;

List<double> interp(List<double> x, List<double> y, List<double>xx){
    double dx,dy,dist, newDist;
    int i,j, idx,indiceEnVector;
    List<double> slope = [],intercept = [];
    List<double> yy = [];

    if (slope != null && intercept != null) {
      slope.clear();
      intercept.clear();
    }

    for(i = 0; i < x.length; i++)
    {
      if(i < x.length - 1)
      {
        dx = x[i + 1] - x[i];
        dy = y[i + 1] - y[i];
        slope.add(dy / dx);
        intercept.add(y[i] - x[i] * slope[i]);
      }
      else
      {
        slope.add(slope[i - 1]);
        intercept.add(intercept[i - 1]);
      }
    }
    for (i = 0; i < xx.length; i++)
    {
      idx = -1;
      dist = 1000;

      for ( j = 0; j < x.length; j++)
      {
        newDist = (xx[0]+(i*(xx[1]-xx[0]))) - x[j];
        if (newDist > 0 && newDist < dist)
        {
          dist = newDist;
          idx = j;
        }
      }
      indiceEnVector = idx;
      if(indiceEnVector != -1) yy.add(slope[indiceEnVector] * (xx[0]+(i * (xx[1]-xx[0]))) + intercept[indiceEnVector]);
      else yy.add(0);
    }

    return yy;
  }

        List<double> yy = [];
        yy = interp(gammaWavelength,map['spm14'],xx);
        //print(yy);
        //print(gammaWavelength);
        yy[0] = yy[1];
        List<double> yy_n =[];
        List<double> yy_n2 = [];
        List<double> C = [];
        List<double> B = [];
        for(var i=0;i<yy.length;i++){
          yy_n.add(yy[i]/yy.reduce(max));
          yy_n2.add(yy_n[i]*yy_n[i]);
        }
        //generate C matrix
        C.add(1.0);
        C.addAll(yy_n);
        C.addAll(yy_n2);
        //generate B matrix
        //List<List<double>> convMatrix = [];
        /*for(var i=0;i<103;i++){
          convMatrix.add(map['convMat'].getRange(i*51, i*51+51).toList().cast<double>());
        }*/
       /* Matrix convRealMatrix = Matrix(map['convMat2']);
        Vector cMatrix = Vector.row(C);
        Matrix matrixB = cMatrix*convRealMatrix;
        Matrix matrixBZ = matrixB.map((f){
          if (f < 0) return f =0;
          else return f;
        });*/
        Matrix toReturn = Matrix.fill(1, 51);
        double sum =0;
        List<double> BMatrix = [];

        List<double> convMat;
        convMat = map['convMat'].toList().cast<double>();
        List<dynamic> convMatBeta;
        convMatBeta  = map['convMat'].toList();
        for (int r = 0; r < 51; r++) {
          sum = 0;
          for (int c = 0; c < 103; c++) {
            if(convMatBeta[(c*51)+r] == 0){
              sum = sum + 0;
            }
            else{
              //sum = sum + C[c]*map['convMat'].toList().cast<double>()[(c*51)+r];
              sum = sum + C[c]*convMat[(c*51)+r];
            }
          }
          BMatrix.add(sum);
          if(BMatrix[r] <0 )BMatrix[r] = 0;
        }
        sum =0;
        recon = [];
        Matrix reconstructed = Matrix.fill(401, 1);
        List<double> transMat;
        List<dynamic> transMatBeta = map['transMat'].toList();
        transMat = map['transMat'].toList().cast<double>();
        for (int r = 0; r < reconstructed.m; r++) {
          sum=0;
          for (int c = 0; c < toReturn.n; c++) {
            //sum=sum + transRealMatrix[r][c]*BMatrix[c];
            if(transMatBeta[(r*51)+c] == 0){
              sum = sum + 0;
            }
            else{
              //sum=sum + map['transMat'].toList().cast<double>()[(r*51)+c]*BMatrix[c];
              sum=sum + transMat[(r*51)+c]*BMatrix[c];
            }


          }
          recon.add(sum);
          if(recon[r] <0 )recon[r] = recon[r]*-1;
        }
        print(recon.toString());
        
        List<double> Nrecon=[];
        recon.forEach((f){
          Nrecon.add(f/recon.reduce(max));
        });
        sum = 0;
        map['spm14'].forEach((e){sum += e;});
        
        double radioPower = sum/323.0;

        sum = 0;
        Nrecon.forEach((e){sum += e;});
        double factor = radioPower/sum;
        List<double> reconstructedSpectrum = [];
        Nrecon.forEach((f){
          reconstructedSpectrum.add(f*factor);
        });

  return reconstructedSpectrum;
}