# Stage 1: Build
FROM golang:1.22.5 AS base

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY . .
RUN go build -o main .

# Stage 2: Minimal Runtime
FROM gcr.io/distroless/base

WORKDIR /

COPY --from=base /app/main /main
COPY --from=base /app/static /static

EXPOSE 8080

CMD ["./main"]
