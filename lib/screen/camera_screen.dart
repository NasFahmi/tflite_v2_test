import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_v2_test/screen/widget/bounding_box.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late List<CameraDescription> cameras;
  CameraController? controller;
  bool isDetecting = false;
  int imageCount = 0;
  String label = ''; //example bed
  String confidence = ''; //example 0.40
  double boundaryBoxesX = 0.0; //0.96
  double boundaryBoxesW = 0.0; //0.86
  double boundaryBoxesY = 0.0; //0.12
  double boundaryBoxesH = 0.0; //0.03
  double screenWidth = 0;
  double screenHeight = 0;
  double imageWidth = 0;
  double imageHeight = 0;
  List<dynamic> resultDetection = [];

  @override
  void initState() {
    super.initState();
    requestCameraPermission();
  }

  Future<void> requestCameraPermission() async {
    if (await Permission.camera.request().isGranted) {
      await initCamera();
      await loadModel();
    } else {
      showPermissionDeniedDialog();
    }
  }

  void showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
            'Camera permission is required to use this feature. Please enable it in settings.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();
    controller = CameraController(cameras[0], ResolutionPreset.medium);

    await controller?.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> startDetection() async {
    if (controller == null || controller!.value.isStreamingImages) {
      return;
    }

    setState(() {
      isDetecting = true;
    });

    controller!.startImageStream((image) async {
      if (isDetecting) {
        try {
          imageCount++;
          if (imageCount % 10 == 0) {
            imageCount = 0;
            var result = await objectDetectionOnFrame(image);
            print('result ${result}');

            if (result.isNotEmpty) {
              // Get bounding box data
              // var boundingBox = result.first['rect'];

              // Convert from normalized coordinates to screen coordinates
              imageWidth = image.width.toDouble();
              imageHeight = image.height.toDouble();

              // Filter results with confidence > 50
              var filteredResults = result.where((re) {
                var confidence = re["confidenceInClass"] * 100;
                return confidence > 50;
              }).toList();

              setState(() {
                resultDetection = filteredResults;
              });
              // print('result label ${label}');
              // print('result confidence ${confidence}');
              // print('result H $h');
              // print('result W $w');
              // print('result X $x');
              // print('result y $y');

              // print('result boudnary box H $boundaryBoxesH');
              // print('result boudnary box W $boundaryBoxesW');
              // print('result boudnary box X $boundaryBoxesX');
              // print('result boudnary box Y $boundaryBoxesY');
              /**
               * result label oven
                W/System  ( 7836): A resource failed to call destroy. 
                I/flutter ( 7836): result confidence 0.72
                I/flutter ( 7836): result boudnary box H 238.50510120391846
                I/flutter ( 7836): result boudnary box W 355.21095275878906
                I/flutter ( 7836): result boudnary box X 55.09601593017578
                I/flutter ( 7836): result boudnary box Y 100.40400981903076
               */
            }
          }
        } catch (e) {
          print("Error during object detection: $e");
        }
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
    });

    // Stop the image stream to save resources
    await controller?.stopImageStream();
  }

  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/ssd_mobilenet.tflite",
      labels: "assets/ssd_mobilenet.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  Future<List<dynamic>> objectDetectionOnFrame(CameraImage cameraImage) async {
    if (!isDetecting) return []; // Return immediately if not detecting
    var detection = await Tflite.detectObjectOnFrame(
      model: "SSDMobileNet",
      bytesList: cameraImage.planes.map((plane) {
        return plane.bytes;
      }).toList(), // required
      imageHeight: cameraImage.height,
      imageWidth: cameraImage.width,
      imageMean: 127.5, // defaults to 127.5
      imageStd: 127.5, // defaults to 127.5
      rotation: 90, // defaults to 90, Android only
      numResultsPerClass: 2, // defaults to 5
      threshold: 0.1, // defaults to 0.1
      asynch: true, // defaults to true
    );

    return detection ?? [];
  }

//   List<Widget> displayBoxesAroundRecognizedObjects() {
//     if (label.isEmpty) return [];
//     /**
//      * result label oven
// 3
//         W/System  ( 7836): A resource failed to call destroy.
//         I/flutter ( 7836): result confidence 0.72
//         I/flutter ( 7836): result boudnary box H 238.50510120391846
//         I/flutter ( 7836): result boudnary box W 355.21095275878906
//         I/flutter ( 7836): result boudnary box X 55.09601593017578
//         I/flutter ( 7836): result boudnary box Y 100.40400981903076
//      */
//     return [
//       Positioned(
//         left: boundaryBoxesX,
//         top: boundaryBoxesY,
//         child: Container(
//           width: boundaryBoxesH,
//           height: boundaryBoxesW,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(10.0),
//             border: Border.all(color: Colors.pink, width: 3.0),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.start,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(4),
//                 color: Colors.pink,
//                 child: Text(
//                   "$label ${(double.parse(confidence) * 100).toStringAsFixed(0)}%",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 12.0,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     ];
//   }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.sizeOf(context).width;
    screenHeight = MediaQuery.sizeOf(context).height;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Display CameraPreview if the controller is initialized
        if (controller?.value.isInitialized ?? false)
          CameraPreview(controller!),
        // Show loading indicator while initializing
        if (!(controller?.value.isInitialized ?? false))
          const Center(child: CircularProgressIndicator()),
        /**
         * W/System  ( 7836): A resource failed to call destroy. 
        I/flutter ( 7836): result confidence 0.72
        I/flutter ( 7836): result boudnary box H 238.50510120391846
        I/flutter ( 7836): result boudnary box W 355.21095275878906
        I/flutter ( 7836): result boudnary box X 55.09601593017578
        I/flutter ( 7836): result boudnary box Y 100.40400981903076
        7
          I/flutter ( 7836): result boudnary box H 213.52455139160156
          I/flutter ( 7836): result boudnary box W 175.29891967773438
          I/flutter ( 7836): result boudnary box X 312.1128463745117
          I/flutter ( 7836): result boudnary box Y 111.94542646408081
         */
        // Positioned(
        //   left: 100,
        //   top: 238,
        //   child: Container(
        //     width: 220,
        //     height: 400,
        //     decoration: BoxDecoration(
        //       borderRadius: BorderRadius.circular(10.0),
        //       border: Border.all(color: Colors.pink, width: 3.0),
        //     ),
        //     child: Column(
        //       mainAxisAlignment: MainAxisAlignment.start,
        //       crossAxisAlignment: CrossAxisAlignment.start,
        //       children: [
        //         Container(
        //           padding: const EdgeInsets.all(4),
        //           color: Colors.pink,
        //           child: Text(
        //             "oven 200%",
        //             style: const TextStyle(
        //               color: Colors.white,
        //               fontSize: 12.0,
        //               fontWeight: FontWeight.bold,
        //             ),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        BoundingBox(
            results: resultDetection,
            previewH: imageHeight,
            previewW: imageWidth,
            screenH: screenHeight,
            screenW: screenWidth),
        // Positioned IconButton for start/stop detection
        Positioned(
          bottom: 75,
          left: (MediaQuery.of(context).size.width - 80) /
              2, // Center the button horizontally
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                width: 5,
                color: Colors.white,
                style: BorderStyle.solid,
              ),
            ),
            child: isDetecting
                ? IconButton(
                    onPressed: stopDetection,
                    icon: const Icon(
                      Icons.stop,
                      color: Colors.red,
                    ),
                    iconSize: 50,
                  )
                : IconButton(
                    onPressed: startDetection,
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                    iconSize: 50,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    Tflite.close(); // Ensure TensorFlow Lite is closed
    super.dispose();
  }
}
