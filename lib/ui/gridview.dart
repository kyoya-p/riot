import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riot/schema/log.dart';
import 'package:riot/ui/logList.dart';

import '../riot.dart';

class LogView_Grid extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => LogView_GridState();
}

class LogView_GridState extends State<LogView_Grid> {
  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    double columnWidth = 178; // 日時を1行で表示できるサイズ
    int columnCount = deviceSize.width ~/ columnWidth;
    int height = 66;
    double ratio = deviceSize.width * 1.0 / columnCount / height;

    return Consumer<Riot>(
      builder: (_, riot, __) => GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          childAspectRatio: ratio,
        ),
        itemBuilder: (_, index) {
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
              logItem.setWidget(LogView_GridItem(log));
            } else {
              logItem.setWidget(Text("$index: no data"));
            }
          });
          return p;
        },
      ),
    );
  }
}

class LogView_GridItem extends StatelessWidget {
  LogView_GridItem(Log this.log);

  Log log;

  @override
  Widget build(BuildContext context) {
    TextStyle ts = TextStyle(
      //backgroundColor: Colors.grey[300],
      fontSize: 13.0,
    );
    StrutStyle ss = StrutStyle(
      fontSize: 16.0,
      height: 1.5,
    );

    return Container(
      padding: EdgeInsets.all(2.0),
      margin: EdgeInsets.all(1.0),
      color: Colors.grey[200],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            log.datetime.toString(),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: ts,
            strutStyle: ss,
          ),
          //Padding(padding: EdgeInsets.only(top: 1.0)),
          Text(
            log.topic,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: ts,
            strutStyle: ss,
          ),
          //Padding(padding: EdgeInsets.only(top: 1.0)),
          Text(
            log.msg,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.left,
            style: ts,
            strutStyle: ss,
          ),
        ],
      ),
    );
  }
}
