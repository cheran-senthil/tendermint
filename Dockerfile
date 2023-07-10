# stage 1 Generate Tendermint Binary
FROM golang:1.18-alpine as builder
RUN apk update && \
    apk upgrade && \
    apk --no-cache add make


WORKDIR /go

RUN make build-linux

# stage 2
FROM golang:1.18-alpine

LABEL maintainer="hello@tor.us"

ENV TMHOME=/.torus/tendermint

# OS environment setup
# Set user right away for determinism, create directory for persistence and give our user ownership
# jq and curl used for extracting `pub_key` from private validator while
# deploying tendermint with Kubernetes. It is nice to have bash so the users
# could execute bash commands.
RUN apk update && \
    apk upgrade && \
    apk --no-cache add curl jq bash && \
    addgroup tmuser && \
    adduser -S -G tmuser tmuser -h "$TMHOME"

# Run the container with tmuser by default. (UID=100, GID=1000)
USER tmuser

WORKDIR $TMHOME

# p2p, rpc and prometheus port
EXPOSE 26656 26657 26660

STOPSIGNAL SIGTERM

COPY --from=builder /tendermint/build/tendermint /usr/bin/tendermint


ENV CHAIN_ID=main-chain-BLUBLU

COPY ./docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["node" "--proxy-app=tcp://localhost:26655"]


