# Install and use Wireguard on macOS
Scripts automate the installation and use of Wireguard on macOS.
This is a fork from pprometey for macOS.
Concept from https://barrowclift.me/post/wireguard-server-on-macos


## How to use

### Installation
```
git clone https://github.com/lilbillybiscuit/wireguard_macos.git
cd wireguard_macos
sudo ./initial.sh
```

The `initial.sh` script removes the previous Wireguard installation (if any) using the `remove.sh` script. It then installs and configures the Wireguard service using the `install.sh` script. And then creates a client using the `add-client.sh` script.

### Add new customer
`add-client.sh` - Script to add a new VPN client. As a result of the execution, it creates a configuration file ($CLIENT_NAME.conf) on the path ./clients/$CLIENT_NAME/, displays a QR code with the configuration.

```
sudo ./add-client.sh
#OR
sudo ./add-client.sh $CLIENT_NAME
```

### Reset customers
`reset.sh` - script that removes information about clients. And stopping the VPN server Winguard
```
sudo ./reset.sh
```

### Delete Wireguard
```
sudo ./remove.sh
```
## Authors
- Alexey Chernyavskiy
- lilbillybiscuit (changed to macOS)
