import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riot/ui/gridview.dart';
import 'package:selectable_autolink_text/selectable_autolink_text.dart';

import 'package:riot/riot.dart';
import 'package:riot/schema/log.dart';

import 'logList.dart';

class AppStyle extends ChangeNotifier {
  String logLayout = "grid"; //"grid" or "list"
}

class RiotWidget extends StatelessWidget {
  static const String _title = 'RIoT';

  @override
  Widget build(BuildContext context) {
    GlobalKey<MyStatefulWidgetState> subWidgetKey = GlobalKey();
    MyStatefulWidget myAppContent = MyStatefulWidget(key: subWidgetKey);
    return ChangeNotifierProvider<AppStyle>(
      create: (context) => AppStyle(),
      child: Consumer<Riot>(
        builder: (context, Riot riot, child) => MaterialApp(
          title: _title,
          home: Scaffold(
            appBar: AppBar(title: const Text(_title)),
            body: myAppContent,
            floatingActionButton: FloatingActionButton(
              child: Icon(Icons.send),
              backgroundColor: riot.isConnected()
                  ? Theme.of(context).accentColor
                  : Theme.of(context).disabledColor,
              onPressed: () {
                if (subWidgetKey.currentState.formKey.currentState.validate()) {
                  subWidgetKey.currentState.formKey.currentState.save();
                  riot.publish();
                }
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

    Form form = Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
              child: Consumer<AppStyle>(
            builder: (_, appStyle, __) =>
                appStyle.logLayout == "grid" ? LogView_Grid() : LogView(),
          )),
          topicField,
          msgField,
        ],
      ),
    );
    return Padding(padding: EdgeInsets.all(16.0), child: form);
  }
}

class DrawerWidget extends StatefulWidget {
  @override
  _DrawerWidgetState createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            child: Text('Road to IoT'),
            decoration: BoxDecoration(
              color: Theme.of(context).highlightColor,
            ),
          ),
          ListTile(
            title: Text("Broker Settings"),
            leading: Icon(Icons.settings),
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
            leading: Icon(Icons.settings),
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
          new RadioListTile(
            secondary: Icon(Icons.view_list),
            //activeColor: Colors.blue,
            controlAffinity: ListTileControlAffinity.trailing,
            title: Text('List View'),
            //subtitle: Text('Goodアイコンの表示'),
            value: "list",
            groupValue: style,
            onChanged: _handleRadio,
          ),
          new RadioListTile(
            secondary: Icon(Icons.view_module),
            //activeColor: Colors.orange,
            controlAffinity: ListTileControlAffinity.trailing,
            title: Text('Grid View'),
            //subtitle: Text('Favoriteアイコンの表示'),
            value: "grid",
            groupValue: style,
            onChanged: _handleRadio,
          ),
        ],
      ),
    );
  }

  String style = 'grid';

  void _handleRadio(String e) => setState(() {
        style = e;
      });
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
