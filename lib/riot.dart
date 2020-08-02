import 'dart:core';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riot/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart';

import './mqttjs.dart';
import './firebase.dart';
import 'Schema/Log.dart';

// RIoTアプリケーションロジック

class Riot extends ChangeNotifier {
  String brokerUrl;
  String log = "";
  Set<String> subscribTopics = Set.from(["#"]);
  MqttJs mqttClient = null;

  String _sendTopic;
  String _sendMessage;

  MyFirebase _db = MyFirebase();

  Riot() {
    _getPastLog(["#"]);
    reconnect();
  }

  setSendMessage(String msg) {
    print("setSendMessage($msg)");
    _sendMessage = msg;
    //notifyListeners();
  }

  setSendTopic(String topic) {
    print("setSendTopic($topic)");
    _sendTopic = topic;
    //notifyListeners();
  }

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
            "timestamp", ">", now.millisecondsSinceEpoch - 1000 * 60 * 60 * 24)
        .get()
        .then((value) {
      value.forEach((doc) {
        var e = doc.data();
        print("doc=$e");
        var dt = e['datetime'];
        var t = e['topic'];
        var m = e['msg'];
        log = "${dt} [$t] $m\n" + log;
      });
    });
    notifyListeners();
  }
}
