# wireguard-helper

This is a bash script written for help to run VPN via wireguard.

## Requements
* Bash
* Wireguard

## How to use:
First: you should create dir `$ mkdir /etc/wireguard` \
Then: Generate private and public keys for your server \
You can do this with these commands:
```
$ cd /etc/wireguard
$ umask 077
$ wg genkey > privatekey
$ wg pubkey < privatekey > publickey
```

Okay, now open `wg.sh` via nano or vim and edit `$HOST` variable.
Assign your server hostname or ip to this.

That's all. Now you can `$ ./wg.sh up` \
To add a client type `$ ./wg.sh add %username% 10.10.0.*`, where %username% - client's name and * - last digit in ip \
Script will create %username%.conf for your client \
Clients are saved in /etc/wireguard/clients.conf \
