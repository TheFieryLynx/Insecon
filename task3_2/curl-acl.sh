#!/bin/sh

rm ivanovii-111-acl.log

SSLKEYLOGFILE=ivanovii-111-acl.log curl --proxy http://127.0.0.1:3128 https://ident.me
SSLKEYLOGFILE=ivanovii-111-acl.log curl --proxy http://127.0.0.1:3128 https://httpbin.org/get?bio=ivanovii
