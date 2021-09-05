import 'package:flutter/material.dart';
import 'slider/controller.dart';
import 'slider/view.dart'; // ignore: unused_import
import 'slider/view_reorderable.dart'; // ignore: unused_import

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

  List<TextSpan> _debugText = [];
  String _status = '';
  final int _itemsCount = 3;

  @override

  /// [PageView]
  // ignore: prefer_expression_function_bodies
  Widget build(BuildContext context) {
    final SliderController controller =
        SliderController(viewportFraction: 1 / 3);
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              _status = 'S';
            } else if (notification is ScrollUpdateNotification) {
              _status = 'U';
            } else if (notification is ScrollEndNotification) {
              _status = 'E';
            }

            if (notification is ScrollUpdateNotification) {
              final p = notification.metrics;
              final double vp = p.viewportDimension;
              final double _itemSize = vp / _itemsCount;
              final int _itemCurrent = (p.pixels / _itemSize).round();

              final _positions = StringBuffer()..write('0');
              for (var i = 1; i < 6; i++) {
                _positions.write(', ${(i * _itemSize).toInt()}');
              }

              const _s = TextStyle(color: Colors.grey);

              List<TextSpan> _d = [
                const TextSpan(text: '\n status: ', style: _s),
                TextSpan(text: _status.toString()),
                const TextSpan(text: '\n pixels: ', style: _s),
                TextSpan(text: p.pixels.toStringAsFixed(0)),
                const TextSpan(text: '\n viewport: ', style: _s),
                TextSpan(text: vp.toStringAsFixed(0)),
                const TextSpan(text: '\n itemSize: ', style: _s),
                TextSpan(text: _itemSize.toStringAsFixed(0)),
                const TextSpan(text: '\n itemCount: ', style: _s),
                TextSpan(text: _itemsCount.toString()),
                const TextSpan(text: '\n itemCurrent: ', style: _s),
                TextSpan(text: _itemCurrent.toString()),
                const TextSpan(text: '\n'),
                TextSpan(text: p.minScrollExtent.toStringAsFixed(0)),
                const TextSpan(text: '..[', style: _s),
                TextSpan(text: _positions.toString()),
                const TextSpan(text: ']..', style: _s),
                TextSpan(text: p.maxScrollExtent.toStringAsFixed(0)),
              ];

              setState(() {
                _debugText = _d;
              });
            }
            return false;
          },
          child: SliderViewReorderable(
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
                  width: MediaQuery.of(context).size.width / 3,
                  key: ValueKey(i),
                  decoration: BoxDecoration(
                      color: i.isOdd ? Colors.black26 : Colors.black38),
                  child: Center(
                    child: Text(items[i].toString()),
                  ),
                ),
            ],
          ),
        ),
        RichText(
          text: TextSpan(
              children: _debugText,
              style: const TextStyle(
                  color: Colors.white, backgroundColor: Colors.black)),
        ),
      ],
    );
  }
}
