FROM golang:1.18.1-alpine3.15 AS builder

COPY . /app/go

WORKDIR /app/go

RUN go build -v -o app .

FROM alpine:3.15.4

WORKDIR /app

COPY --from=builder /app/go/app ./app

CMD ["./app"]
