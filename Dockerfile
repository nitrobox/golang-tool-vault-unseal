# syntax = docker/dockerfile:1.4

# build image
FROM golang:alpine as build
WORKDIR /build

RUN apk add --no-cache make ca-certificates busybox-static
COPY go.sum go.mod Makefile /build/
RUN \
	--mount=type=cache,target=/root/.cache \
	--mount=type=cache,target=/go \
	make go-fetch

COPY . /build/
RUN \
	--mount=type=cache,target=/root/.cache \
	--mount=type=cache,target=/go \
	make

# runtime image
FROM scratch
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /bin/busybox /bin/busybox
RUN ["/bin/busybox", "--install", "/bin"]
COPY --from=build /build/vault-unseal /usr/local/bin/vault-unseal

# runtime params
WORKDIR /
ENV LOG_JSON=true
CMD ["/usr/local/bin/vault-unseal"]
