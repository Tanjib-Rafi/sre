FROM golang:1.24 AS builder

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY app/go.mod app/go.sum ./
RUN go mod download

COPY app/ .

RUN CGO_ENABLED=0 GOOS=linux go build -o server .

FROM alpine:3.19

RUN apk add --no-cache ca-certificates

RUN adduser -D -g '' appuser

WORKDIR /app

COPY --from=builder /build/server /app/server

EXPOSE 8080

USER appuser

ENTRYPOINT ["/app/server"]