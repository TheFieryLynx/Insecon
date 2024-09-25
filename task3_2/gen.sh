#!/bin/sh

NAME=ivanovii
GROUP=111
MAIL=ivanovii@gmail.com

YEAR=365

PATH_TASK_1_1=../task1_1

# #-----------<Конфиги>-----------

mkdir -p configs

cat << EOF > ./configs/config.cnf
[v3_ca]
basicConstraints=critical,CA:TRUE,pathlen:0
keyUsage=critical,digitalSignature,keyCertSign,cRLSign
EOF

#-----------<Цепочка сертификатов>-----------

openssl genrsa \
    -out $NAME-$GROUP-bump.key \
    4096

openssl req \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P3_2/CN=$NAME Squid CA/emailAddress=$MAIL" \
    -passin pass:$NAME \
    -new \
    -key $NAME-$GROUP-bump.key \
    -out $NAME-$GROUP-bump.csr

openssl x509 \
    -req \
    -extfile ./configs/config.cnf \
    -extensions v3_ca \
    -days $YEAR \
    -passin pass:$NAME \
    -CA $PATH_TASK_1_1/$NAME-$GROUP-ca.crt \
    -CAkey $PATH_TASK_1_1/$NAME-$GROUP-ca.key \
    -CAcreateserial \
    -in $NAME-$GROUP-bump.csr \
    -out $NAME-$GROUP-bump.crt

openssl x509 \
    -text \
    -noout \
    -in $NAME-$GROUP-bump.crt

openssl verify \
    -verbose \
    -CAfile $PATH_TASK_1_1/$NAME-$GROUP-ca.crt \
    $NAME-$GROUP-bump.crt \

cat $NAME-$GROUP-bump.crt $PATH_TASK_1_1/$NAME-$GROUP-ca.crt > $NAME-$GROUP-chain.crt
