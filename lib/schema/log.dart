import 'dart:collection';

class Log {
  Log(int timestamp, DateTime datetime, String topic,
      String msg) {
    ver = [0, 1];
  }

  List<int> ver;
  int timestamp;
  DateTime datetime;
  String topic;
  String msg;
}
