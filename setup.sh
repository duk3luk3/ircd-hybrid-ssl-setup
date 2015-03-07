set -e

echo "Installing OpenSSL, STunnel, Ircd-Hybrid packages"
apt-get -qy install openssl stunnel ircd-hybrid

echo "Checking SSL certs and keys"

if [ -f "key/ircd.key" ]
then
	echo "Using existing server key"
else
	echo "Checking for CA"
	if [ -f "ca/ca-root.pem" ]
	then
		echo "Using existing ca and generating server key and CSR"
		echo "Generating new server key:"
		openssl genrsa -out key/ircd.key 2048
		echo "Generating new server certificate request, please fill in:"
		openssl req -new -key key/ircd.key -out key/ircd-cert.csr -sha512
		if [ -f "ca/ca.key" ]
		then
			echo "Found a CA key, signing certificate now"
			openssl x509 -req -in key/ircd-cert.csr -CA ca/ca-root.pem -CAkey ca/ca.key -CAcreateserial -out key/ircd-cert.pem -days 365 -sha512
		else
			echo "Please get key/ircd-cert.csr signed and place signed certificate as key/ircd-cert.pem"
			echo "Then rerun this script"
			exit 0
		fi
	else
		echo "Generating new ca key:"
		openssl genrsa -aes256 -out ca/ca.key 2048
		echo "Generating new ca certificate, please fill in:"
		openssl req -x509 -new -nodes -extensions v3_ca -key ca/ca.key -days 1024 -out ca/ca-root.pem -sha512
		echo "Generating new server key:"
		openssl genrsa -out key/ircd.key 2048
		echo "Generating new server certificate, please fill in:"
		openssl req -new -key key/ircd.key -out key/ircd-cert.csr -sha512
		openssl x509 -req -in key/ircd-cert.csr -CA ca/ca-root.pem -CAkey ca/ca.key -CAcreateserial -out key/ircd-cert.pem -days 365 -sha512
	fi
fi

echo "Setting up ircd-hybrid"
cp ircd.conf /etc/ircd.conf

service ircd-hybrid restart

echo "Setting up STunnel"
cp key/ircd.key /etc/stunnel/
cp key/ircd-cert.pem /etc/stunnel/
cp stunnel.conf /etc/stunnel/ircd.conf
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/stunnel4

service stunnel4 restart
