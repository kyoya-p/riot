import 'package:firebase/firebase.dart';
import 'package:firebase/firestore.dart';
import 'dart:math';

class MyFirebase {
  App _app = null;
  Firestore _db = null;
  String _myfirebaseName =
      "myfirebase${Random(DateTime.now().millisecondsSinceEpoch).nextInt(100000)}";

  // TODO: 非同期(async)に書き換え
  Firestore getDb() {
    while (_db == null) {
      try {
        _app = app(_myfirebaseName);
      } catch (e) {
        while (_app == null) {
          print("Initiate Firebase application.");
          _app = initializeApp(
            apiKey: "AIzaSyDrO7W7Sb6RCpHTsY3GaP-zODRP_HtY4nI",
            authDomain: "road-to-iot.firebaseapp.com",
            databaseURL: "https://road-to-iot.firebaseio.com",
            projectId: "road-to-iot",
            storageBucket: "road-to-iot.appspot.com",
            //messagingSenderId: "307495712434",
            //appId: "1:307495712434:web:acc483c0c300549ff33bab",
            //measurementId: "G-1F2ZQXB15M"
            name: _myfirebaseName,
          );
        }
      }
      print("Initiate Firebase instance.");
      _db = _app.firestore();
      _db.enablePersistence().catchError((err) {
        if (err.code == 'failed-precondition') {
          print("enablePersistence(): ${err.code}");
        } else if (err.code == 'unimplemented') {
          print("enablePersistence(): ${err.code}");
        }
      });
    }
    return _db;
  }
}
