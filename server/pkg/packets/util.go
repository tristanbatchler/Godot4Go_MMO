package packets

import "server/internal/server/objects"

type Msg = isPacket_Msg

func NewChat(msg string) Msg {
	return &Packet_Chat{
		Chat: &ChatMessage{
			Msg: msg,
		},
	}
}

func NewId(id uint64) Msg {
	return &Packet_Id{
		Id: &IdMessage{
			Id: id,
		},
	}
}

func NewOkResponse() Msg {
	return &Packet_OkResponse{
		OkResponse: &OkResponseMessage{},
	}
}

func NewDenyResponse(reason string) Msg {
	return &Packet_DenyResponse{
		DenyResponse: &DenyResponseMessage{
			Reason: reason,
		},
	}
}

func NewPlayer(id uint64, player *objects.Player) Msg {
	return &Packet_Player{
		Player: &PlayerMessage{
			Id:        id,
			Name:      player.Name,
			X:         player.X,
			Y:         player.Y,
			Radius:    player.Radius,
			Direction: player.Direction,
			Speed:     player.Speed,
		},
	}
}

func newSporeMessage(spore_id uint64, spore *objects.Spore) *SporeMessage {
	return &SporeMessage{
		Id:     spore_id,
		X:      spore.X,
		Y:      spore.Y,
		Radius: spore.Radius,
	}
}

func NewSpore(id uint64, spore *objects.Spore) Msg {
	return &Packet_Spore{
		newSporeMessage(id, spore),
	}
}

func NewSporesBatch(spores map[uint64]*objects.Spore) Msg {
	sporesMessages := make([]*SporeMessage, len(spores))
	for id, spore := range spores {
		sporesMessages = append(sporesMessages, newSporeMessage(id, spore))
	}

	return &Packet_SporesBatch{
		SporesBatch: &SporesBatchMessage{
			Spores: sporesMessages,
		},
	}
}

func NewHiscoreBoard(hiscores []*HiscoreMessage) Msg {
	return &Packet_HiscoreBoard{
		HiscoreBoard: &HiscoreBoardMessage{
			Hiscores: hiscores,
		},
	}
}
