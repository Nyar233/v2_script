#!/bin/bash
v2fly_folder="/usr/local/bin/v2ray"
# os=`awk -F= '/^ID=/{print $2}' /etc/os-release`
# 起始
releasever=`awk -F= '/^VERSION_ID/{print $2}' /etc/os-release`
basearch="x86_64"

cat << EOF
********please enter your choise:(1-6)****
(1) install v2ray.
(2) install Certbot.
(3) config Certbot.
(4) install nginx.
(5) config tls for v2ray
(6) Exit Menu.
EOF


main(){
read -p "Selected:" selected_by_user
case $selected_by_user in
    1)
        echo "install v2ray..."
		v2_install
		echo "install v2ray: done."
        ;;
    2)
	    echo "install certbot..."
	    certbot_install
        echo "install certbot: done."
	;;
    3)
        echo "config Certbot..."
        config_certbot
        echo "config Certbot: done."
        ;;
    4)
        echo "install nginx..."
        install_nginx
        echo "install nginx: done."
        ;;
    5)
        echo "config tls"
        config_tls
        echo "config tls: done"
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


config_tls(){
    read -p "input your domain: " domain_tls
    useradd -s /usr/sbin/nologin v2ray
    install -d -o v2ray -g v2ray /etc/ssl/v2ray/
    install -m 644 -o v2ray -g v2ray /etc/letsencrypt/live/$domain_tls/fullchain.pem -t /etc/ssl/v2ray/
    install -m 600 -o v2ray -g v2ray /etc/letsencrypt/live/$domain_tls/privkey.pem -t /etc/ssl/v2ray/
cat > /etc/letsencrypt/renewal-hooks/deploy/v2ray.sh<<EOF
#!/bin/bash
V2RAY_DOMAIN="$domain_tls"
if [[ "$RENEWED_LINEAGE" == "/etc/letsencrypt/live/$V2RAY_DOMAIN"  ]]; then
     install -m 644 -o v2ray -g v2ray "/etc/letsencrypt/live/$V2RAY_DOMAIN/fullchain.pem" -t /etc/ssl/v2ray/
     install -m 600 -o v2ray -g v2ray "/etc/letsencrypt/live/$V2RAY_DOMAIN/privkey.pem" -t /etc/ssl/v2ray/
     sleep "$((RANDOM % 2048))"
     systemctl restart v2ray.service
fi
EOF

chmod +x /etc/letsencrypt/renewal-hooks/deploy/v2ray.sh

echo "done."
echo '"certificateFile": "/etc/ssl/v2ray/fullchain.pem"'
echo '"keyFile": "/etc/ssl/v2ray/privkey.pem"'
echo "systemctl edit v2ray.service"
echo "[Service]"
echo "User=v2ray"
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
	#if [ "$os"=="centos" ]; then
	#	echo "install epel-release..."
	#	yum install epel-release -y
	#	echo "install certbot"
	#	yum install certbot -y
	#	echo "done."
	#elif [ "$os"=="debian" ]; then
		apt install certbot -y
		echo "done"
	#fi
	}


config_certbot(){
    read -p "Please input your domain: " domain_user
    systemctl stop nginx
    systemctl stop v2ray
    certbot certonly --standalone -d $domain_user
    echo "done."
    systemctl start nginx
    systemctl start v2ray
    mkdir /opt/certbot
    touch /opt/certbot/certbot-auto-renew-cron
    echo '15 2 * */2 * certbot renew --pre-hook "service nginx stop" --post-hook "service nginx start"' > /opt/certbot-auto-renew-cron
    crontab /opt/certbot/certbot-auto-renew-cron
    echo "done"
    }

install_nginx(){
   # if [ "$os"=="centos"  ]; then
#cat>"/etc/yum.repos.d/nginx.repo"<<EOF
#[nginx]
#name=nginx repo
#baseurl=https://nginx.org/packages/centos/$releasever/$basearch/
#gpgcheck=0
#enabled=1
#EOF
#        yum update -y
 #       yum install nginx -y
#    elif [ "$os"=="debian"  ]; then
        echo 'deb https://nginx.org/packages/debian/ buster nginx' >> /etc/apt/sources.list
        echo 'deb-src https://nginx.org/packages/debian/ buster nginx' >> /etc/apt/sources.list
        apt update -y
        apt install nginx -y
	
 #   fi
}



main
