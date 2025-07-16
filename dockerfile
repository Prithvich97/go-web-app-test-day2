# Stage 1: Build
FROM golang:1.22.5 AS base
#defining work dir , afetr this anything that will  be executed will be executed under this workdir
WORKDIR /app

# so all the requirments for this application will be defined go.mod file , so will copy and run this
COPY go.mod ./
RUN go mod download

# so copying the source code onto the image 
COPY . .
# this will create an artifcact called main will be created in our image 
RUN go build -o main .

# Stage 2: Minimal Runtime
FROM gcr.io/distroless/base

WORKDIR /
# copying the binary from /app dir of base image , will do the same for static files 
COPY --from=base /app/main /main
COPY --from=base /app/static /static

EXPOSE 8080

CMD ["./main"]
