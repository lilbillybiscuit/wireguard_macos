echo "# Reseting..."

cd /usr/local/etc/wireguard

# Delete the folder with customer data
rm -rf ./clients

# Zero IP counter
echo "1" > last_used_ip.var

# Resetting the server configuration template to default settings
cp -f wg0.conf.def wg0.conf

sudo launchctl unload -w /Library/LaunchDaemons/com.wireguard.server.plist

echo "# Reseted"
