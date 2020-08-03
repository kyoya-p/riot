import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './riot.dart';
import './schema/log.dart';

class RiotWidget extends StatelessWidget {
  static const String _title = 'RIoT';

  @override
  Widget build(BuildContext context) {
    GlobalKey<MyStatefulWidgetState> subWidgetKey = GlobalKey();
    MyStatefulWidget myAppContent = MyStatefulWidget(key: subWidgetKey);
    return Consumer<Riot>(
      builder: (context, riot, child) => MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(title: const Text(_title)),
          body: myAppContent,
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.send),
            backgroundColor: riot.isConnected() ? Colors.blue : Colors.grey,
            onPressed: () {
              if (subWidgetKey.currentState.formKey.currentState.validate()) {
                subWidgetKey.currentState.formKey.currentState.save();
                riot.publish();
              }
              ;
            },
          ),
          drawer: DrawerWidget(),
        ),
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        onGenerateRoute: (settings) {
          print("params=$settings");
          var paths = settings.name.split('?');
          var args = Uri.splitQueryString(paths[1] ?? "");
          String broker = args['broker'];
          riot.connect(broker);
          riot.mqttClient
              .publish("r/i/o/t", "Test: Hello! This is MQTT Console.");
        },
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  MyStatefulWidget({Key key}) : super(key: key);

  @override
  MyStatefulWidgetState createState() => MyStatefulWidgetState();
}

class MyStatefulWidgetState extends State<MyStatefulWidget> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    Consumer<Riot> topicField = Consumer<Riot>(
      builder: (_, riot, __) => TextFormField(
        controller: TextEditingController(text: riot.getSendTopic()),
        decoration: const InputDecoration(
          hintText: 'Topic',
        ),
        autovalidate: true,
        validator: (value) =>
            value.isEmpty ? "Please enter some text as topic." : null,
        onChanged: (String value) => riot.setSendTopic(value),
      ),
    );
    Consumer<Riot> msgField = Consumer<Riot>(
      builder: (_, riot, __) => TextFormField(
        controller: TextEditingController(text: riot.getSendMessage()),
        decoration: const InputDecoration(
          hintText: 'Message',
        ),
        onChanged: (String value) => riot.setSendMessage(value),
      ),
    );

    Widget pad16 = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
    );
    Form form = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Consumer<Riot>(
              builder: (context, app, child) => Container(
                constraints: BoxConstraints.expand(),
                child: Scrollbar(
                  isAlwaysShown: false,
                  child: SingleChildScrollView(
                    child: Text(app.log),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: LogWidget(),
          ),
          topicField,
          msgField
        ],
      ),
    );
    return Padding(padding: EdgeInsets.all(16.0), child: form);
  }
}

class DrawerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Text('Road to IoT'),
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            title: Text("Broker Settings"),
            //trailing: Icon(Icons.arrow_forward),
            onTap: () => showDialog(
              context: context,
              builder: (_) => Consumer<Riot>(
                builder: (context, riot, child) => AlertDialog(
                  title: Text("Broker Setting"),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: <Widget>[
                        UrlSettingWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: Text("Topic Setting"),
            onTap: () => showDialog(
              context: context,
              builder: (_) => Consumer<Riot>(
                builder: (context, riot, child) => AlertDialog(
                  title: Text("Subscrib Topic"),
                  content: _scrollableTextField(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UrlSettingWidget extends StatefulWidget {
  UrlSettingWidget({Key key}) : super(key: key);

  @override
  UrlSettingWidgetState createState() => UrlSettingWidgetState();
}

class UrlSettingWidgetState extends State<UrlSettingWidget> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<Riot>(builder: (_, riot, __) {
      return TextFormField(
        initialValue: riot.brokerUrl,
        decoration: const InputDecoration(
          hintText: 'Enter URL of MQTT Broker',
        ),
        validator: (value) {
          if (value.isEmpty) {
            return 'Please enter URL';
          }
          return null;
        },
        onFieldSubmitted: (String newUrl) {
          print(newUrl);
          riot.connect(newUrl);
        },
      );
    });
  }
}

Widget _scrollableTextField(BuildContext context) => Consumer<Riot>(
    builder: (_, riot, __) => TextFormField(
          keyboardType: TextInputType.multiline,
          maxLines: null,
          textAlignVertical: TextAlignVertical.bottom,
          initialValue: riot.subscribTopics.join("\n"),
          onFieldSubmitted: (text) {
            riot.subscribe(text.split("\n").where((e) => e != "").toSet());
          },
        ));

// Sample: 項目が動的なListView
// Sample: Firebaseデータ取得(ソート、index指定)
class LogWidget extends StatefulWidget {
  LogWidget({Key key}) : super(key: key);

  @override
  LogWidgetState createState() => LogWidgetState();
}

class LogWidgetState extends State<LogWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Riot>(
      builder: (_, riot, __) => ListView.builder(
          reverse: true,
          itemBuilder: (context, index) {
            // とにかくWidgetを先に返し、内容は後で埋める Textは変更できないのでTextを格納できるWidget
            TextField tx = TextField(controller: TextEditingController(text: "loading..."),);
            riot.getLog(index).then((Log log) {
              print(log.msg);
              tx.controller.value=TextEditingValue(text: log.msg.toString());
            });
            return tx;

            //            return Text(index.toString());
          }),
    );
  }
}
