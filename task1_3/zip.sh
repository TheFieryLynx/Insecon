#!/bin/sh

GROUP=111
NAME=ivanovii

zip $NAME-$GROUP-p1_3.zip \
    "$NAME-$GROUP-ocsp-valid.crt" \
    "$NAME-$GROUP-ocsp-valid.key" \
    "$NAME-$GROUP-ocsp-revoked.crt" \
    "$NAME-$GROUP-ocsp-revoked.key" \
    "$NAME-$GROUP-ocsp-resp.crt" \
    "$NAME-$GROUP-ocsp-resp.key" \
    "$NAME-$GROUP-chain.crt" \
    "$NAME-$GROUP-ocsp-valid.pcapng" \
    "$NAME-$GROUP-ocsp-valid.log" \
    "$NAME-$GROUP-ocsp-revoked.pcapng" \
    "$NAME-$GROUP-ocsp-revoked.log"
