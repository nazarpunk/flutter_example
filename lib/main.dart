import 'package:flutter/material.dart';
import 'package:page_view/physics.dart';

import 'scroll.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
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

  @override
  Widget build(BuildContext context) {
    final SliderController controller =
        SliderController(viewportFraction: 1 / 3);
    return SliderView(
      physics: const SliderScrollPhysics(itemsCount: 3),
      controller: controller,
      children: [
        for (var i = 0; i < items.length; i++)
          Container(
            decoration:
                BoxDecoration(color: i.isOdd ? Colors.black26 : Colors.black38),
            child: Center(
              child: Text('$i'),
            ),
          ),
      ],
    );
  }
}
