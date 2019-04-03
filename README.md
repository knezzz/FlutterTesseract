## Flutter create

You navigate to next page by swiping to the left. There are 2 'stages' fist is after 2 page and second one is after 3 page.

For my flutter create project I decided to do something that no one has made in Flutter.
First idea was making a 3D cube, it was shooting rainbow it was great but then I saw someone else
already made game in Flutter using cubes, so I had to do something else.

I really liked my cube, so I just added one more dimension to it. I present you tesseract or also known as eight-cell, C8, octachoron, octahedroid, cubic prism, tetracube and hypercube done in Flutter! 
With 'w' rotation and all.

It's tesseract done in Flutter with CustomPainter and matrix multiplication

### About
I'm using map function (From processing) to map values thought the app for mapping 
values from 0.0 to 1.0 to any other range from 1 to oEnd

And Start the app with dark theme and Scaffold
```dart
void main() => runApp(MaterialApp(theme: ThemeData.dark().copyWith(accentColor: Colors.white), home: Scaffold(body: MyApp())));
```

### Tesseract class
Generates tesseract points and has update function to update vector after calling setValues
that will assign new rotation x, rotation w and distance for stereographic projection
and then we get offset of the vector by getting x and z values mapped to Offset

##### Class code with comments:
```dart
class Tesseract{
  /// Looping 16 times at constructor because tesseract has 16 points (2 cubes, connected to all available edges)
  /// 
  ///   final double x = (i + 1) % 4 > 1 ? _size : -_size;
  ///   final double y = i % 4 > 1 ? _size : -_size;
  ///   final double z = i % 8 > 3 ? _size : -_size;
  ///   final double w = i % 16 > 7 ? _size : -_size;
  /// 
  /// In the end of the loop we end up with this list of Vector4's (In this case we set size as 1):
  /// 
  ///   /// First 'cube'
  ///   Vector4(-1, -1, -1, 1),
  ///   Vector4(1, -1, -1, 1),
  ///   Vector4(1, 1, -1, 1),
  ///   Vector4(-1, 1, -1, 1),
  ///   Vector4(-1, -1, 1, 1),
  ///   Vector4(1, -1, 1, 1),
  ///   Vector4(1, 1, 1, 1),
  ///   Vector4(-1, 1, 1, 1),
  ///   /// Second 'cube'
  ///   Vector4(-1, -1, -1, -1),
  ///   Vector4(1, -1, -1, -1),
  ///   Vector4(1, 1, -1, -1),
  ///   Vector4(-1, 1, -1, -1),
  ///   Vector4(-1, -1, 1, -1),
  ///   Vector4(1, -1, 1, -1),
  ///   Vector4(1, 1, 1, -1),
  ///   Vector4(-1, 1, 1, -1),
  /// 
  /// Max distance has to correlate with size
  Tesseract(this._size) : _maxDistance = _size * 2 {
    for(int i = 0; i < 16; i++)
      _points.add(Vector4((i + 1) % 4 > 1 ? _size : -_size, i % 4 > 1 ? _size : -_size, i % 8 > 3 ? _size : -_size, i % 16 > 7 ? _size : -_size));
  }

  final double _size;
  final double _maxDistance;
  final Matrix4 _canvasRot = Matrix4.rotationX(pi * 0.2) * Matrix4.rotationY(-pi * 0.6) * Matrix4.rotationZ(pi * 0.2);
  final List<Vector4> _points = <Vector4>[];

  double _x = 0.0, _w = 0.0, _shadow = 0.0;
  Matrix4 _xwRot = Matrix4.identity();
  
  /// Setting new values for tesseract for rotation x, rotation y or distance for stereographic projection.
  /// This will generate new _xwRot matrix that is used to rotate the box
  void setValues(double x, double y, double s){
    _x = x;
    _w = y;
    _shadow = s;
    _xwRot = Matrix4(cos(_x), -sin(_x), 0, 0, sin(_x), cos(_x), 0, 0, 0, 0, cos(_w), -sin(_w), 0, 0, sin(_w), cos(_w));
    _projectAll();
  }

  /// This just gets Offset for canvas to draw for vector at index
  Offset getOffset(int index) => Offset(_points[index].x, _points[index].z);
  
  /// _projectAll() will be called to calculate new Vector positions.
  void _projectAll() => _points.forEach(_project);
  
  /// Project will map vector on new values that depend on rotation and shadow 'distance' 
  /// where _sgValue is value for distance of the object in stereographic projection.
  /// _sgProjection is matrix for stereographic projection that we will multiply with _rotated to get our projected vector
  /// _sgValue maps current _shadow value to range between 1 and _stereographic projection value determined by
  /// 
  ///     _size / (_maxShadow - _rotated.w) 
  ///     
  void _project(Vector4 vector){
    final Vector4 _rotated = _xwRot * vector;
    final double _sgValue = ((_size / (_maxShadow - _rotated.w) - 1) / 1) * _shadow + 1;
    final Matrix4 _sgProjection = Matrix4.diagonal3(Vector3.all(_sgValue));
    final Vector4 _pVector = _sgProjection * _rotated;
    
    _points[_points.indexOf(vector)] = _canvasRot * _pVector;
  }
}
```

### MyAppState class
This is main screen, everything gets drawn here.
I used timer for rotations since it is less code than AnimationController.
Strings are loaded from external json file.

##### Class code with comments:
```dart
class MyAppState extends State<MyApp>{
  double _x = 0, _w = 0, _shadow = 0, _scale = 1, _scaleDiff;
  List<String> _s = <String>[];
  PageController _page;

  @override
  void initState() {
    _page = PageController();
    _loadStrings();
    Timer.periodic(Duration(milliseconds: 32), _startTimer);
    super.initState();
  }

  /// Start timer. cancel it if view is not mounted anymore
  void _startTimer(Timer t){
    if(!mounted){
      t.cancel();
      return;
    }

    /// Get current page
    final double _index = _page.hasClients ? _page.page ?? 0 : 0;
    setState((){
      _x = (_x - .01) % (pi * 2);
      _shadow = max(.0, min(1.0, _index - 1));
      _w = _index > 2.5 ? (_w + .02) % (pi * 2) : max(.0, _w - .02);
    });
  }

  /// Load from external file, convert to JSON, get values from JSON array '_' and mapp values to the List<String>
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
            alignment: const Alignment(.0, .9),
            child: Container(
              width: MediaQuery.of(context).size.width * .5,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: _s.map(_makeDot).toList())
            )
          )
        ]
      )
    );
  }

  /// Make text widget that will display Strings loaded from external text.json file
  Widget _makeText(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    alignment: const Alignment(.0, -.8),
    child: Text(s, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300))
  );

  /// Make navigation dot on bottom of the screen
  Widget _makeDot(String s){
    final double _i = (_s.indexOf(s) - (_page.page ?? .0)).clamp(.0, 1.0);
    final double _size = 12 - (2 * _i);

    return Container(width: _size, height: _size, decoration: BoxDecoration(
      color: Color.lerp(Colors.grey, Colors.black87, _i),
      shape: BoxShape.circle
    ));
  }
}
```

### TesseractPainter class
Tesseract painter will paint tesseract object on canvas.
Again we are using canvas.drawLine instead of Path because it is less code.

##### Class code with comments:
```dart
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
    
    /// Connect all cube ends to each other (Each one of those is like separate cube)
    /// Just like we needed just 4 lines (instead of 12) to make 4 planes to make cube out of 2 planes
    /// Now we need just 8 lines (instead of 48) to make 6 cubes out of 2 cubes
    for(int i = 0; i < 8; i++){
      canvas.drawLine(_tess.getOffset(i), _tess.getOffset(i + 8), p);
    }
    /// This cube will be little thicker so that one cube has better visibility in tesseract
    /// during double rotation
    p..color = Colors.white..strokeWidth = 2;
    _cube(canvas, _tess, p);
  }

  /// Connect 8 (4 on x, 4 on y and 4 on z) points to make cube wireframe
  void _cube(Canvas c, Tesseract _tess, Paint p, [int offset = 0]){
    for(int i = 0; i < 4; i++){
      c.drawLine(_tess.getOffset(offset + i), _tess.getOffset(offset + (i + 1) % 4), p);
      c.drawLine(_tess.getOffset(offset + i + 4), _tess.getOffset(offset + (i + 1) % 4 + 4), p);
      c.drawLine(_tess.getOffset(offset + i), _tess.getOffset(offset + i + 4), p);
    }
  }
}
```