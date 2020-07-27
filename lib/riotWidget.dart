import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './riot.dart';

class RiotWidget extends StatelessWidget {
  static const String _title = 'RIoT';
  MyStatefulWidget myAppContent = MyStatefulWidget();

  @override
  Widget build(BuildContext context) {
    return Consumer<Riot>(
      builder: (context, riot, child) => MaterialApp(
        title: _title,
        home: Scaffold(
          appBar: AppBar(title: const Text(_title)),
          body: myAppContent,
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
  final _formKey = GlobalKey<FormState>();

  TextFormField topicField = TextFormField(
    controller: TextEditingController(),
    decoration: const InputDecoration(
      hintText: 'Enter Topic String',
    ),
  );
  TextFormField msgField = TextFormField(
    controller: TextEditingController(),
    decoration: const InputDecoration(
      hintText: 'Enter Topic String',
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget pad16 = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
    );
    Form form = Form(
      key: _formKey,
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
          pad16,
          topicField,
          msgField,
          pad16,
          Consumer<Riot>(
            builder: (context, params, child) => FlatButton(
              color: Colors.blue,
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  params.mqttClient.publish(
                      topicField.controller.text, msgField.controller.text);
                }
              },
              child: Text('Publish'),
            ),
          ),
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
                  title: Text("Topic Setting"),
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
          //showDialog(            context: context,            builder: (context) => AlertDialog(              title: Text(newUrl),            ),);
          riot.connect(newUrl);
        },
      );
    });
  }
}

class TopicListEditorWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _scrollableTextField(context);
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
