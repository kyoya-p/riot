#!/bin/sh
sudo docker build -t kyoyap/riot .
sudo docker run -p 8180:80 kyoyap/riot
