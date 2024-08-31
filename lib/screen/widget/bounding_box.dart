import 'dart:math' as math;
import 'package:flutter/material.dart';

class BoundingBox extends StatelessWidget {
  final List<dynamic> results;
  final double previewH;
  final double previewW;
  final double screenH;
  final double screenW;

  BoundingBox({
    required this.results,
    required this.previewH,
    required this.previewW,
    required this.screenH,
    required this.screenW,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> _renderBoxes() {
      return results.map((re) {
        var _x = re["rect"]["x"] as double;
        var _w = re["rect"]["w"] as double;
        var _y = re["rect"]["y"] as double;
        var _h = re["rect"]["h"] as double;

        double scaleW, scaleH, x, y, w, h;

        if (screenH / screenW > previewH / previewW) {
          // Scaling for portrait aspect ratio
          scaleW = screenH / previewH * previewW;
          scaleH = screenH;
          double difW = (scaleW - screenW) / scaleW;
          x = (_x - difW / 2) * scaleW;
          w = _w * scaleW;
          if (_x < difW / 2) w -= (difW / 2 - _x) * scaleW;
          y = _y * scaleH;
          h = _h * scaleH;
        } else {
          // Scaling for landscape aspect ratio
          scaleH = screenW / previewW * previewH;
          scaleW = screenW;
          double difH = (scaleH - screenH) / scaleH;
          x = _x * scaleW;
          w = _w * scaleW;
          y = (_y - difH / 2) * scaleH;
          h = _h * scaleH;
          if (_y < difH / 2) h -= (difH / 2 - _y) * scaleH;
        }

        return Positioned(
          left: math.max(0, x),
          top: math.max(0, y),
          width: w,
          height: h,
          child: Container(
            padding: const EdgeInsets.only(top: 5.0, left: 5.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromRGBO(37, 213, 253, 1.0),
                width: 3.0,
              ),
            ),
            child: Text(
              "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Color.fromRGBO(37, 213, 253, 1.0),
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList();
    }

    return Stack(
      children: _renderBoxes(),
    );
  }
}
