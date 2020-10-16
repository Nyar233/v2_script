#!/bin/bash
v2fly_folder="/usr/local/bin/v2ray"
os=`awk -F= '/^NAME/{print $2}' /etc/os-release`
# 起始

cat << EOF
********please enter your choise:(1-6)****
(1) installv2ray.
(2) installCertbot.
(6) Exit Menu.
EOF


main(){
read -p "Selected:" selected_by_user
case $selected_by_user in
	1)
		echo "install v2ray..."
		v2_install
		;;
		2)
		echo "install certbot..."
		certbot_install
		;;
		6)
		echo "exit."
		exit
		;;
		*)
		echo "error option."
		echo "exit."
		exit
esac
}


# install v2ray
v2_install(){
    if [ -f "$filename"  ]; then
        echo "v2ray had installed."
    else
        echo "v2ray is install..."
        bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
        echo "v2ray has installed."
    fi
}

certbot_install(){
    
	if [ "$os"=="CentOS Linux" ]; then
		echo "install epel-release..."
		yum install epel-release -y 
		echo "install certbot"
		yum install certbot -y
		echo "done."
	elif [ "$os"=="Debian GNU/Linux" ]; then
		apt install certbot -y
		echo "done"
	fi
}





