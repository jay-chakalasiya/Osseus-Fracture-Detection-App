import 'package:flutter/material.dart';
//import 'package:flutter_sound/flutter_sound_player.dart';
//import 'package:flutter_sound/flutter_sound_recorder.dart';
import 'package:vibration/vibration.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';



void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  final FirebaseApp app = await FirebaseApp.configure(
    name: 'test',
    options: FirebaseOptions(
      googleAppID: (Platform.isIOS || Platform.isMacOS)
          ? '1:159623150305:ios:4a213ef3dbd8997b'
          : '1:375346618752:android:daeefd75063cef6697a165',
      gcmSenderID: '159623150305',
      apiKey: 'AIzaSyCHy-OFcz_Lvfe30vhqHVLiNKZK007PGZI',
      projectID: 'osseus-fracture-detection',
    ),
  );
  final FirebaseStorage storage = FirebaseStorage(
      app: app, storageBucket: 'gs://osseus-fracture-detection.appspot.com');
  runApp(MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  MyApp({this.storage});
  final FirebaseStorage storage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', storage: storage),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({this.storage, Key key, this.title}) : super(key: key);
  final FirebaseStorage storage;
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //final String fileName = 'hello.txt';
  //final StorageReference storageRef =  FirebaseStorage.instance.ref().child(fileName);
  int _vib = 0;
  String _vibText = 'Start Vibration';


  int _recorder = 0;
  String _recText = 'Start Recording';
  FlutterSoundRecorder _flutterRecord = new FlutterSoundRecorder();
  FlutterSoundPlayer _flutterPlayer = new FlutterSoundPlayer();
  Permission _permission = Permission.microphone;
  String _recorderTxt = "Getting Save Location";

  int _vibRec = 0;
  String _vibRecText = 'Start Processing';

  String _fileId;
  Directory appDocDirectory;
  var dateTimeString;


  Future<void> _uploadFile() async {
    final File file = await File('${appDocDirectory.path}/foo$_fileId.txt').create();
    dateTimeString = new DateTime.now().toIso8601String();
    await file.writeAsString(dateTimeString);
    final StorageReference ref = widget.storage.ref().child('text').child('foo$_fileId.txt');
    final StorageUploadTask uploadTask = ref.putFile(
      file,
      StorageMetadata(
        contentLanguage: 'en',
        customMetadata: <String, String>{'activity': 'test'},
      ),
    );

    //setState(() {
     // _tasks.add(uploadTask);
    //});
  }

  Future<void> _uploadFile2() async {

    final File file = File('${appDocDirectory.path}/audio$_fileId.wav');
    final StorageReference ref = widget.storage.ref().child('audio-test').child('audio$_fileId.wav');
    final StorageUploadTask uploadTask = ref.putFile(
      file,
      StorageMetadata(
        contentLanguage: 'en',
        customMetadata: <String, String>{'activity': 'test'},
      ),
    );

    //setState(() {
    // _tasks.add(uploadTask);
    //});
  }



  void _vibrate() {
    if (_vib == 0) {
      Vibration.vibrate(duration: 60 * 1000, amplitude: 255);
      setState(() {
        _vib = 1;
        _vibText = 'Stop Vibration';
      });
    } else {
      Vibration.cancel();
      setState(() {
        _vib = 0;
        _vibText = 'Start Vibration';
      });
    }
  }

  Future<void> startRecorder() async{
    _fileId = Uuid().v1();
    appDocDirectory = await getExternalStorageDirectory();
    if (await Permission.microphone.request().isGranted){
      print(appDocDirectory.path);
      setState(() {
        _recorderTxt = appDocDirectory.path;
        _recText = appDocDirectory.path;
      });
      await _flutterRecord.openAudioSession(
        category: SessionCategory.record,
      );
      await _flutterRecord.startRecorder(
          codec: Codec.aacADTS,
          toFile: appDocDirectory.path + "/audio$_fileId.wav",
          sampleRate: 16000
      );
      print(_flutterRecord.recorderState);
    }
    else { Permission.microphone.request(); }
  }

  void stopRecorder() async {
    print("HI");
    //await _flutterRecord.stopRecorder();
    print(_flutterRecord.recorderState);
    await _flutterRecord.closeAudioSession();
    print(_flutterRecord.recorderState);

  }

  void _record() {
    if (_recorder == 0) {
      startRecorder();

      setState(() {
        _recorder = 1;
        _recText = 'Stop Recording';
      });
    } else {
      stopRecorder();
      setState(() {
        _recorder = 0;
        _recText = 'Start Recording';
      });
    }
  }

  void _startVibrationAndRecording(){
    if (_vibRec==0){
      startRecorder();
      Vibration.vibrate(duration: 60 * 1000, amplitude: 255);
      setState(() {
        _vibRec = 1;
        _vibRecText = 'Stop Processing';
      });
    }
    else{
      stopRecorder();
      _uploadFile2();
      _uploadFile();
      Vibration.cancel();
      setState(() {
        _vibRec = 0;
        _vibRecText = 'Start Processing';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            /*Center(
              child: Text(
                'Current State of Vibration:',
              ),
            ),
            Center(
              child: Text(
                '$_vib',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),

             */
            Container(
              margin: EdgeInsets.all(20),
              child: FlatButton(
                padding: EdgeInsets.all(20),
                color: Colors.blue,
                child: Text(
                  '$_vibText',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _vibrate,
              ),
            ),
            /*Center(
              child: Text(
                'Current State of Recording:',
              ),
            ),
            Center(
              child: Text(
                '$_recorder',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),

             */
            Container(
              margin: EdgeInsets.all(20),
              child: FlatButton(
                padding: EdgeInsets.all(20),
                color: Colors.blue,
                child: Text(
                  '$_recText',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _record,
              ),
            ),
            Container(
              margin: EdgeInsets.all(20),
              child: FlatButton(
                padding: EdgeInsets.all(20),
                color: Colors.blue,
                child: Text(
                  '$_vibRecText',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: _startVibrationAndRecording,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


