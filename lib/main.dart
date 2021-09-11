// 🐦 Flutter imports:
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// 🌎 Project imports:
import 'slider/view.dart';

void main() => runApp(const _App());

class _ScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}

class _App extends StatelessWidget {
  const _App({Key? key}) : super(key: key);

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

  int get _itemsCount {
    final w = MediaQuery.of(context).size.width;
    if (w < 0) {
      return 5;
    }
    if (w < 600) {
      return 3;
    }
    if (w < 1200) {
      return 4;
    }
    return 5;
  }

  @override
  Widget build(BuildContext context) => SliderView(
        itemsCount: _itemsCount,
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
                  color: items[i].isOdd ? Colors.black26 : Colors.black38),
              child: Center(
                child: Text(items[i].toString()),
              ),
            ),
        ],
      );
}
