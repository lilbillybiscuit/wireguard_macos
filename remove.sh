echo "# Removing"
sudo launchctl unload -w /Library/LaunchDaemons/com.wireguard.server.plist
sudo launchctl disable -w /Library/LaunchDaemons/com.wireguard.server.plist

sudo rm /Library/LaunchDaemons/com.wireguard.server.plist
yes | brew remove wireguard-tools qrencode

rm -rf /usr/local/etc/wireguard

echo "# Removed"
