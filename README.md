# livekit-self-hosted

There are several examples available for launching your own LiveKit server:

* [User created guides for FoundryVTT](https://github.com/bekriebel/fvtt-module-avclient-livekit/wiki)
* [LiveKit Getting Started](https://docs.livekit.io/guides/getting-started)
* [Deploy to a VM (GCP/AWS/Digital Ocean/Linode/Vultr/etc)](https://docs.livekit.io/deploy/vm)
* [Deploy to Kubernetes](https://docs.livekit.io/deploy/kubernetes)

This example focuses on launching self-hosted LiveKit server not accessible from the Internet while also providing proper HTTPS, WSS using  [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) propagation using awesome [acme-dns](https://github.com/joohoi/acme-dns) server.

## Background

The contents of this repository were generated using:
```
docker run --rm -it -v$PWD:/output livekit/generate
```
And modified to account for an on-premise set-up using:
* owned domain name
* [acmedns Caddy plugin](https://github.com/caddy-dns/acmedns)
* local DNS server 

to provide proper HTTPS/WSS addresses in your local network.

## Usage

1. **Acquire a domain name** for which you are be able to create CNAME records.
2. **Set up acme-dns**: 
    - For testing purposes, you can use the public server at https://auth.acme-dns.io, refer to [acmedns Caddy plugin documentation](https://github.com/caddy-dns/acmedns). 
    - For a production set-up a self-hosted instance of acme-dns  is encouraged, refer to [ACME-DNS documentation](https://github.com/joohoi/acme-dns#self-hosted) or a [guide by Vykintas Baltrušaitis](https://github.com/caddy-dns/acmedns/tree/acmedns-hosting/acmedns-hosting).
3. **Replace `myhost.com`** in all files with you domain name.
4. **Point subdomains using local DNS** to the IP address of your server.
5. **Replace Livekit API key and secret** in all files with your custom one.
6. **Use either `init_script.sh` or `cloud_init.ubuntu.yaml`** for automated set-up of LiveKit server. 
    > **Note**: Make sure that the contens of files that will be created by the `init_script.sh` or `cloud_init.ubuntu.yaml` correspond to the ones you modified - `caddy.yaml`, `acme-dns-cred.json`, `livekit.yaml`, `ingress.yaml`.

    > **Note**: For a set-up in a VirtualBox you can refer to these materials: [#1](https://dustinspecker.com/posts/ubuntu-autoinstallation-virtualbox/), [#2](https://askubuntu.com/questions/1344472/combine-cloud-init-autoinstall-with-other-cloud-init-modules).
7. **Develop your own LiveKit frontend** and add it to the setup. For example: 
    1. Fork [LiveKit Meet](https://github.com/livekit-examples/meet).
    2. Add a corresponding [Dockerfile](https://github.com/vercel/next.js/blob/canary/examples/with-docker/Dockerfile) to it.
        > **Note**: don't forget to copy env.local with the right API key and secret ```COPY --from=builder /app/.env.local ./.env.local```
    3. Deploy to Docker Hub.
    4. Modify `docker-compose.yaml` and `caddy.yaml` to include your frontend.

## TODO

- Test out WHIP and URL ingress.

## Known issues and solutions

- **Caddy: DNS-01 challenge takes long.** No solution yet, it might take really long sometimes.

- **Redis: "WARNING Memory overcommit must be enabled!"** [Solution](https://github.com/nextcloud/all-in-one/discussions/1731)

- **Ingress: "UDP receive buffer is too small for a production set-up."** [Solution](https://medium.com/@CameronSparr/increase-os-udp-buffers-to-improve-performance-51d167bb1360)