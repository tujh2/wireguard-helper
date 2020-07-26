#!/bin/bash
HOST="git.tujh.xyz"
WG="wg0"
ETH="ens2"
BASE_IP="10.10.0.1"
PORT="1194"
PRIVATE_KEY="/etc/wireguard/privatekey"
PUBLIC_KEY="/etc/wireguard/publickey"
PEERS_PATH="/etc/wireguard/clients.conf"
WG_OUT=$(wg)

confExample="
[Interface]
PrivateKey = %s
Address = %s/32
DNS = 1.1.1.1

[Peer]
PublicKey = $(cat $PUBLIC_KEY)
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $HOST:$PORT
"

function up {
	echo "Trying to up wireguard VPN"
	ip link add dev $WG type wireguard
	ip address add dev $WG $BASE_IP/24
	wg set $WG listen-port $PORT private-key $PRIVATE_KEY 
	
	while IFS=\  read -r name peer addr
	do
		echo Adding client $name \($peer\) with $addr
		wg set $WG peer $peer allowed-ips $addr/32
	done < "$PEERS_PATH"

	iptables -A FORWARD -i $WG -j ACCEPT; iptables -t nat -A POSTROUTING -o $ETH -j MASQUERADE;
	ip link set up dev $WG
}

function down {
	echo "Trying to down wireguard VPN"
	ip link delete dev $WG
	iptables -D FORWARD -i $WG -j ACCEPT; iptables -t nat -D POSTROUTING -o $ETH -j MASQUERADE;
}

function addUser {
	if [[ $2 =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		echo "Valid IP. Checking if available..."
	else
	      	echo "Error. Invalid IP"
		return
	fi
	while IFS=\  read -r name peer addr
	do
		if [[ "$1" == "$name" ]]; then
			echo "Error. User $1 exists"
			return
		fi
		if [[ "$2" == "$addr" ]]; then
			echo "Error. IP $2 exists"
			return
		fi
	done < "$PEERS_PATH"
	echo "Generating new user named" $1

	privkey=$(wg genkey)
	pubkey=$(wg pubkey < <(echo $privkey))
	
	if [ -z "$WG_OUT" ]
	then
		echo "Warning: WG is down now"
	else
		echo Adding client $1 \($pubkey\) with $2
		wg set $WG peer $pubkey allowed-ips $2
	fi

	echo $1 $pubkey $2 >> $PEERS_PATH
	printf "$confExample" "$privkey" $2 > $1.conf
}

function listUsers {
	while IFS=\  read -r name peer addr
	do
		echo $name with $addr
	done < "$PEERS_PATH"
}

if [[ "$1" == "up" ]]; then
	up
elif [[ "$1" == "down" ]]; then
	down
elif [[ "$1" == "add" ]]; then
	addUser $2 $3
elif [[ "$1" == "list" ]]; then
	listUsers
fi

