#!/bin/bash
v2fly_folder="/usr/local/bin/v2ray"
# os=`awk -F= '/^ID=/{print $2}' /etc/os-release`
# 起始
releasever=`awk -F= '/^VERSION_ID/{print $2}' /etc/os-release`
basearch="x86_64"
VERSION_CODENAME_script=`awk -F= '/^VERSION_CODENAME=/{print $2}' /etc/os-release`
cat << EOF
********please enter your choise:(1-6)****
recommend: 1->2->3->4->5
(1) install v2ray.
(2) install Certbot.
(3) configure Certbot.
(4) install nginx.
(5) configure tls for v2ray
(6) install and configure all
(7) Exit Menu.
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
        echo "install and configure all"
        install_all
        echo "done"
    7)
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
    read -p "input your UUID: " UUID_v2
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

cat > /usr/local/etc/v2ray/config.json <<EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID_v2", // 填写你的 UUID
                        "flow": "xtls-rprx-direct",
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 80 // 或者回落到其它也防探测的代理
                    },
                    {
                        "path": "/vlws", // 必须换成自定义的 PATH
                        "dest": 1234,
                        "xver": 1
                    },
                    {
                        "path": "/vmtcp", // 必须换成自定义的 PATH
                        "dest": 2345,
                        "xver": 1
                    },
                    {
                        "path": "/vmws", // 必须换成自定义的 PATH
                        "dest": 3456,
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "xtls",
                "xtlsSettings": {
                    "alpn": [
                        "http/1.1"
                    ],
                    "certificates": [
                        {
                            "certificateFile": "/etc/ssl/v2ray/fullchain.pem", // 换成你的证书，绝对路径
                            "keyFile": "/etc/ssl/v2ray/privkey.pem" // 换成你的私钥，绝对路径
                        }
                    ]
                }
            }
        },
        {
            "port": 1234,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID_v2", // 填写你的 UUID
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true, // 提醒：若你用 Nginx/Caddy 等反代 WS，需要删掉这行
                    "path": "/vlws" // 必须换成自定义的 PATH，需要和分流的一致
                }
            }
        },
        {
            "port": 2345,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID_v2", // 填写你的 UUID
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none",
                "tcpSettings": {
                    "acceptProxyProtocol": true,
                    "header": {
                        "type": "http",
                        "request": {
                            "path": [
                                "/vmtcp" // 必须换成自定义的 PATH，需要和分流的一致
                            ]
                        }
                    }
                }
            }
        },
        {
            "port": 3456,
            "listen": "127.0.0.1",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "$UUID_v2", // 填写你的 UUID
                        "level": 0,
                        "email": "love@v2fly.org"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "acceptProxyProtocol": true, // 提醒：若你用 Nginx/Caddy 等反代 WS，需要删掉这行
                    "path": "/vmws" // 必须换成自定义的 PATH，需要和分流的一致
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF
systemctl restart v2ray

echo "done."
echo '"certificateFile": "/etc/ssl/v2ray/fullchain.pem"'
echo '"keyFile": "/etc/ssl/v2ray/privkey.pem"'
echo '---------------------------------------------'
echo "do it by yourself:"
echo "systemctl edit v2ray.service"
echo "[Service]"
echo "User=v2ray"
echo "systemctl restart v2ray"

echo '--------------information--------------------'
echo 'address:$domain_tls'
echo 'port:443'
echo 'UUID:$UUID_v2'
echo 'flow:xtls-rprx-direct'
echo 'path:
vless+tcp /
vless+ws /vlws
vmess+ws /vmws
vmess+tcp /vmtcp
'


}




# install v2ray
v2_install(){
    if [ -f "$filename"  ]; then
        echo "v2ray had installed."

    else
        echo "v2ray is install..."
        bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
        echo "v2ray has installed."
        touch $HOME/v2_source.file
        echo "[Service]" >> $HOME/v2_source.file
        echo "User=v2ray" >> $HOME/v2_source.file
        env SYSTEMD_EDITOR="mv $HOME/source.file" systemctl edit v2ray
        systemctl restart v2ray
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
    echo '15 2 * */2 * certbot renew --pre-hook "service nginx stop" --post-hook "service nginx start"' > /opt/certbot/certbot-auto-renew-cron
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
        echo 'deb https://nginx.org/packages/debian/ $VERSION_CODENAME_script nginx' >> /etc/apt/sources.list
        echo 'deb-src https://nginx.org/packages/debian/ $VERSION_CODENAME_script nginx' >> /etc/apt/sources.list
        apt update -y
        apt install nginx -y
	
 #   fi
}

# 整合
install_all() {
    apt update -y
    apt upgrade -y
    v2_install
    install_nginx
    certbot_install
    config_certbot
    config_tls
}



main
