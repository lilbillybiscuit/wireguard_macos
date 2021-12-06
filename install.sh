#!/bin/zsh

brew install wireguard-tools
brew install qrencode 

cd /usr/local/etc/wireguard

umask 077

SERVER_PRIVKEY=$( wg genkey )
SERVER_PUBKEY=$( echo $SERVER_PRIVKEY | wg pubkey )

echo $SERVER_PUBKEY > ./server_public.key
echo $SERVER_PRIVKEY > ./server_private.key

read -p "Enter the endpoint (external ip and port) in format [ipv4:port] (e.g. 4.3.2.1:54321):" ENDPOINT
if [ -z $ENDPOINT ]
then
echo "[#]Empty endpoint. Exit"
exit 1;
fi
echo $ENDPOINT > ./endpoint.var

if [ -z "$1" ]
  then 
    read -p "Enter the server address in the VPN subnet (CIDR format), [ENTER] set to default: 10.50.0.1: " SERVER_IP
    if [ -z $SERVER_IP ]
      then SERVER_IP="10.50.0.1"
    fi
  else SERVER_IP=$1
fi

echo $SERVER_IP | grep -o -E '([0-9]+\.){3}' > ./vpn_subnet.var

read -p "Enter the ip address of the server DNS (CIDR format), [ENTER] set to default: 1.1.1.1): " DNS
if [ -z $DNS ]
then DNS="1.1.1.1"
fi
echo $DNS > ./dns.var

echo 1 > ./last_used_ip.var

read -p "Enter the name of the WAN network interface ([ENTER] set to default: en0): " WAN_INTERFACE_NAME
if [ -z $WAN_INTERFACE_NAME ]
then
  WAN_INTERFACE_NAME="en0"
fi

echo $WAN_INTERFACE_NAME > ./wan_interface_name.var

cat ./endpoint.var | sed -e "s/:/ /" | while read SERVER_EXTERNAL_IP SERVER_EXTERNAL_PORT
do
cat > ./wg0.conf.def << EOF
[Interface]
Address = $SERVER_IP
SaveConfig = false
PrivateKey = $SERVER_PRIVKEY
ListenPort = $SERVER_EXTERNAL_PORT
PostUp = /usr/sbin/sysctl -w net.inet.ip.forwarding=1
PostUp = /usr/sbin/sysctl -w net.inet6.ip6.forwarding=1
PostUp = /usr/local/etc/wireguard/postup.sh
PostDown = /usr/local/etc/wireguard/postdown.sh

EOF
done

cat > /usr/local/etc/wireguard/postup.sh << EOF
#!/bin/sh
mkdir -p /usr/local/var/run/wireguard
chmod 700 /usr/local/var/run/wireguard

echo 'nat on en0 from $SERVER_IP to any -> (en0)' | \
    pfctl -a com.apple/wireguard -Ef - 2>&1 | \
    grep 'Token' | \
    sed 's%Token : \(.*\)%\1%' > /usr/local/var/run/wireguard/pf_wireguard_token.txt

EOF

cat > /usr/local/etc/wireguard/postdown.sh << EOF
#!/bin/sh
TOKEN=`cat /usr/local/var/run/wireguard/pf_wireguard_token.txt`
pfctl -X ${TOKEN} || exit 1
rm -f /usr/local/var/run/wireguard/pf_wireguard_token.txt

EOF

sudo chmod +x /usr/local/etc/wireguard/postdown.sh
sudo chmod +x /usr/local/etc/wireguard/postup.sh

cp -f ./wg0.conf.def ./wg0.conf

cat > /Library/LaunchDaemons/com.wireguard.server.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.wireguard.server</string>
        <key>ProgramArguments</key>
        <array>
            <!-- NOTE: If on Apple Silicon, this path should be
                 /opt/homebrew/bin/wg-quick, instead -->
            <string>/usr/local/bin/wg-quick</string>
            <string>up</string>
            <string>/usr/local/etc/wireguard/coordinates.conf</string>
        </array>
        <key>KeepAlive</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>/usr/local/var/log/wireguard.err</string>
        <key>EnvironmentVariables</key>
        <dict>
            <key>PATH</key>
            <string>/usr/local/sbin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
        </dict>
    </dict>
</plist>
EOF

sudo launchctl enable system/com.wireguard.server
sudo launchctl bootstrap system /Library/LaunchDaemons/com.wireguard.server.plist

echo "Setup complete! Please restart your Mac for the server to start"
