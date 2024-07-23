FROM golang:1.22 as builder

ARG APP

WORKDIR /app
COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/app ./cmd/$APP

FROM alpine:latest

ARG APP

#RUN apk add --no-cache tzdata && apk --no-cache add ca-certificates
#RUN wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -O /etc/ssl/certs/global-bundle.pem && update-ca-certificates
#RUN GRPC_HEALTH_PROBE_VERSION=v0.4.15 && \
#    wget -qO/bin/grpc_health_probe https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/${GRPC_HEALTH_PROBE_VERSION}/grpc_health_probe-linux-amd64 && \
#    chmod +x /bin/grpc_health_probe

COPY --from=builder /app/bin/app /bin/app
COPY --from=builder /app/cmd/$APP/config/config.yml /configs/
COPY --from=builder /app/cmd/$APP/dbmigration[s]/ /dbmigrations/

ENTRYPOINT ["/bin/app", "-c", "/configs/config.yml", "-env", "prod"]
