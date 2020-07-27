ARG WORKTOP=/opt/tools
ARG SRCREPO=https://github.com/kyoya-p/riot
ARG SRCPATH=riot

#
# Build
#
FROM buildpack-deps:stretch-scm as build
ARG WORKTOP
ARG SRCREPO
ARG SRCPATH

RUN apt update && apt upgrade -y && apt install -y unzip
WORKDIR $WORKTOP
RUN git clone https://github.com/flutter/flutter.git
ENV PATH=$WORKTOP/flutter/bin:$PATH
RUN flutter channel beta
RUN flutter upgrade
RUN flutter config --enable-web

RUN git clone $SRCREPO

WORKDIR $WORKTOP/$SRCPATH
RUN flutter build web

# Test run with SDK tool
CMD cd $WORKTOP/$SRCPATH && flutter run --web-hostname=0.0.0.0 --web-port=80 -d web-server
