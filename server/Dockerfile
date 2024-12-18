FROM golang:1.23

WORKDIR /usr/src/gameserver

COPY go.mod go.sum ./
RUN go mod download && go mod verify

COPY . .

RUN go build -v -o /gameserver/main ./cmd/main.go

CMD ["/gameserver/main", "--config", ".env"]