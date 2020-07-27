@JS('mqtt')
library mqtt;

import 'package:js/js.dart';

@JS('connect')
external _MqttClient mqtt_connect(String url);

@JS()
class _MqttClient {
  static _MqttClient connect(String url) {
    return mqtt_connect(url);
  }

  external subscribe(String topic);

  external publish(String topic, String msg);

  external bool get connected;

  external on(String msg, Function handler);
}

class MqttJs {
  _MqttClient client;

  MqttJs(String url) {
    client = mqtt_connect(url);
  }

  subscribe(String topic) {
    client.subscribe(topic);
  }

  publish(String topic, String msg) {
    client.publish(topic, msg);
  }

   bool get connected {return client.connected;}


  onMessage(Function(String, Iterable<int>, Object) handler) {
    return client.on("message", allowInterop(handler));
  }

  onError(Function(Object) handler) {
    return client.on('error', allowInterop(handler));
  }
}
