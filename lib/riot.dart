import 'dart:core';
import 'dart:convert';

import 'package:firebase/firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './mqttjs.dart';
import './firebase.dart';
import './schema/log.dart';

// RIoTアプリケーションロジック

class Riot extends ChangeNotifier {
  String brokerUrl;
  String log = "";

  List<Log> _logList = List<Log>(); // 新しい順

  Set<String> subscribTopics = Set.from(["#"]);
  MqttJs mqttClient = null;

  String _sendTopic = "";
  String _sendMessage = "";

  MyFirebase _db = MyFirebase();
  Future<Log> _dbMutex = null;

  Riot() {
    _getPastLog(["#"]);
    reconnect();
  }

  setSendMessage(String msg) {
    _sendMessage = msg;
  }

  setSendTopic(String topic) {
    _sendTopic = topic;
  }

  String getSendTopic() => _sendTopic;

  String getSendMessage() => _sendMessage;

  subscribe(Set<String> topicList) async {
    _addLog("subscribe: [$topicList]");
    subscribTopics.forEach((e) => mqttClient.unsubscribe(e));
    topicList.forEach((e) => mqttClient.subscribe(e));
    subscribTopics = topicList;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList("subscribeTopicList", List.from(topicList));
    notifyListeners();
  }

  publish() {
    _publish(_sendTopic, _sendMessage);
    _sendMessage = "";
    reloadLog();
    notifyListeners();
  }

  bool isConnected() {
    return mqttClient != null && mqttClient.connected;
  }

  _publish(String topic, String msg) {
    DateTime pubTime = DateTime.now().toUtc();

    _db.getDb().collection("log").add({
      "ver": [0, 1],
      "topic": topic,
      "msg": msg,
      "timestamp": pubTime.millisecondsSinceEpoch,
      "datetime": pubTime.toString(),
    }).then((docRef) {
      print("Document written with ID: ${docRef.id}");
    });
    mqttClient.publish(topic, msg);
  }

  Future<void> reconnect() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    brokerUrl = prefs.getString("brokerUrl") ?? "ws://shokkaa.0t0.jp:9883";
    notifyListeners();
    print("reconnect($brokerUrl)");
    return connect(brokerUrl);
  }

  Future<void> connect(String url) async {
    print("connect('$url')");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("brokerUrl", url);
    brokerUrl = url;
    notifyListeners();

    mqttClient = MqttJs(url);
    for (int i = 0; i < 10 && !mqttClient.connected; ++i) {
      print("connect retry: $i");
      await new Future.delayed(new Duration(seconds: 1)); //connectまで時間がかかる
    }
    if (!mqttClient.connected) {
      _addLog("Failed: connect($url)");
    } else {
      _addLog("Succeeded: connect($url)");
    }
    notifyListeners();

    mqttClient.onMessage((String p1, Iterable<int> p2, Object _p3) {
      String msg = utf8.decode(p2);
      _addLog("[$p1] $msg");
    });
    mqttClient.onError((var v) {
      print("onError($v)");
    });

    Set<String> subsTopicList =
    (prefs.getStringList("subscribeTopicList") ?? ["#"]).toSet();
    subscribe(subsTopicList);
  }

  void _addLog(String appendLog) {
    DateTime n = DateTime.now();
    String now = [n.hour, n.minute, n.second].map((int i) {
      return i.toString().padLeft(2, "0");
    }).join(":");
    log = "$now $appendLog\n" + log;
    notifyListeners();
  }

  String _getPastLog(List<String> topicList) {
    print("_getPastLog($topicList)");
    DateTime now = DateTime.now().toUtc();
    log = "";
    _db
        .getDb()
        .collection("log")
        .where(
        "timestamp", ">", now.millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 7)
        .get()
        .then((value) {
      value.forEach((doc) {
        var e = doc.data();
        var dt = e['datetime'];
        var t = e['topic'];
        var m = e['msg'];
        log = "${dt} [$t] $m\n" + log;
        notifyListeners();
      });
    });
  }


  void reloadLog() {
    _logList=List<Log>();
    notifyListeners();
  }
  // Sample: firebase (ソートとindex)
  // Sample: 非同期関数のチェイン実行
  Future<Log> getLog(int index) async {
    if (_dbMutex == null) {
      _dbMutex = _getLog(index);
    } else {
      // ignore: missing_return
      _dbMutex = _dbMutex.then((_) async {
        return _getLog(index);
      });
    };
    return _dbMutex;
  }

  Future<Log> _getLog(int index) async {
    DateTime now = DateTime.now().toUtc();
    if (index < _logList.length) return _logList[index]; //キャッシュにあればそのまま返す

    // キャッシュになければDBから取得
    int marker = _logList.length == 0 ? 0 : _logList[_logList.length - 1]
        .timestamp; // 取得リストの開始点。キャッシュリストの末尾のtimestamp以降. キャッシュリスト空ならtimestanmp>=0(すべて)
    print("getLog() index=$index  Logs: ${_logList.length} After: $marker");
    await _db
        .getDb()
        .collection("log")
        //.where(        "timestamp", ">", now.millisecondsSinceEpoch - 1000 * 60 * 60 * 24 * 7)
        .orderBy("timestamp", "desc") // 時刻順(新しい順)
        //.startAfter(fieldValues: [marker]) //　
        .limit(20)
        .get()
        .then((QuerySnapshot es) {
      es.forEach((d) {
        Log log = Log(d.data());
        _logList.add(log);
        print("log=${log.datetime}");
      });
    });
    if (_logList.length <= index) return null;
    //print(_logList[index].msg);
    return _logList[index];
  }
}
