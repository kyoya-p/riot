# riot - Road to IoT

MQTT monitoring tool.

## テスト実行
   ---------
```
flutter run --web-hostname=0.0.0.0 --web-port=8080 -d web-server
```

## 参考
##### mosquittoのwss対応
https://qiita.com/kuboon/items/f424b84c718619460c6f

## プロジェクト履歴

1. flutter SDKの設置
    > [参考:Windows向け] (https://flutter.dev/docs/get-started/install/windows)

2. flutterのターゲットにwebを追加
    > flutter config --enable-web
                         
    この設定は $HOME に格納される

3. 初期プロジェクト作成
    > flutter create .


## Intelli-J設定
- Flutter plugin導入
- Settings > Framwork > Flutter > パスを入力

## パッケージ追加
- pubspec.yaml を編集
- flutter pub get // 依存関係で実行される

## MQTTモジュール追加
web/index.htmlにmqtt.jsのロードを追加
  > https://unpkg.com/mqtt/dist/mqtt.min.js

## shared_preference追加
