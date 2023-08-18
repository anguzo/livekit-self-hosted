FROM caddy:2.6.4-builder AS builder

RUN xcaddy build \
  --with github.com/abiosoft/caddy-yaml \
  --with github.com/mholt/caddy-l4@38bd801 \
  --with github.com/caddy-dns/acmedns@main 

FROM caddy:2.6.4

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Run the binary.
ENTRYPOINT ["/usr/bin/caddy"]