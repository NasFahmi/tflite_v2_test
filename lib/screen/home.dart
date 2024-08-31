import 'package:flutter/material.dart';
import 'package:tflite_v2_test/screen/camera_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Container(
        child: Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>CameraScreen()));
            },
            child: Text('Open Camera'),
          ),
        ),
      )),
    );
  }
}
