#!/bin/sh

GROUP=111
NAME=ivanovii

rm $NAME-$GROUP-ocsp-revoked.log
SSLKEYLOGFILE=$NAME-$GROUP-ocsp-revoked.log /Applications/Firefox.app/Contents/MacOS/firefox -purgecaches --private-window https://ocsp.revoked.$NAME.ru
