# Tollgate Module - relay (go)

This Tollgate module is a very minimal Nostr relay implementation intended to run on every tollgate.

# Compile for ATH79 (GL-AR300 NOR)

```bash
cd ./src
env GOOS=linux GOARCH=mips GOMIPS=softfloat go build -o relay -trimpath -ldflags="-s -w"

# Hint: copy to connected router 
scp relay root@119.201.26.1:/tmp/relay
```