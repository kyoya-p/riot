import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:riot/riot.dart';
import 'package:riot/schema/log.dart';

// Sample: 項目が動的なListView
// Sample: Firebaseデータ取得(ソート、index指定)
class LogView extends StatefulWidget {
  LogView({Key key}) : super(key: key);

  @override
  LogViewState createState() => LogViewState();
}

class LogViewState extends State<LogView> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Riot>(
      builder: (_, riot, __) => ListView.builder(
          reverse: true,
          itemBuilder: (context, index) {
            // とにかくMutableなWidgetを先に返し、内容は後で埋める
            MutableWidgetContent logItem =
                MutableWidgetContent(Text("loading..."));
            Widget p = ChangeNotifierProvider(
              create: (context) => logItem,
              child: MutableWidget()..notifire = logItem,
            );

            riot.getLog(index).then((Log log) {
              if (log != null) {
                String dt = log.datetime.toString();
                String t = log.topic;
                String msg = log.msg;
                logItem.setWidget(Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    //Text("$index: "),
                    Text("$dt"),
                    Expanded(child: Text("$t")),
                    Expanded(child: Text("$msg")),
                  ],
                ));
              } else {
                logItem.setWidget(Text("$index: no data"));
              }
            });
            return p;
          }),
    );
  }
}

class MutableWidgetContent extends ChangeNotifier {
  Widget childWidget;

  MutableWidgetContent(Widget initail) {
    childWidget = initail;
  }

  void setWidget(Widget update) {
    childWidget = update;
    notifyListeners();
  }
}

class MutableWidget extends StatefulWidget {
  MutableWidget();

  MutableWidgetContent notifire;
  Widget mutableWidget = Text("loading..");

  @override
  MutableWidgetState createState() => MutableWidgetState();
}

class MutableWidgetState extends State<MutableWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<MutableWidgetContent>(
      builder: (_, logItem, __) => logItem.childWidget,
    );
  }
}

class LogWidget2 extends StatefulWidget {
  LogWidget2({Key key}) : super(key: key);

  @override
  LogWidget2State createState() => LogWidget2State();
}

class LogWidget2State extends State<LogWidget2> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Riot>(
      builder: (_, riot, __) => SliverFixedExtentList(
        itemExtent: 50.0,
        delegate: null,
      ),
    );
  }
}
