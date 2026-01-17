systemctl stop mysqld;

cat <<EOF > /sbin/mysqld.my
{
  "components": "file://component_keyring_encrypted_file"
}
EOF 

cat <<EOF > /lib64/mysql/plugin/component_keyring_encrypted_file.cnf
{
  "path": "/var/lib/mysql-keyring/component_keyring_encrypted_file",
  "password": "=SecretPassword=",
  "read_only": false
}
EOF

systemctl start mysqld;

# SELECT * FROM performance_schema.keyring_component_status;
