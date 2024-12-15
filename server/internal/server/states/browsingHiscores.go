package states

import (
	"context"
	"fmt"
	"log"
	"server/internal/server"
	"server/internal/server/db"
	"server/pkg/packets"
)

type BrowsingHiscores struct {
	client  server.ClientInterfacer
	logger  *log.Logger
	queries *db.Queries
	dbCtx   context.Context
}

func (b *BrowsingHiscores) Name() string {
	return "BrowsingHiscores"
}

func (b *BrowsingHiscores) SetClient(client server.ClientInterfacer) {
	b.client = client
	loggingPrefix := fmt.Sprintf("Client %d [%s]: ", client.Id(), b.Name())
	b.logger = log.New(log.Writer(), loggingPrefix, log.LstdFlags)
	b.queries = client.DbTx().Queries
	b.dbCtx = client.DbTx().Ctx
}

func (b *BrowsingHiscores) OnEnter() {
	b.sendTopScores(10, 0)
}

func (b *BrowsingHiscores) HandleMessage(senderId uint64, message packets.Msg) {
	switch message := message.(type) {
	case *packets.Packet_FinishedBrowsingHiscores:
		b.handleFinishedBrowsingHiscoresMessage(senderId, message)
	case *packets.Packet_SearchHiscore:
		b.handleSearchHiscore(senderId, message)
	}
}

func (b *BrowsingHiscores) OnExit() {
}

func (b *BrowsingHiscores) handleFinishedBrowsingHiscoresMessage(senderId uint64, message *packets.Packet_FinishedBrowsingHiscores) {
	b.client.SetState(&Connected{})
}

func (b *BrowsingHiscores) handleSearchHiscore(senderId uint64, message *packets.Packet_SearchHiscore) {
	player, err := b.queries.GetPlayerByName(b.dbCtx, message.SearchHiscore.Name)

	if err != nil {
		b.logger.Printf("Error getting player %s: %v", message.SearchHiscore.Name, err)
		b.client.SocketSend(packets.NewDenyResponse("No player found with that name"))
		return
	}

	playerRank, err := b.queries.GetPlayerRank(b.dbCtx, player.ID)
	if err != nil {
		b.logger.Printf("Error getting rank of player %s: %v", player.Name, err)
		b.client.SocketSend(packets.NewDenyResponse("Player is unranked"))
		return
	}

	const limit int64 = 10
	offset := playerRank - limit/2
	b.sendTopScores(limit, max(0, offset))
}

func (b *BrowsingHiscores) sendTopScores(limit, offset int64) {
	topScores, err := b.queries.GetTopScores(b.dbCtx, db.GetTopScoresParams{
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		b.logger.Printf("Error getting top %d scores from rank %d: %v", limit, offset, err)
		b.client.SocketSend(packets.NewDenyResponse("Failed to get top scores - please try again later"))
		return
	}

	hiscoreMessages := make([]*packets.HiscoreMessage, 0, limit)
	for rank, scoreRow := range topScores {
		hiscoreMessage := &packets.HiscoreMessage{
			Rank:  uint64(rank) + uint64(offset) + 1,
			Name:  scoreRow.Name,
			Score: uint64(scoreRow.BestScore),
		}
		hiscoreMessages = append(hiscoreMessages, hiscoreMessage)
	}

	b.client.SocketSend(packets.NewHiscoreBoard(hiscoreMessages))
}
