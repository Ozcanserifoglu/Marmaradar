# Build context must be the monorepo root:
#   docker build -f backend/Dockerfile .
FROM golang:1.22-alpine AS builder
WORKDIR /app

COPY backend/go.mod backend/go.sum ./
RUN go mod download

COPY backend/ ./
COPY infra/migrations /migrations

RUN CGO_ENABLED=0 go build -o /api ./cmd/api

FROM alpine:3.20
RUN apk add --no-cache ca-certificates

COPY --from=builder /api /api
COPY --from=builder /migrations /migrations

ENV MIGRATIONS_DIR=/migrations
EXPOSE 8080
ENTRYPOINT ["/api"]
