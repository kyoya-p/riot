import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riot/riot.dart';
import 'package:riot/riotWidget.dart';


void main() {
  Riot riot = Riot();
  riot.init();
  runApp(
    ChangeNotifierProvider<Riot>(
      create: (context) => riot,
      child: RiotWidget(),
    ),
  );
}
