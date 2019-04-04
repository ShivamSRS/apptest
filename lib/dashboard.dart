import 'package:flutter/material.dart';
import 'package:flutter_pdf_viewer/flutter_pdf_viewer.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("NIMBUS"),
        elevation: .1,
        backgroundColor: Color.fromRGBO(49, 87, 110, 1.0),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 2.0),
        child: GridView.count(
          crossAxisCount: 2,
          padding: EdgeInsets.all(3.0),
          children: <Widget>[
            makeDashboardItem("The Magazine", Icons.book,0),
            makeDashboardItem("About",Icons.album,1),
            makeDashboardItem("Departmental Activities", Icons.threesixty,2),
            makeDashboardItem("Archives", Icons.archive,3),
            makeDashboardItem("Submit article", Icons.assignment,4),
            makeDashboardItem("Deadlines", Icons.alarm,5)
          ],
        ),
      ),
    );
  }

  Card makeDashboardItem(String title, IconData icon,int i) {
    return Card(
        elevation: 1.0,
        margin: new EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(color: Color.fromRGBO(220, 220, 220, 1.0)),
          child: new InkWell(
            onTap: () {
              if(i==0){
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Carroussel()));
                }},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              verticalDirection: VerticalDirection.down,
              children: <Widget>[
                SizedBox(height: 50.0),
                Center(
                    child: Icon(
                      icon,
                      size: 40.0,
                      color: Colors.black,
                    )),
                SizedBox(height: 20.0),
                new Center(
                  child: new Text(title,
                      style:
                      new TextStyle(fontSize: 18.0, color: Colors.black)),
                )
              ],
            ),
          ),
        ));
  }

  @override
  void initState(){
    super.initState();
    getPermission();
  }

  void getPermission() async{
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.storage);
    if(permission.value != PermissionStatus.granted.value){
      Map<PermissionGroup, PermissionStatus> permissions = await PermissionHandler().requestPermissions([PermissionGroup.storage]);
    }
    Directory dir = await getExternalStorageDirectory();
    Future<bool> exists = Directory(await "${dir.path}/Nimbus_Magazine").exists();
    exists.then((bool b) async{
      if(!b){
        new Directory(dir.path+'/'+'Nimbus_Magazine').create(recursive: true)
            .then((Directory directory) {
          print('Path of New Dir: '+directory.path);
        });
      }
    });
  }
}

class CounterStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

//  Future<int> readCounter() async {
//    try {
//      final file = await _localFile("nimbus8.pdf");
//
//      // Read the file
//      String contents = await file.readAsString();
//
//      return int.parse(contents);
//    } catch (e) {
//      // If encountering an error, return 0
//      return 0;
//    }
//  }

  Future<File> writeCounter(int counter) async {
    final file = await _localFile("nimbus8.pdf");

    // Write the file
    return file.writeAsString('$counter');
  }

  void getFile() async {
  }
}


class Carroussel extends StatefulWidget {
  @override
  _CarrousselState createState() => new _CarrousselState();
}

class _CarrousselState extends State<Carroussel> {
  PageController controller;
  int currentpage = 0;
  int fileNumber = 9;
  final pdfUrl = "http://nimbusmag.herokuapp.com/nimbus";
  bool downloading = false;
  var progressString = "";

  @override
  initState() {
    super.initState();
    controller = new PageController(
      initialPage: currentpage,
      keepPage: true,
      viewportFraction: 0.5,
    );
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> downloadFile() async {
    Dio dio = Dio();
    try{
      var dir = await getExternalStorageDirectory();
      print(dir.path + "");
      await dio.download(pdfUrl + fileNumber.toString() + ".pdf", "${dir.path}/Nimbus_Magazine/nimbus"+ fileNumber.toString() +".pdf", onReceiveProgress: (rec, total) {
        print("Progress: $rec / $total");
        setState(() {
          downloading = true;
          progressString = ((rec/total)*100).toStringAsFixed(0) + "%";
        });
      });
    } catch(e){
      print('1' + e.toString());
    }
    setState(() {
      downloading = false;
      progressString = "";
    });
    openFile();
  }

  Future<void> openFile() async {
    var dir = await getExternalStorageDirectory();
    Future<bool> exists = File(await "${dir.path}/Nimbus_Magazine/nimbus"+ fileNumber.toString() +".pdf").exists();
    exists.then((bool b) async{
      if(!b){
        await downloadFile();
      }
      else {
        try {
          PdfViewer.loadFile(
            "${dir.path}/Nimbus_Magazine/nimbus"+ fileNumber.toString() +".pdf",
            config: PdfViewerConfig(
              nightMode: false,
              swipeHorizontal: true,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              enableImmersive: false,
              autoPlay: false,
              forceLandscape: false,
              xorDecryptKey: null,
            ),
          );
        } catch(e) {
            await downloadFile();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Center(
        child: downloading?
        Container(
          height: 120.0,
          width: 200.0,
          child: Card(
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(
                  height: 10.0,
                ),
                Text("Downloading File: $progressString",
                  style: TextStyle(
                      color: Colors.white
                  ),
                )
              ],
            ),
          ),
        )
        : new GestureDetector(
          child: new Container(
            child: new PageView.builder(
              onPageChanged: (value) {
                setState(() {
                  currentpage = value;
                  fileNumber = 9 - value;
                });
              },
              controller: controller,
              itemBuilder: (context, index) => builder(index),
              itemCount: 3,

            ),
          ),
          onTap: () {
            openFile();
//
          },
        )
      ),
      floatingActionButton: FloatingActionButton(
        child: Text("Go back"),
        onPressed:(){Navigator.pop(context);},
      ),
    );
  }

  Future<String> get _localPath async {
    final directory = await Directory.systemTemp.createTemp();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/nimbus8.pdf');
  }

  Future<File> writeCounter(int counter) async {
    final file = await _localFile;
    // Write the file
    return file.writeAsString('$counter');
  }

  builder(int index) {
    return new AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double value = 1.0;
        if (controller.position.haveDimensions) {
          value = controller.page - index;
          value = (1 - (value.abs() * .5)).clamp(0.0, 1.0);
        }

        return new Center(
          child: new SizedBox(
            height: Curves.easeOut.transform(value) * 300,
            width: Curves.easeOut.transform(value) * 250,
            child: child,
          ),
        );
      },
      child: new Container(
        margin: const EdgeInsets.all(8.0),
        color: index % 2 == 0 ? Colors.blue : Colors.red,
      ),
    );
  }
}