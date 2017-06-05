#!/bin/bash

rpm -qa | grep openssl > /dev/null

if [ $? -ne 0 ];then
	echo "don't have openssl command..."
	exit 2
fi

modify_cnf(){
	sed -i '/^countryName_default/s/XX/CN/g' /etc/pki/tls/openssl.cnf
	sed -i '/^#stateOrProvinceName_default/s/#//' /etc/pki/tls/openssl.cnf
	sed -i '/stateOrProvinceName_default/s/Default Province/BeiJing/g' /etc/pki/tls/openssl.cnf
	sed -i '/Default City/s/Default City/BeiJing/g' /etc/pki/tls/openssl.cnf
	sed -i '/Default Company Ltd/s/Default Company Ltd/CA/g' /etc/pki/tls/openssl.cnf
	sed -i '/#organizationalUnitName/a organizationalUnitName_default=IT ' /etc/pki/tls/openssl.cnf
}


creat_CA(){
	cd /etc/pki/CA/
	if test ! -d private;then
		mkdir private
	fi
	
	if test ! -d certs;then
		mkdir certs
	fi
	
	if test ! -d crl;then
		mkdir crl
	fi
	
	
	if test ! -d newcerts;then
		mkdir newcerts
	fi

	(umask 077;openssl genrsa -out private/cakey.pem 2048)
	openssl req -new -x509 -key private/cakey.pem -out cacert.pem -days 365
	touch index.txt
	echo 01 > serial
}

client_CA(){
	(umask 077;openssl genrsa 1024 > $1.key)
	openssl req -new -key httpd.key -out $1.csr
}

sign_csr(){
	openssl ca -in $1.csr -out $1.crt -days 365
}

menu(){
	cat <<-EOF
	##################################################
	1.modify /etc/pki/tls/openssl.cnf
	2.creat CA organization
	3.creat Certificate signing request of client
	4.CA Sign the certificate
	##################################################
	EOF
}

client_menu(){
	cat <<-END
	################################################	
	You must reach the location where the key needs 
	to be stored, otherwise it will be stored in the 
	current directory
	
	If you want to generate httpd.csr you should enter httpd
	example:

		input your name of Certificate signing request :httpd		

	you will get a file named of httpd.csr
	################################################
	END
}

CA_menu(){
	cat <<-END
	##############################################
	If you have a certificate signing request with 
	the name httpd.csr, you should enter httpd
	##############################################
	END
}


menu



read -p "press the num,then press enter:" num
case $num in 
	1)
	modify_cnf
	;;
	2)
	creat_CA
	;;
	3)
	clear
	client_menu
	read -p "input your name of Certificate signing request :" name
	client_CA $name
	;;
	4)
	clear
	CA_menu
	read -p "input your name of Certificate signing request:" csr
	sign_csr $csr
	;;
	*)
	exit 3
	;;
esac
