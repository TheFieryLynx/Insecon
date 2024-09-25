#!/bin/sh

rm ivanovii-111-bump.log

SSLKEYLOGFILE=ivanovii-111-bump.log curl --proxy http://127.0.0.1:3128 --cacert ivanovii-111-chain.crt https://httpbin.org/get?bio=ivanovii
