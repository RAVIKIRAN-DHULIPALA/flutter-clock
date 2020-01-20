import 'dart:async';
import 'package:digital_clock/app_background.dart';
import 'package:digital_clock/mrngbg.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

enum _Element {
  background,
  text,
  shadow,
}

final _lightTheme = {
  _Element.background: Color(0xFF81B3FE),
  _Element.text: Colors.white,
  _Element.shadow: Colors.black,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
  _Element.shadow: Color(0xFF174EA6),
};

class DigitalClock extends StatefulWidget {
  const DigitalClock(this.model);

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock>
    with TickerProviderStateMixin {
  String _timeString;
  String _dateString;
  String _day;

  void _getTime() {
    final DateTime now = DateTime.now();
    final String formattedDateTime = _formatDateTime(now);
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat(widget.model.is24HourFormat ? 'HH:mm:ss' : 'hh:mm:ss')
        .format(dateTime);
  }

  AnimationController controller;
  Timer timer;

  @override
  void initState() {
    super.initState();
    _timeString = _formatDateTime(DateTime.now());
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
    super.initState();
    getDate();
    widget.model.addListener(_updateModel);
    _updateModel();
    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 60),
    );
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    timer.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _repeat() {
    controller.reverse(from: controller.value == 0.0 ? 1.0 : controller.value);
  }

  String _ampm;

  void getDate() {
    var now = new DateTime.now();
    var formatter = new DateFormat('dd-MM-yyyy');
    var day = DateFormat('EEEE').format(now);
    String formatted = formatter.format(now);
    var ampm =
        new DateFormat('hh:mm:ss a').format(now).toString().split(" ")[1];
    setState(() {
      _dateString = formatted;
      _day = day;
      _ampm = ampm;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget x = Theme.of(context).brightness == Brightness.light
        ? CustomPaintDemo()
        : AppBackground();
    var time = _timeString.split(":");
    var date = _dateString.toString();
    var day = _day.toString();
    var hours = "";
    var mins = "";
    var seconds = "";
    var ampm = _ampm.toString();
    try {
      hours += time[0];
      mins += time[1];
      seconds += time[2];
    } catch (Error) {}
    _repeat();
    ThemeData themeData = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white10,
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Stack(
              children: <Widget>[
                x,
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: FractionalOffset.center,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: Stack(
                              children: <Widget>[
                                Positioned.fill(
                                  child: CustomPaint(
                                      painter: CustomTimerPainter(
                                    animation: controller,
                                    backgroundColor: Colors.transparent,
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.white
                                        : themeData.indicatorColor,
                                    seconds: seconds,
                                  )),
                                ),
                                Align(
                                  alignment: FractionalOffset.topCenter,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        '${hours.toString()}:${mins.toString()}',
                                        style: TextStyle(
                                            fontSize: 80.0,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.white
                                                    : Colors.black38),
                                      ),
                                      !widget.model.is24HourFormat
                                          ? Text('${ampm.toString()}',
                                              style: TextStyle(
                                                  fontSize: 25.0,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.light
                                                      ? Colors.white
                                                      : Colors.black38))
                                          : Container(),
                                      Text('\n${date.toString()}',
                                          style: TextStyle(
                                              fontSize: 25.0,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.light
                                                  ? Colors.white
                                                  : Colors.black38)),
                                      Text('${day.toString()}',
                                          style: TextStyle(
                                              fontSize: 25.0,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.light
                                                  ? Colors.white
                                                  : Colors.black38)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }
}

class CustomTimerPainter extends CustomPainter {
  CustomTimerPainter(
      {this.animation, this.backgroundColor, this.color, this.seconds})
      : super(repaint: animation);

  final Animation<double> animation;
  final Color backgroundColor, color;
  var seconds;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color;
    var x = 1.0 - ((double.parse(seconds)) / 100);
    double progress = (1.0 - x) * 3.4 * math.pi;
    canvas.drawArc(Offset.zero & size, math.pi * 1.5, progress, false, paint);
  }

  @override
  bool shouldRepaint(CustomTimerPainter old) {
    return animation.value != old.animation.value ||
        color != old.color ||
        backgroundColor != old.backgroundColor;
  }
}
