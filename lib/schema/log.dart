import 'dart:collection';

class Log {
  Log(Map<String, dynamic> m) {
    timestamp = m['timestamp'];
    datetime = DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    topic = m['topic'];
    msg = m['msg'];
    ver = [0, 1];
  }

  List<int> ver;
  int timestamp;
  DateTime datetime;
  String topic;
  String msg;
}
