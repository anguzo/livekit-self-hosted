# Caddy with Layer4 and acme-dns

This directory contains Docker build script for Caddy v2.6.4 with layer4 and [acme-dns](https://github.com/caddy-dns/acmedns) support.

LiveKit can utilize Caddy's certificate management automation using acme-dns when deployed.

You are welcome to use your own Caddy build or customize this one.
Livekit requires Caddy to be compiled with [Layer4](https://github.com/mholt/caddy-l4) and [YAML](https://github.com/abiosoft/caddy-yaml) modules.
