import 'dart:core';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './mqttjs.dart';

// RIoTアプリケーションロジック

class Riot extends ChangeNotifier {
  String brokerUrl;
  String log = "";
  Set<String> subscribTopics = Set.from(["#"]);
  MqttJs mqttClient;

  init() async {
    reconnect();
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

  Future<void> reconnect() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    brokerUrl = prefs.getString("brokerUrl") ?? "ws://192.168.3/102:9887";
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
}
