#!/bin/sh

GROUP=111
NAME=ivanovii

rm $NAME-$GROUP-ocsp-valid.log
SSLKEYLOGFILE=$NAME-$GROUP-ocsp-valid.log /Applications/Firefox.app/Contents/MacOS/firefox -purgecaches https://ocsp.valid.$NAME.ru
