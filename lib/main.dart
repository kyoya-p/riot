import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:riot/riot.dart';
import 'package:riot/riotWidget.dart';

void main() {
  runApp(
    ChangeNotifierProvider<Riot>(
      create: (context) => Riot(),
      child: RiotWidget(),
    ),
  );
}
