package main

import (
	"fmt"
	"server/pkg/packets"

	"google.golang.org/protobuf/proto"
)

func main() {
	data := []byte{8, 69, 18, 15, 10, 13, 72, 101, 108, 108, 111, 44, 32, 119, 111, 114, 108, 100, 33}

	packet := &packets.Packet{}
	err := proto.Unmarshal(data, packet)
	if err != nil {
		panic(err)
	}

	fmt.Println(packet)
}
