/*
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,

        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        backgroundColor: Colors.amber[100],
        appBar: AppBar(
          title: Text('Osseus'),
          backgroundColor: Colors.amber,
        ),
        body:,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'dart:io'; 
//import 'package:vibration/vibration.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibrate Demo',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: VibrateHomepage(),
    );
  }
}

class VibrateHomepage extends StatefulWidget {
  VibrateHomepage({Key key}) : super(key: key);

  @override
  _VibrateHomepageState createState() => _VibrateHomepageState();
}

class _VibrateHomepageState extends State<VibrateHomepage> {
  var vib=0;
  _PatternVibrate() {
    while (vib<1000) {
      HapticFeedback.lightImpact();
      vib+=1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Osseus'),),
      backgroundColor: Colors.amber[0],
      body: Center(

        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,

            children: <Widget>[
              Expanded(

                child: FlatButton(
                  child: Text('Vibrate'),
                  padding: EdgeInsets.all(10),

                  onPressed: () {
                    HapticFeedback.vibrate();
                  },
                  color: Colors.amber[200],
                ),
              ),
              Container(
                height: 5,
              ),
              Expanded(
                child: FlatButton(

                  child: Text('lightImpact'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                  color: Colors.amber[300],
                ),
              ),
              Container(
                height: 5,
              ),
              Expanded(
                child: FlatButton(
                  child: Text('mediumImpact'),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                  },
                  color: Colors.amber[400],
                ),
              ),
              Container(
                height: 5,
              ),
              Expanded(
                child: FlatButton(
                  child: Text('heavyImpact'),
                  onPressed: () {
                    HapticFeedback.heavyImpact();
                  },
                  color: Colors.amber[500],
                ),
              ),
              Container(
                height: 5,
              ),
              Expanded(
                child: FlatButton(
                  child: Text('Long-time'),
                  onPressed: () {
                    _PatternVibrate();
                  },
                  color: Colors.amber[600],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}