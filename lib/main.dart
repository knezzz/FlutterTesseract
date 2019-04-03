import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

void main() => runApp(MaterialApp(theme: ThemeData.dark().copyWith(accentColor: Colors.white), home: Scaffold(body: MyApp())));

class MyApp extends StatefulWidget{
  @override MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp>{
  double _x = 0, _w = 0, _shadow = 0, _scale = 1, _scaleDiff;
  List<String> _s = <String>[];
  PageController _page;

  @override
  void initState() {
    super.initState();
    _page = PageController();
    _loadStrings();
    Timer.periodic(Duration(milliseconds: 32), _startTimer);
  }

  void _startTimer(Timer t){
    if(!mounted){
      t.cancel();
      return;
    }

    final double _index = _page.hasClients ? _page.page ?? 0 : 0;
    setState((){
      _x = (_x - .01) % (pi * 2);
      _shadow = max(.0, min(1.0, _index - 1));
      _w = _index > 2.5 ? (_w + .02) % (pi * 2) : max(.0, _w - .02);
    });
  }

  void _loadStrings() async => _s = List<dynamic>.of(json.decode(await DefaultAssetBundle.of(context).loadString('text.json'))['_']).map<String>((dynamic d) => d).toList();

  @override
  Widget build(BuildContext context){
    return GestureDetector(
      onScaleStart: (_) => _scaleDiff = _scale,
      onScaleUpdate: (ScaleUpdateDetails d) => _scale = d.scale * _scaleDiff,
      child: Stack(
        children: <Widget>[
          CustomPaint(painter: TesseractPainter(_x, _w, _shadow, _scale), child: const SizedBox.expand()),
          PageView(controller: _page, children: _s.map(_makeText).toList()),
          Container(
            alignment: const Alignment(0, .9),
            child: Container(
              width: MediaQuery.of(context).size.width * .5,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _s.map(_makeDot).toList())
            )
          )
        ]
      )
    );
  }

  Widget _makeText(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    alignment: const Alignment(0, -.8),
    child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300))
  );

  Widget _makeDot(String s){
    final double _i = (_s.indexOf(s) - (_page.page ?? .0)).clamp(.0, 1.0);
    final double _size = 12 - (2 * _i);

    return Container(width: _size, height: _size, decoration: BoxDecoration(
      color: Color.lerp(Colors.grey, Colors.black87, _i),
      shape: BoxShape.circle
    ));
  }
}

class Tesseract{
  Tesseract(this._size) : _maxShadow = _size * 2 {
    for(int i = 0; i < 16; i++)
      _v.add(Vector4((i + 1) % 4 > 1 ? _size : -_size, i % 4 > 1 ? _size : -_size, i % 8 > 3 ? _size : -_size, i % 16 > 7 ? _size : -_size));
  }

  final double _size, _maxShadow;
  final Matrix4 _cRot = Matrix4.rotationX(pi * .2) * Matrix4.rotationY(-pi * .6) * Matrix4.rotationZ(pi * .2);
  final List<Vector4> _v = <Vector4>[];

  double _x = 0, _w = 0, _shadow = 0;
  Matrix4 _xwRot = Matrix4.identity();

  void setValues(double x, double y, double s){
    _x = x;
    _w = y;
    _shadow = s;
    _xwRot = Matrix4(cos(_x), -sin(_x), 0, 0, sin(_x), cos(_x), 0, 0, 0, 0, cos(_w), -sin(_w), 0, 0, sin(_w), cos(_w));
    _projectAll();
  }

  void _projectAll() => _v.forEach(_project);
  Offset getOffset(int index) => Offset(_v[index].x, _v[index].z);

  void _project(Vector4 v){
    final Vector4 _rotated = _xwRot * v;
    final double _sgValue = (_size / (_maxShadow - _rotated.w) - 1) * _shadow + 1;
    final Matrix4 _sgProjection = Matrix4.diagonal3(Vector3.all(_sgValue));
    final Vector4 _pVector = _sgProjection * _rotated;
    _v[_v.indexOf(v)] = _cRot * _pVector;
  }
}

class TesseractPainter extends CustomPainter{
  TesseractPainter(this.x, this.w, this.shadow, this.scale);

  final double x, w, shadow, scale;
  final Paint p = Paint()..strokeWidth = .4..color = Colors.white..strokeCap = StrokeCap.round;

  Tesseract _tess;

  @override bool shouldRepaint(TesseractPainter oldDelegate) => x != oldDelegate.x || w != oldDelegate.w || shadow != oldDelegate.shadow;

  @override
  void paint(Canvas canvas, Size size) {
    if(size.shortestSide == 0)
      return;

    _tess ??= Tesseract(size.shortestSide * .2 * scale);
    _tess..setValues(x, w, shadow);

    canvas.translate(size.width / 2, size.height / 2);
    _cube(canvas, _tess, p, 8);
    for(int i = 0; i < 8; i++){
      canvas.drawLine(_tess.getOffset(i), _tess.getOffset(i + 8), p);
    }
    p..color = Colors.white..strokeWidth = 2;
    _cube(canvas, _tess, p);
  }

  void _cube(Canvas c, Tesseract _tess, Paint p, [int offset = 0]){
    for(int i = 0; i < 4; i++){
      c.drawLine(_tess.getOffset(offset + i), _tess.getOffset(offset + (i + 1) % 4), p);
      c.drawLine(_tess.getOffset(offset + i + 4), _tess.getOffset(offset + (i + 1) % 4 + 4), p);
      c.drawLine(_tess.getOffset(offset + i), _tess.getOffset(offset + i + 4), p);
    }
  }
}