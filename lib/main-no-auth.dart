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

enum SingingCharacter { Fractured_Bone, Healthy_Bone }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FirebaseApp app = await FirebaseApp.configure(
    name: 'test',
    options: FirebaseOptions(
      googleAppID: (Platform.isIOS || Platform.isMacOS)
          ? '* Add iOS app ID *'
          : '* Add Android app ID *',
      gcmSenderID: '159623150305',
      apiKey: '* Add API Key Here *',
      projectID: '* Add Project ID Here *',
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
  int _vib = 0;
  String _vibText = 'Start Vibration';

  int _recorder = 0;
  String _recText = 'Start Recording';
  FlutterSoundRecorder _flutterRecord = new FlutterSoundRecorder();
  //FlutterSoundPlayer _flutterPlayer = new FlutterSoundPlayer();
  Permission _permission = Permission.microphone;
  //String _recorderTxt = "Getting Save Location";
  String _saveLocation = '';

  int _vibRec = 0;
  String _vibRecText = 'Start Processing';

  String _fileId;
  Directory appDocDirectory;
  var dateTimeString;

  SingingCharacter _character = SingingCharacter.Fractured_Bone;

  Future<void> _uploadMeta() async {
    final File file =
    await File('${appDocDirectory.path}/foo$_fileId.txt').create();
    String _annotation='Fractured';
    if (_character==SingingCharacter.Fractured_Bone){
      String _annotation = 'Fractured';
    }
    else{
      String _annotation = 'Healthy';
    }
    dateTimeString = new DateTime.now().toIso8601String()+' : '+_annotation;
    await file.writeAsString(dateTimeString);
    final StorageReference ref =
    widget.storage.ref().child('text').child('foo$_fileId.txt');
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

  Future<void> _uploadAudio() async {
    final File file = File('${appDocDirectory.path}/audio$_fileId.wav');
    final StorageReference ref =
    widget.storage.ref().child('audio-test').child('audio$_fileId.wav');
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

  Future<void> startRecorder() async {
    _fileId = Uuid().v1();
    appDocDirectory = await getExternalStorageDirectory();
    if (await Permission.microphone.request().isGranted) {
      //print(appDocDirectory.path);
      await _flutterRecord.openAudioSession(
        category: SessionCategory.record,
      );
      await _flutterRecord.startRecorder(
          codec: Codec.aacADTS,
          toFile: appDocDirectory.path + "/audio$_fileId.wav",
          sampleRate: 16000);
      //print(_flutterRecord.recorderState);
    } else {
      Permission.microphone.request();
    }
  }

  void stopRecorder() async {
    //await _flutterRecord.stopRecorder();
    //print(_flutterRecord.recorderState);
    await _flutterRecord.closeAudioSession();
    // print(_flutterRecord.recorderState);
    setState(() {
      _saveLocation = 'file saved at ${appDocDirectory.path}/audio$_fileId.wav';
    });
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

  void _startVibrationAndRecording() {
    if (_vibRec == 0) {
      startRecorder();
      Vibration.vibrate(duration: 60 * 1000, amplitude: 255);
      setState(() {
        _vibRec = 1;
        _vibRecText = 'Stop';
      });
    } else {
      stopRecorder();
      _uploadAudio();
      _uploadMeta();
      Vibration.cancel();
      setState(() {
        _vibRec = 0;
        _vibRecText = 'Start';
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            /*Container(
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

             */
            ListTile(
              title: const Text('Fractured Bone'),
              leading: Radio(
                value: SingingCharacter.Fractured_Bone,
                groupValue: _character,
                onChanged: (SingingCharacter value) {
                  setState(() {
                    _character = value;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Healthy Bone'),
              leading: Radio(
                value: SingingCharacter.Healthy_Bone,
                groupValue: _character,
                onChanged: (SingingCharacter value) {
                  setState(() {
                    _character = value;
                  });
                },
              ),
            ),
            Container(
              height: 30,
            ),
            Container(
              width: 200,
              //margin: EdgeInsets.all(20),
              child: RaisedButton(
                padding: EdgeInsets.all(20),
                color: Colors.amber,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
                child: Center(
                  child: Text(
                    '$_vibRecText',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                onPressed: _startVibrationAndRecording,
              ),
            ),
            Container(
              margin: EdgeInsets.all(20),
              child: Text(
                '$_saveLocation',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
