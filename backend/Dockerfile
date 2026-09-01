# Build context: backend/ (Render Root Directory, docker compose)
FROM golang:1.22-alpine AS builder
WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . ./

RUN go install github.com/swaggo/swag/cmd/swag@v1.16.4
RUN swag init -g cmd/api/main.go -o docs --parseDependency --parseInternal --outputTypes json,go
RUN CGO_ENABLED=0 go build -o /api ./cmd/api

FROM alpine:3.20
RUN apk add --no-cache ca-certificates

COPY --from=builder /api /api
# SQL is also embedded in the binary; this copy is only used if MIGRATIONS_DIR is set.
COPY migrations /migrations

ENV MIGRATIONS_DIR=/migrations
EXPOSE 8080
ENTRYPOINT ["/api"]
