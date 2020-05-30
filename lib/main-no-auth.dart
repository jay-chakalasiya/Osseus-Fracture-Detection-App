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
import 'package:flutter/services.dart';

enum SingingCharacter { Fractured_Bone, Healthy_Bone }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final FirebaseApp app = await FirebaseApp.configure(
    name: 'test',
    options: FirebaseOptions(
      googleAppID: (Platform.isIOS || Platform.isMacOS)
          ? 'iOS'
          : 'Android',
      gcmSenderID: '159623150305',
      apiKey: '',
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return MaterialApp(
      title: 'Osseus Fracture Detection',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Osseus', storage: storage),
    );
  }
}

class TutorialPage extends StatefulWidget {
  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage>{

  var images = ['images/tutorial_3.gif','images/tutorial_3.gif','images/tutorial_3.gif','images/tutorial_3.gif'];
  int _currentIndex=0;
  String _currentText='Next';
  bool _relyVisibility=false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tutorial'),
      ),


      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,

          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[

            Image.asset(
              images[_currentIndex],
              //height: MediaQuery.of(context).size.height * 0.45,
            ),
            Container(
              margin: EdgeInsets.all(15),
              child: Text('Step : ${_currentIndex+1}/${images.length}'),
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
                    _currentText,
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                onPressed: (){
                  if (_currentIndex<images.length-2){
                    setState(() {
                      _currentIndex+=1;
                    });
                  }
                  else if (_currentIndex==images.length-2){
                    setState(() {
                      _currentText = 'Go Back To Home Screen';
                      _currentIndex+=1;
                      _relyVisibility=true;
                    });
                  }
                  else{
                    setState(() {
                      _currentText = 'Next';
                      _currentIndex=0;
                      _relyVisibility=false;
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            Container(
              height: 20,
            ),
            Visibility(
              visible: _relyVisibility,
              child: Container(
                width: 200,
                //margin: EdgeInsets.all(20),
                child: RaisedButton(
                  padding: EdgeInsets.all(20),
                  color: Colors.amber,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100)),
                  child: Center(
                    child: Icon(Icons.replay),
                  ),
                  onPressed: (){
                    setState(() {
                      _currentText = 'Next';
                      _currentIndex=0;
                      _relyVisibility=false;
                    });
                  },
                ),
              ),
            ),



          ],
        ),
      ),
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
  int _class = 1;
  String _classDir;
  String _cloudMetaDir = 'meta';
  String _cloudAudioDir = 'data';

  SingingCharacter _character = SingingCharacter.Fractured_Bone;

  String _portalAddress = 'https://osseusserver2.azurewebsites.net/checksignalstrength?path=data%2F';
  String _request = '';
  String _feedback='';

  //double width = MediaQuery.of(context).size.width;
  //double yourWidth = width * 0.65;

  Future<void> _uploadMeta() async {
    final File file =
    await File('${appDocDirectory.path}/foo$_fileId.txt').create();

    if (_class == 1) {
      _classDir = 'Fractured';
    } else {
      _classDir = 'Healthy';
    }

    dateTimeString = new DateTime.now().toIso8601String();
    await file.writeAsString(dateTimeString);
    final StorageReference ref = widget.storage
        .ref()
        .child(_cloudMetaDir)
        .child(_classDir)
        .child('foo$_fileId.txt');
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
    if (_class == 1) {
      _classDir = 'Fractured';
    } else {
      _classDir = 'Healthy';
    }
    _request = '$_portalAddress$_classDir%2Faudio$_fileId.wav';
    print(_request);
    //String _requestEnc = Uri.encodeFull(_request);

    final File file = File('${appDocDirectory.path}/audio$_fileId.wav');
    final StorageReference ref = widget.storage
        .ref()
        .child(_cloudAudioDir)
        .child(_classDir)
        .child('audio$_fileId.wav');
    final StorageUploadTask uploadTask = ref.putFile(
      file,
      StorageMetadata(
        contentLanguage: 'en',
        customMetadata: <String, String>{'activity': 'test'},
      ),
    );
    await new Future.delayed(const Duration(seconds : 2));
    final _response = await http.get(_request);
    print(_response);
    print(_response.statusCode);
    if (_response.statusCode == 200){
      setState(() {
        _feedback = _response.body;
      });
      print(_response.body);
    }
    else{
      setState(() {
        _feedback = 'can\'t reach the server';
      });
      print('Server Error');
    }

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
          codec: Codec.pcm16WAV, //aacADTS,
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
      _saveLocation = 'Experiment is Saved';// at ${appDocDirectory.path}/audio$_fileId.wav';
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
        _feedback = '';
        _saveLocation='';
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: new FloatingActionButton.extended(
        onPressed: (){
          Navigator.push(context, new MaterialPageRoute(builder: (context) => new TutorialPage()));
        },
        label: Text('How To Make Cup'),
        icon: Icon(Icons.help),
        backgroundColor: Colors.amber[200],
      ),


      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,

          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              'images/tutorial_3.gif',
              height: MediaQuery.of(context).size.height * 0.45,
            ),
            Container(
              margin: EdgeInsets.all(20),
              child: Text(
                '$_feedback',
                style: TextStyle(color: Colors.red),
              ),
            ),
            ListTile(
              title: const Text('Fractured Bone'),
              leading: Radio(
                value: SingingCharacter.Fractured_Bone,
                groupValue: _character,
                onChanged: (SingingCharacter value) {
                  setState(() {
                    _character = value;
                    _class = 0;
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
                    _class = 0;
                  });
                },
              ),
            ),
            Container(
              height: 20,
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
