#!/bin/sh

DEBUG=1

GROUP=111
NAME=ivanovii
EMAIL=ivanovii@gmail.com
YEAR=365
YEAR3=1095
DAYS=90

PATH_TASK_1_1=../task1_1

echo '\n\n-----------<TASK 1_3>-----------\n\n' 

# #-----------<Конфиги>-----------

mkdir -p configs

cat << EOF > ./configs/ocsp-resp-ext-x509.cnf
[v3_ca]
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=OCSPSigning
EOF

cat << EOF > ./configs/ocsp-valid-ext-x509.cnf
[v3_ca]
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,serverAuth,clientAuth
subjectAltName=DNS:ocsp.valid.$NAME.ru
authorityInfoAccess=OCSP;URI:http://ocsp.$NAME.ru:2560
EOF


cat << EOF > ./configs/ocsp-revoked-ext-x509.cnf
[v3_ca]
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,serverAuth,clientAuth
subjectAltName=DNS:ocsp.revoked.$NAME.ru
authorityInfoAccess=OCSP;URI:http://ocsp.$NAME.ru:2560
EOF


rm index.txt*
touch index.txt

cat << EOF > ./configs/ocsp.cnf
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

#-----------<OCSP Responder>-----------

echo '\n\n-----------<OCSP Responder>-----------\n\n'

# Ключевая пара:
#   – RSA 4096бит;
#   – Зашифрован AES 256, пароль <фамилияио>;

openssl genrsa \
    -aes256 \
    -passout pass:$NAME \
    -out $NAME-$GROUP-ocsp-resp.key \
    4096

# Сертификат
# – Подписан промежуточным сертификатом;
# – Срокдействия 1 год;
# – C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, OU=<фамилияио> P1_3, CN=<фамилияио> OCSP Responder, email=<адрес вашей почты>;
# – X.509v3 расширения:
#   ● Basic Constrains: 
#       – CA=False
#   ● Key Usage: 
#       – Critical
#       – Digital Signature
#   ● Extended Key Usage:
#       – OCSP Signing

openssl req \
    -new \
    -passin pass:$NAME \
    -key $NAME-$GROUP-ocsp-resp.key \
    -out $NAME-$GROUP-ocsp-resp.csr \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_3/CN=$NAME OCSP Responder/emailAddress=$EMAIL"

openssl x509 \
    -req \
    -days $YEAR \
    -passin pass:$NAME \
    -CA $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -CAkey $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -in $NAME-$GROUP-ocsp-resp.csr \
    -out $NAME-$GROUP-ocsp-resp.crt \
    -extensions v3_ca \
    -extfile ./configs/ocsp-resp-ext-x509.cnf

# проверить содержимое ключа
if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-ocsp-resp.crt
fi

# верификация ключа
echo '\nverify OCSP Responder: \n'

openssl verify \
    -verbose \
    -CAfile $CHAINCRT \
    $NAME-$GROUP-ocsp-resp.crt




#-----------<Валидный>-----------

echo '\n\n-----------<Валидный>-----------\n\n'

# СвойствасоответствуютсертификатуBasicиззаданияNo1,кроме:
# ● C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, OU=<фамилияио> P1_3, CN=<фамилияио> OCSP Valid, email=<адрес вашей почты>;
# ● Присутствует атрибут X509v3 Subject Alternative Name: ocsp.valid.<фамилияио>.ru (только один домен)
# ● Присутствует атрибут X509v3 Authority Information Access, URL OSCP Responder: http://ocsp.<фамилияио>.ru
# – Отсутствоватьвспискеотозванныхсертификатов;

openssl genrsa \
    -out $NAME-$GROUP-ocsp-valid.key \
    2048

openssl req \
    -new \
    -key $NAME-$GROUP-ocsp-valid.key \
    -out $NAME-$GROUP-ocsp-valid.csr \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_3/CN=$NAME OCSP Valid/emailAddress=$EMAIL"

openssl x509 \
    -req \
    -days $DAYS \
    -passin pass:$NAME \
    -CA $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -CAkey $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -in $NAME-$GROUP-ocsp-valid.csr \
    -out $NAME-$GROUP-ocsp-valid.crt \
    -extensions v3_ca \
    -extfile ./configs/ocsp-valid-ext-x509.cnf

# проверить содержимое ключа
if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-ocsp-valid.crt
fi

# верификация ключа

openssl verify \
    -verbose \
    -CAfile $CHAINCRT \
    $NAME-$GROUP-ocsp-valid.crt



#-----------<Отозванный>-----------

echo '\n\n-----------<Отозванный>-----------\n\n'

# Отозванный сертификат:
# – СвойствасоответствуютсертификатуBasicиззаданияNo1,кроме:
# ● C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, OU=<фамилияио> P1_3, CN=<фамилияио> OCSP Revoked, email=<адрес вашей почты>;
# ● Присутствует атрибут X509v3 Subject Alternative Name: ocsp.revoked.<фамилияио>.ru (только один домен)
# ● Присутствует атрибут X509v3 Authority Information Access, URL OSCP Responder: http://ocsp.<фамилияио>.ru
# – Присутствоватьвспискеотозванныхсертификатов.

openssl genrsa \
    -out $NAME-$GROUP-ocsp-revoked.key \
    2048

openssl req \
    -new \
    -key $NAME-$GROUP-ocsp-revoked.key \
    -out $NAME-$GROUP-ocsp-revoked.csr \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_3/CN=$NAME OCSP Revoked/emailAddress=$EMAIL"

openssl x509 \
    -req \
    -days $DAYS \
    -passin pass:$NAME \
    -CA $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -CAkey $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -in $NAME-$GROUP-ocsp-revoked.csr \
    -out $NAME-$GROUP-ocsp-revoked.crt \
    -extensions v3_ca \
    -extfile ./configs/ocsp-revoked-ext-x509.cnf

# проверить содержимое ключа
if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-ocsp-revoked.crt
fi

# верификация ключа

openssl verify \
    -verbose \
    -CAfile $CHAINCRT \
    $NAME-$GROUP-ocsp-revoked.crt


#-----------<OCSP>-----------

echo '\n\n-----------<OCSP>-----------\n\n'


openssl ca \
    -passin pass:$NAME \
    -cert $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -keyfile $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -valid $NAME-$GROUP-ocsp-valid.crt \
    -config ./configs/ocsp.cnf

openssl ca \
    -passin pass:$NAME \
    -cert $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -keyfile $PATH_TASK_1_1/$NAME-$GROUP-intr.key \
    -revoke $NAME-$GROUP-ocsp-revoked.crt \
    -config ./configs/ocsp.cnf

openssl ocsp \
    -port 2560 \
    -index index.txt \
    -passin pass:$NAME \
    -CA $NAME-$GROUP-chain.crt \
    -rkey $NAME-$GROUP-ocsp-resp.key \
    -rsigner $NAME-$GROUP-ocsp-resp.crt & PIDocsp=$!

echo "pid ocsp: $PIDocsp"

openssl ocsp \
    -url http://ocsp.$NAME.ru:2560 \
    -issuer $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -CAfile $NAME-$GROUP-chain.crt \
    -cert $NAME-$GROUP-ocsp-valid.crt

openssl ocsp \
    -url http://ocsp.$NAME.ru:2560 \
    -issuer $PATH_TASK_1_1/$NAME-$GROUP-intr.crt \
    -CAfile $NAME-$GROUP-chain.crt \
    -cert $NAME-$GROUP-ocsp-revoked.crt

cat $NAME-$GROUP-ocsp-revoked.crt $PATH_TASK_1_1/$NAME-$GROUP-intr.crt $PATH_TASK_1_1/$NAME-$GROUP-ca.crt > fullchain-revoked.crt
cat $NAME-$GROUP-ocsp-valid.crt $PATH_TASK_1_1/$NAME-$GROUP-intr.crt $PATH_TASK_1_1/$NAME-$GROUP-ca.crt > fullchain-valid.crt

# kill $PIDocsp


    
    








