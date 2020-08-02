#!/bin/sh
cd ..
flutterw.web config --enable-web
flutterw.web build web
mv build/web up/mcd up
cd up
sudo docker build -t kyoyap/riot-img .
sudo docker push kyoyap/riot-img
