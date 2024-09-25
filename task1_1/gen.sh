#!/bin/sh

DEBUG=0

GROUP=111
NAME=ivanovii
EMAIL=ivanovii@gmail.com
YEAR=365
YEAR3=1095
DAYS=90

echo '\n\n-----------<TASK 1_1>-----------\n\n' 

#-----------<Конфиги>-----------

mkdir -p configs

cat << EOF > ./configs/intr-ext-x509.cnf
[v3_ca]
basicConstraints=critical,pathlen:0,CA:TRUE
keyUsage=critical,digitalSignature,keyCertSign,cRLSign
EOF

cat << EOF > ./configs/basic-ext-x509.cnf
[v3_ca]
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature
extendedKeyUsage=critical,serverAuth,clientAuth
subjectAltName=DNS:basic.$NAME.ru,DNS:basic.$NAME.com
EOF


#-----------<Корневой>-----------
echo '\n\n-----------<Корневой>-----------\n\n'

# Ключевая пара:
# – RSA 4096 бит;
# – Зашифрован AES256, пароль<фамилияио>;

openssl genrsa \
    -aes256 \
    -passout pass:$NAME \
    -out $NAME-$GROUP-ca.key \
    4096

#  Сертификат
# – Самоподписной;
# – Срокдействия 3 года;
# – C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, OU=<фамилияио> P1_1, CN=<фамилияио> CA, email=<адрес вашей почты>;
# – X.509v3 расширения:
#   ● Basic Constrains: 
#       – Critical
#       – CA=True
#   ● Key Usage: 
#       – Critical
#       – Digital Signature 
#       – Certificate Sign 
#       – CRL sign.

openssl req \
    -new \
    -x509 \
    -days $YEAR3 \
    -key $NAME-$GROUP-ca.key \
    -out $NAME-$GROUP-ca.crt \
    -passin pass:$NAME \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_1/CN=$NAME CA/emailAddress=$EMAIL" \
    -addext "basicConstraints=critical,CA:true" \
    -addext "keyUsage=critical,digitalSignature,keyCertSign,cRLSign" 


# проверить содержимое ключа
if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-ca.crt
fi

# верификация ключа

openssl verify \
    -verbose \
    -CAfile $NAME-$GROUP-ca.crt \
    $NAME-$GROUP-ca.crt

#-----------<Промежуточный>-----------

echo '\n\n-----------<Промежуточный>-----------\n\n'

# Ключевая пара:
# – RSA 4096 бит;
# – Зашифрован AES256,пароль<фамилияио>;

# 1. Сгенерировать ключевую пару

openssl genrsa \
    -aes256 \
    -passout pass:$NAME \
    -out $NAME-$GROUP-intr.key \
    4096

# Сертификат
# – Подписан корневым сертификатом;
# – Срокдействия 1 год;
# – C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, CN=<фамилияио> Intermediate CA, OU=<фамилияио> P1_1, email=<адрес вашей почты>;
# – X.509v3 расширения:
#   ● Basic Constrains: 
#       – Critical
#       – PathLen=0 
#       – CA=True
#   ● Key Usage: 
#       – Critical
#       – Digital Signature 
#       – Certificate Sign 
#       – CRL sign.

# 2. Сгенерировать запрос сертификата к удостоверяющему центру, 
#       содержащего все атрибуты сертификата;

openssl req \
    -new \
    -key $NAME-$GROUP-intr.key \
    -out $NAME-$GROUP-intr.csr \
    -passin pass:$NAME \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_1/CN=$NAME Intermediate CA/emailAddress=$EMAIL"

# 3. Удостоверяющий центр выпускает сертификат, 
#       используя запрос сертификата как источник данных атрибутов, 
#           а также подписывает его при помощи своего закрытого ключа.

openssl x509 \
    -req \
    -days $YEAR \
    -passin pass:$NAME \
    -CA $NAME-$GROUP-ca.crt \
    -CAkey $NAME-$GROUP-ca.key \
    -in $NAME-$GROUP-intr.csr \
    -out $NAME-$GROUP-intr.crt \
    -extensions v3_ca \
    -extfile ./configs/intr-ext-x509.cnf

# проверить содержимое ключа

if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-intr.crt
fi

# верификация ключа

openssl verify \
    -verbose \
    -CAfile $NAME-$GROUP-ca.crt \
    $NAME-$GROUP-intr.crt


#-----------<Базовый>-----------

echo '\n\n-----------<Базовый>-----------\n\n'

# Ключевая пара:
#   – RSA 2048 бит;

openssl genrsa \
    -out $NAME-$GROUP-basic.key \
    2048

# Сертификат
# – Подписан промежуточным сертификатом;
# – Срокдействия 90 дней;
# – C=RU, ST=Moscow, L=Moscow, O=<фамилияио>, OU=<фамилияио> P1_1, CN=<фамилияио> Basic, email=<адрес вашей почты>;
# – X.509v3расширения:
#   ● Basic Constrains: 
#       – CA=False
#   ● Key Usage (Critical): 
#       – Digital Signature
#   ● Extended Key Usage (Critical): 
#       – TLS Web Server Authentication
#       – TLS Web Client Authentication
#   ● Subject Alternative Name: 
#       – basic.<фамилияио>.ru
#       – basic.<фамилияио>.com

openssl req \
    -new \
    -key $NAME-$GROUP-basic.key \
    -out $NAME-$GROUP-basic.csr \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=$NAME/OU=$NAME P1_1/CN=$NAME Basic/emailAddress=$EMAIL"

openssl x509 \
    -req \
    -days $DAYS \
    -passin pass:$NAME \
    -CA $NAME-$GROUP-intr.crt \
    -CAkey $NAME-$GROUP-intr.key \
    -in $NAME-$GROUP-basic.csr \
    -out $NAME-$GROUP-basic.crt \
    -extensions v3_ca \
    -extfile ./configs/basic-ext-x509.cnf

# проверить содержимое ключа

if [ $DEBUG == 1 ] 
then
    openssl x509 \
        -text \
        -noout \
        -in $NAME-$GROUP-basic.crt
fi

# верификация ключа

TMPCRT=./tmp.crt
cat $NAME-$GROUP-ca.crt $NAME-$GROUP-intr.crt > $TMPCRT

openssl verify \
    -verbose \
    -CAfile $TMPCRT \
    $NAME-$GROUP-basic.crt

rm $TMPCRT

zip $NAME-$GROUP-p1_1.zip \
    $NAME-$GROUP-ca.key \
    $NAME-$GROUP-ca.crt \
    $NAME-$GROUP-intr.key \
    $NAME-$GROUP-intr.crt \
    $NAME-$GROUP-basic.key \
    $NAME-$GROUP-basic.crt
