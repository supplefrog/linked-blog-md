#!/bin/bash
set -euo pipefail

APP_NAME=""
IP=""
DAYS=3650

DATA_DIR="/data/mysql"
MYCNF="/etc/my.cnf"

# =====================
# Generate certificates
# =====================
{
openssl genrsa -out ca-key.pem 2048
openssl req -new -x509 -nodes -key ca-key.pem -out ca.pem -subj "/CN=MySQL_${APP_NAME}_CA" -sha256 -days ${DAYS}

openssl genrsa -out server-key.pem 2048
openssl req -new -key server-key.pem -out server.csr -subj "/CN=${IP}"
echo "subjectAltName=IP:${IP}" > san.cnf
openssl x509 -req -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile san.cnf -sha256 -days ${DAYS}

openssl genrsa -out client-key.pem 2048
openssl req -new -key client-key.pem -out client.csr -subj "/CN=replica-client"
openssl x509 -req -in client.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -sha256 -days ${DAYS}

chown mysql:mysql *.pem
chmod 600 *-key.pem
chmod 644 *.pem
}

# =====================
# Edit my.cnf
# =====================
{
CA="${DATA_DIR}/ca.pem"
CERT="${DATA_DIR}/server-cert.pem"
KEY="${DATA_DIR}/server-key.pem"

# Remove ALL cert-related or TLS-related lines anywhere
sed -i '/ssl-ca=\|ssl-cert=\|ssl-key=\|tls_ciphersuites=\|require_secure_transport/d' "${MYCNF}"

# Append ordered block under [client] if it exists
if grep -q '^\[client\]' "${MYCNF}"; then
  sed -i "/^\[client\]/a ssl-ca=${CA}\n" "${MYCNF}"
fi

# Append ordered block under [server] if it exists
if grep -q '^\[server\]' "${MYCNF}"; then
  sed -i "/^\[server\]/a ssl-ca=${CA}\nssl-cert=${CERT}\nssl-key=${KEY}\ntls_ciphersuites=TLS_AES_256_GCM_SHA384\n#require_secure_transport\n" "${MYCNF}"
fi
}

systemctl stop mysqld
mv *.pem $DATA_DIR
systemctl start mysqld
