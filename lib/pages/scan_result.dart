import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:wlss_gamma_app/pages/device_connected.dart';

class ScannedResult  extends StatefulWidget {

  ScannedResult ( {Key key}) : super (key : key);

  //@override
  //_DiscoverDevicesState createState() => _DiscoverDevicesState();

  @override
  _ScannedResultState createState() => _ScannedResultState();


}

class _ScannedResultState extends State<ScannedResult> with TickerProviderStateMixin{

  AnimationController _controller;
  AnimationController _controller2;
  double borderRadius;
  double currentWidth;
  double currentHeight;
  double containerHeight;
  bool _searching = false;
  bool _animating = false;
  bool clmFound;
  List<BluetoothDevice> clmDeviceList=[];
  @override
  void initState(){
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration : Duration(milliseconds: 2000),
      lowerBound: 0.0,

    )..forward();

    _controller2 = AnimationController(
      vsync: this,
      /*lowerBound: 0.1,
      upperBound: 1,*/
      duration: Duration(seconds: 10),

    )..forward();


    _controller.addListener(() {

      setState(() {
        currentWidth = _controller.value*350;
        currentHeight = _controller.value*100;
      });
    }
    );
    var scaleAnimation = new Tween(
      begin: 0.1,
      end: 1.0,

    ).animate(new CurvedAnimation(
        parent: _controller2,
        curve: Curves.bounceOut
    ));
    _controller2.addListener(() {

      setState(() {
        containerHeight = scaleAnimation.value*500;

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

    borderRadius = 20.0;
    currentWidth = 350;
    currentHeight = 100;
    clmFound = false;
    clmDeviceList=[];
  }
  @override

  void dispose() {

    _controller.dispose();

    super.dispose();

  }
  Widget _discoverBle (){
    setState(() {
      _searching = true;
    });
  }

  void _storeDevice(BluetoothDevice dev){
    setState(() {
      clmDeviceList.add(dev);
    });
  }



  @override
  Widget build (BuildContext context) {
    return Scaffold (
      appBar: AppBar(
        title: Text("WLSS Gamma"),
      ),
      body: Center (
        child: Column(
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          //children: <Widget>[
            children: <Widget>[

              SizedBox(

                width: 300,
                height:130,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[

                    dynamicContainer(150 * _controller.value, 70 * _controller.value ),
                    dynamicContainer(200 * _controller.value, 90 * _controller.value ),
                    dynamicContainer(250 * _controller.value, 110 * _controller.value ),
                    dynamicContainer(300 * _controller.value, 130 * _controller.value ),
                    /*Container(
                    width: 150,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
                    ),
                  ),*/
                    Align(

                      child: Container(
                        width: 150,
                        height: 70,
                        child: RaisedButton(
                          //color: Colors.blueGrey,
                          padding: const EdgeInsets.all(6.0),
                          child: buttonChild(),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),

                          onPressed: () {
                            FlutterBlue.instance.startScan(timeout: Duration(seconds: 9));
                            _discoverBle();
                            _controller.forward();

                          },
                        ),
                      ),
                    ),

                    //Align(
                    // alignment: Alignment(0,0),

                    //),

                  ],
                ),
              ),


              /*StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) {
                  if(snapshot.data.length>1) {
                    snapshot.data.forEach((device){
                      if(device.device.name.contains('CLM')){

                        *//*setState(() {
                          //clmFound = true;
                          clmDeviceList.add(device.device);
                        });*//*
                        //_storeDevice(device.device);
                        //print("Found");
                        return Container(height: 100,
                        child: Text("Found"),
                        );
                      }else return Container(height: 0,);
                    });
                    return Container(height: 0,);
                  }else return Container(height: 0,);
                }),*/
             /* ListView.builder(
                  itemCount: clmDeviceList.length,
                  itemBuilder: (BuildContext context, int index) {
                      if(clmFound == true){
                        return Container(
                          height: 10,
                        );
                      }else{
                        return Container(
                          height: 0,
                        );
                      }
                    }
                  ),*/

              StreamBuilder<List<ScanResult>>(
                  stream: FlutterBlue.instance.scanResults,
                  initialData: [],
                  builder: (c, snapshot) {
                    snapshot.data.forEach((device){
                   if(device.device.name.contains('CLM')) clmFound = true;});
                    if(clmFound == true) {
                      return Container(
                        height: containerHeight,
                        child: ListView.builder(
                            itemCount: snapshot.data.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListBody(
                                children: <Widget>[
                                  Container(
                                    child: snapshot.data.map((r) => r.device.name)
                                        .toList()[index].contains('CLM') ? Card(
                                      child: ListTile(
                                        title: Text(
                                          '${snapshot.data.map((r) =>
                                          r.device.name).toList()[index]}',
                                        ),
                                        onTap: () {
                                          /*Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) {
                                              FlutterBlue.instance.stopScan();
                                              //snapshot.data.map((r)=> r.device.connect());
                                              return DeviceConnected(device:snapshot.data.map((r)=> r.device).toList()[index]);
                                            }),
                                          );*/
                                          Navigator.push(
                                              context,
                                              SlideRightRoute(page: DeviceConnected(
                                                  device: snapshot.data.map((
                                                      r) => r.device)
                                                      .toList()[index])));
                                        },
                                      ),
                                    ) : null,
                                  ),
//                            Padding(
//                              padding: EdgeInsets.all(9.0),
//                            ),
                                ],
                              );
                            }
                        ),
                      );
                    }
                    else return Container(height: 0,);
                  }
              ),
            ],

            /*Container(
              margin: EdgeInsets.only(top:5.0, bottom:5.0),
                child: Container(
                  width: currentWidth,
                  height: currentHeight,

                  child:ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 50.0,
                        maxWidth: 300
                      ),
                      child: RaisedButton(
                        //color: Colors.blueGrey,
                        padding: const EdgeInsets.all(6.0),
                        child: buttonChild(),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),

                        onPressed: () {
                          FlutterBlue.instance.startScan(timeout: Duration(seconds: 9));
                          _discoverBle();
                          _controller.forward();
                        },
                      )
                  ),
                ),
            ),
            Container(
              //height: 500,
              child: StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) {
                  return ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListBody(
                          children: <Widget>[
                            Container(
                                child: snapshot.data.map((r) => r.device.name).toList()[index].contains('CLM') ? Card(
                                  child: ListTile(
                                        title: Text(
                                        '${snapshot.data.map((r) => r.device.name).toList()[index]}',
                                        ),
                                        onTap: () {
                                          *//*Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) {
                                              FlutterBlue.instance.stopScan();
                                              //snapshot.data.map((r)=> r.device.connect());
                                              return DeviceConnected(device:snapshot.data.map((r)=> r.device).toList()[index]);
                                            }),
                                          );*//*
                                          Navigator.push(
                                              context,
                                              ScaleRoute(page: DeviceConnected(device:snapshot.data.map((r)=> r.device).toList()[index])));
                                        },
                                  ),
                                ):null,
                            ),
//                            Padding(
//                              padding: EdgeInsets.all(9.0),
//                            ),
                          ],
                        );
                      }
                  );
                }
              ),
            )*/
          //],
        ),
      ),
    );

  }

  Widget buttonChild (){

    return StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {


            return Text(
                "Scanning..",
              style: TextStyle(
                //color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            );
          }else{
              _controller.stop();
            return Text("Scan for Devices",
              style: TextStyle(
                //color: Colors.white,
                fontWeight: FontWeight.bold,
              ),);
          }
        });

//    if(_searching) return Text("Scanning..");
//    else return Text("Scan for Devices");
  }

//  double alternateWidth () {
//    if(_searching) {
//      if (currentWidth == 350){
//        setState(() {
//          currentWidth = 300;
//        });
//      }
//      if (currentWidth == 300){
//        setState(() {
//          currentWidth = 350;
//        });
//      }
//    }
//
//    return currentWidth;
//  }

  Widget dynamicContainer ( double width, double height ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.red.withOpacity(1-_controller.value),
        borderRadius: new BorderRadius.all(new Radius.circular(20.0)),
      ),
    );
  }


}

class ScaleRoute extends PageRouteBuilder {
  final Widget page;
  ScaleRoute({this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) =>
        ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInExpo,
            ),
          ),
          child: child,
        ),
  );
}

class SlideRightRoute extends PageRouteBuilder {
  final Widget page;
  SlideRightRoute({this.page})
      : super(
    pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        ) =>
    page,
    transitionsBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
        Widget child,
        ) =>
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
  );
}
