# livekit-self-hosted

There are several examples available for launching your own LiveKit server:

* [User created guides for FoundryVTT](https://github.com/bekriebel/fvtt-module-avclient-livekit/wiki)
* [LiveKit Getting Started](https://docs.livekit.io/guides/getting-started)
* [Deploy to a VM (GCP/AWS/Digital Ocean/Linode/Vultr/etc)](https://docs.livekit.io/deploy/vm)
* [Deploy to Kubernetes](https://docs.livekit.io/deploy/kubernetes)

This example focuses on launching self-hosted LiveKit server not accessible from the Internet while also providing proper HTTPS, WSS using  [DNS-01 challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) propagation using awesome [acme-dns](https://github.com/joohoi/acme-dns) server.