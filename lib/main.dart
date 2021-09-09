import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'slider/controller.dart';
import 'slider/view.dart';

void main() => runApp(const MyApp());

class _ScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        scrollBehavior: _ScrollBehavior(),
        home: const Scaffold(
          body: SliderWidget(),
        ),
      );
}

class SliderWidget extends StatefulWidget {
  const SliderWidget({Key? key}) : super(key: key);

  @override
  _SliderWidgetState createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget> {
  List<int> items = List<int>.generate(10, (index) => index);

  double get _viewportFraction {
    final w = MediaQuery.of(context).size.width;
    if (w > 0) {
      return 1 / 3;
    }
    if (w < 600) {
      return 1 / 3;
    }
    if (w < 1200) {
      return 1 / 4;
    }
    return 1 / 5;
  }

  @override
  Widget build(BuildContext context) {
    final SliderController controller =
        SliderController(viewportFraction: _viewportFraction);
    return SliderView(
      controller: controller,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          items.insert(newIndex, items.removeAt(oldIndex));
        });
      },
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            //width: MediaQuery.of(context).size.width / 3,
            key: ValueKey(i),
            decoration: BoxDecoration(
                color: items[i].isOdd ? Colors.black26 : Colors.black38),
            child: Center(
              child: Text(items[i].toString()),
            ),
          ),
      ],
    );
  }
}
