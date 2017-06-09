# Quick install
#cd /tmp
#wget --quiet --no-check-certificate -O pia.shhttps://raw.githubusercontent.com/Facerafter/UsefulScripts/master/FreeNAS/pia.sh
#chmod +x pia.sh
#./pia.sh
#!/bin/tcsh

# Grab user information.
echo "PrivateInternetAccess OpenVPN Setup:"
echo -n "User: "
set user = $<
echo -n "Pass: "
set pass = $<

# Some directories. 
set openVPNPort = /usr/ports/security/openvpn
set openVPNDir = /usr/local/etc/openvpn

# Update & upgrade pkgs
/usr/sbin/pkg update -f
/usr/sbin/pkg upgrade -y
# Fetch & extract ports
/usr/sbin/portsnap fetch
/usr/sbin/portsnap extract
# Go to the OpenVPN directory.
cd $openVPNPort
# Change this to a 1 == 1 to use the dialog box to set the options
if (0 == 1) then
	/usr/bin/make config-recursive
else
	/bin/mkdir -p /var/db/ports/security_openvpn/
	echo "# This file is auto-generated by 'make config'." > /var/db/ports/security_openvpn/options
	echo "# Options for openvpn-2.3.6_1" >> /var/db/ports/security_openvpn/options
	echo "_OPTIONS_READ=openvpn-2.3.6_1" >> /var/db/ports/security_openvpn/options
	echo "_FILE_COMPLETE_OPTIONS_LIST=DOCS EASYRSA EXAMPLES PKCS11 PW_SAVE OPENSSL POLARSSL" >> /var/db/ports/security_openvpn/options
	echo "OPTIONS_FILE_UNSET+=DOCS" >> /var/db/ports/security_openvpn/options
	echo "OPTIONS_FILE_SET+=EASYRSA" >> /var/db/ports/security_openvpn/options
	echo "OPTIONS_FILE_UNSET+=EXAMPLES" >> /var/db/ports/security_openvpn/options
	echo "OPTIONS_FILE_UNSET+=PKCS11" >> /var/db/ports/security_openvpn/options
	echo "OPTIONS_FILE_SET+=PW_SAVE" >> /var/db/ports/security_openvpn/options
	echo "OPTIONS_FILE_SET+=OPENSSL" >> /var/db/ports/security_openvpn/options
	echo "OPTIONS_FILE_UNSET+=POLARSSL" >> /var/db/ports/security_openvpn/options

	/bin/mkdir -p /var/db/ports/archivers_lzo2
	echo "# This file is auto-generated by 'make config'" > /var/db/ports/archivers_lzo2/options
	echo "# Options for lzo2-2.08_1" >> /var/db/ports/archivers_lzo2/options
	echo "_OPTIONS_READ=lzo2-2.08_1" >> /var/db/ports/archivers_lzo2/options
	echo "_FILE_COMPLETE_OPTIONS_LIST=DOCS EXAMPLES" >> /var/db/ports/archivers_lzo2/options
	echo "OPTIONS_FILE_UNSET+=DOCS" >> /var/db/ports/archivers_lzo2/options
	echo "OPTIONS_FILE_UNSET+=EXAMPLES" >> /var/db/ports/archivers_lzo2/options
endif
# Install & Clean OpenVPN
/usr/bin/make install
/usr/bin/make clean

# Make & Change to the OpenVPN Config Directory
/bin/mkdir -p $openVPNDir
cd $openVPNDir
# Grab PIA's OpenVPN settings
if ( -x "/usr/local/bin/wget" ) then
	/usr/local/bin/wget https://www.privateinternetaccess.com/openvpn/openvpn.zip --no-check-certificate
else if ( -x "/usr/local/bin/curl" ) then
	/usr/local/bin/curl -OLk https://www.privateinternetaccess.com/openvpn/openvpn.zip
else
	return 0
endif

# Unzip & Delete the file.
/usr/bin/unzip -q /usr/local/etc/openvpn/openvpn.zip
/bin/rm -f /usr/local/etc/openvpn/openvpn.zip

# For each of the ovpn settings.
foreach ovpn (*.ovpn)
	# First add to read in the user's information from pass.txt
	echo "auth-user-pass $openVPNDir/pass.txt" >> "$ovpn"
	# Add the full paths to avoid ambiguity.
	sed -i "" "s/crl\.pem/\/usr\/local\/etc\/openvpn\/crl.pem/g" "$ovpn"
	sed -i "" "s/ca\.crt/\/usr\/local\/etc\/openvpn\/ca.crt/g" "$ovpn"
	# Finally replace the spaces in the filename with underscores.
	set ovpn2 = `echo $ovpn | sed "s/ /_/g"`
	mv "$ovpn" "$ovpn2"
end
# Add username and pass to the pass.txt
echo $user > "$openVPNDir/pass.txt"
echo -n $pass >> "$openVPNDir/pass.txt"

# Enable openvpn in rc.conf
echo 'openvpn_enable="YES"' >> /etc/rc.conf
echo 'openvpn_configfile="/usr/local/etc/openvpn/Switzerland.ovpn"' >> /etc/rc.conf

# Start OpenVPN
/usr/sbin/service openvpn start
echo "OpenVPN will be started in 10 seconds"