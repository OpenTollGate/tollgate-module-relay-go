# Tollgate Module - relay (go)

This Tollgate module is a very minimal Nostr relay implementation intended to run on every tollgate.

# Compile for ATH79 (GL-AR300 NOR)

```bash
cd ./src
env GOOS=linux GOARCH=mips GOMIPS=softfloat go build -o relay -trimpath -ldflags="-s -w"

# Hint: copy to connected router 
scp -O relay root@192.168.8.1:/tmp/relay
```

# Compile for GL-MT3000

## Build

```bash
cd ./src
env GOOS=linux GOARCH=arm go build -o relay -trimpath -ldflags="-s -w"

# Hint: copy to connected router 
scp -O relay root@192.168.X.X:/tmp/relay # X.X == Router IP
```

## Required Firewall rules

Add to `/etc/config/firewall`:
```uci
config rule
	option name 'Allow-Relay-In'
	option src 'lan'
	option proto 'tcp'
	option dest_port 'XXXX' # Relay port
	option target 'ACCEPT'

config redirect
	option name 'TollGate - Nostr Relay DNAT'
	option src 'lan'
	option dest 'lan'
	option proto 'tcp'
	option src_dip '192.168.21.21'
	option src_dport '2121'
	option dest_ip '192.168.X.X' # Router IP
	option dest_port 'XXXX' # Relay port
	option target 'DNAT'

config redirect
        option name 'TollGate - Nostr Relay DNAT port'
        option src 'lan'
        option dest 'lan'
        option proto 'tcp'
        option src_dip '192.168.X.X' # Router IP
        option src_dport '2121'
        option dest_ip '192.168.X.X' # Router IP
        option dest_port 'XXXX' # Relay port
        option target 'DNAT'
```

Run `service firewall restart` to make changes go into effect.

## OpenNDS rules
**Prerequisite: OpenNDS is installed**

To allow unauthenticated clients to reach the relay, we need to explicitly allow access.

Add to `/etc/config/opennds` under `config opennds`:
```uci
config opennds
    list users_to_router 'allow tcp port XXXX' # Relay port
    list users_to_router 'allow tcp port 2121'
    list preauthenticated_users 'allow tcp port 2121 to 192.168.21.21'
```

Run `service opennds restart` to make changes go into effect.
