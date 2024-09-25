#!/bin/sh

DEBUG=0

GROUP=111
NAME=ivanovii
EMAIL=ivanovii@gmail.com
YEAR=365
YEAR3=1095
DAYS=90

PATH_TASK_1_1=../task1_1

echo '\n\n-----------<TASK 1_2>-----------\n\n' 

#-----------<Генерация 1_1>-----------

echo '\n\n-----------<Генерация 1_1 (запуск)>-----------\n\n' 
cd ../task1_1/
./gen.sh
cd ../task1_2/
echo '\n\n-----------<Генерация 1_1 завершилась>-----------\n\n' 

#-----------<Конфиги>-----------

mkdir -p configs

cat << EOF > ./configs/crl-valid-ext-x509.cnf
[v3_ca]
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,serverAuth,clientAuth
subjectAltName=DNS:crl.valid.$NAME.ru
crlDistributionPoints=URI:http://crl.$NAME.ru
EOF

cat << EOF > ./configs/crl-revoked-ext-x509.cnf
[v3_ca]
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,serverAuth,clientAuth
subjectAltName=DNS:crl.revoked.$NAME.ru
crlDistributionPoints=URI:http://crl.$NAME.ru
EOF

rm index.txt*
touch index.txt

cat << EOF > ./configs/crl.cnf
[ca]
default_ca=my_ca_default

[my_ca_default]
database=index.txt
default_md=sha256
default_crl_days=30 

[extx]
authorityKeyIdentifier=keyid
EOF

#-----------<Цепочка сертификатов>-----------

CHAINCRT=./$NAME-$GROUP-chain.crt
cat $PATH_TASK_1_1/$NAME-$GROUP-ca.crt $PATH_TASK_1_1/$NAME-$GROUP-intr.crt > $CHAINCRT

#-----------<Валидный>-----------

echo '\n\n-----------<Валидный>-----------\n\n'

# Свойства соответствуют сертификату Basic из задания No1, кроме:
#   ● C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, OU=<фамилияио> P1_2, CN=<фамилияио> CRL Valid, email=<адрес вашей почты>;
#   ● Присутствует атрибут X509v3 Subject Alternative Name: crl.valid.<фамилияио>.ru (только один домен)
#   ● Присутствует атрибут X509v3 CRL Distribution Points, URL сервера распространения CRL: http://crl.<фамилияио>.ru


openssl genrsa \
    -out $NAME-$GROUP-crl-valid.key \
    2048

openssl req \
    -new \
    -key $NAME-$GROUP-crl-valid.key \
    -out $NAME-$GROUP-crl-valid.csr \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_2/CN=$NAME CRL Valid/emailAddress=$EMAIL"

openssl x509 \
    -req \
    -days $DAYS \
    -passin pass:$NAME \
    -CA $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -CAkey $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -in $NAME-$GROUP-crl-valid.csr \
    -out $NAME-$GROUP-crl-valid.crt \
    -extensions v3_ca \
    -extfile ./configs/crl-valid-ext-x509.cnf

# проверить содержимое ключа
if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-crl-valid.crt
fi

# верификация ключа

openssl verify \
    -verbose \
    -CAfile $CHAINCRT \
    $NAME-$GROUP-crl-valid.crt

#-----------<Отозванный>-----------

echo '\n\n-----------<Отозванный>-----------\n\n'

# Свойства соответствуют сертификату Basic из задания No1, кроме:
#   ● C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, OU=<фамилияио> P1_2, CN=<фамилияио> CRL Revoked, email=<адрес вашей почты>;
#   ● Присутствует атрибут X509v3 Subject Alternative Name: crl.revoked.<фамилияио>.ru (только один домен)
#   ● Присутствует атрибут X509v3 CRL Distribution Points, URL сервера распространения CRL: http://crl.<фамилияио>.ru;

openssl genrsa \
    -out $NAME-$GROUP-crl-revoked.key \
    2048

openssl req \
    -new \
    -key $NAME-$GROUP-crl-revoked.key \
    -out $NAME-$GROUP-crl-revoked.csr \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_2/CN=$NAME CRL Revoked/emailAddress=$EMAIL"

openssl x509 \
    -req \
    -days $DAYS \
    -passin pass:$NAME \
    -CA $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -CAkey $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -in $NAME-$GROUP-crl-revoked.csr \
    -out $NAME-$GROUP-crl-revoked.crt \
    -extensions v3_ca \
    -extfile ./configs/crl-revoked-ext-x509.cnf

# проверить содержимое ключа
if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-crl-revoked.crt
fi

# верификация ключа

openssl verify \
    -verbose \
    -CAfile $CHAINCRT \
    $NAME-$GROUP-crl-revoked.crt

#-----------<CRL>-----------

echo '\n\n-----------<CRL>-----------\n\n'

openssl ca \
    -passin pass:$NAME \
    -cert $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -keyfile $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -revoke $NAME-$GROUP-crl-revoked.crt \
    -crlexts extx \
    -config ./configs/crl.cnf

openssl ca \
    -gencrl \
    -passin pass:$NAME \
    -cert $PATH_TASK_1_1/"$NAME-$GROUP-intr.crt" \
    -keyfile $PATH_TASK_1_1/"$NAME-$GROUP-intr.key" \
    -out $NAME-$GROUP.crl \
    -crlexts extx \
    -config ./configs/crl.cnf

# проверить содержимое crl
if [ $DEBUG == 1 ] 
then
    openssl crl \
        -noout \
        -text \
        -in $NAME-$GROUP.crl
fi


# верификация ключа

echo '\n\n-----------<Revocked check: >-----------\n\n'

openssl verify \
    -crl_check \
    -verbose \
    -CAfile $NAME-$GROUP-chain.crt \
    -CRLfile $NAME-$GROUP.crl \
    $NAME-$GROUP-crl-revoked.crt

echo '\n\n-----------<Vaild check: >-----------\n\n'

openssl verify \
    -crl_check \
    -verbose \
    -CAfile $NAME-$GROUP-chain.crt \
    -CRLfile $NAME-$GROUP.crl \
    $NAME-$GROUP-crl-valid.crt

zip $NAME-$GROUP-p1_2.zip \
    $NAME-$GROUP-crl-valid.key \
    $NAME-$GROUP-crl-valid.crt \
    $NAME-$GROUP-crl-revoked.key \
    $NAME-$GROUP-crl-revoked.crt \
    $NAME-$GROUP.crl \
    $NAME-$GROUP-chain.crt
