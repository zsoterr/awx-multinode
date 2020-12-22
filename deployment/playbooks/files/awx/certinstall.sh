#!/bin/bash
ln -s "/etc/openldap/certs/Internal_Root_CA_1.pem" "/etc/openldap/certs/$(openssl x509 -hash -noout -in /etc/openldap/certs/Internal_Root_CA_1.pem -inform pem).0"
