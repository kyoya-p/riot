import 'dart:core';
import 'dart:convert';
import 'package:flutter/material.dart';
import "package:js/js.dart";
import 'package:shared_preferences/shared_preferences.dart';

import './mqttjs.dart';

// RIoTアプリケーションロジック

class Riot extends ChangeNotifier {
  String brokerUrl;
  String log = "";
  String lastMsg = "";
  List<int> lastBody = List<int>();

  MqttJs mqttClient;

  init() async {
    reconnect();
  }

  Future<void> reconnect() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    brokerUrl = prefs.getString("brokerUrl");
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
    for (int i =0;i<10 && !mqttClient.connected ;++i) {
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
      _addLog("[$p1] $msg\n");
    });
    mqttClient.onError((var v) {
      print(v);
    });
    mqttClient.subscribe("#");
  }

  void _addLog(String appendLog) {
    DateTime n = DateTime.now();
    String now = [n.hour, n.minute, n.second].map((int i) {
      return i.toString().padLeft(2, "0");
    }).join(":");
    print(appendLog);
    log = "$now " + appendLog + "\n" + log;
    notifyListeners();
  }
}
