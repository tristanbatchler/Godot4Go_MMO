package states

import (
	"context"
	"fmt"
	"log"
	"math"
	"server/internal/server"
	"server/internal/server/objects"
	"server/pkg/packets"
	"time"
)

type InGame struct {
	client                 server.ClientInterfacer
	player                 *objects.Player
	logger                 *log.Logger
	cancelPlayerUpdateLoop context.CancelFunc
}

func (g *InGame) Name() string {
	return "InGame"
}

func (g *InGame) SetClient(client server.ClientInterfacer) {
	g.client = client
	loggingPrefix := fmt.Sprintf("Client %d [%s]: ", client.Id(), g.Name())
	g.logger = log.New(log.Writer(), loggingPrefix, log.LstdFlags)
}

func (g *InGame) OnEnter() {
	log.Printf("Adding player %s to the shared collection", g.player.Name)
	go g.client.SharedGameObjects().Players.Add(g.player, g.client.Id())

	// Set the initial properties of the player
	g.player.X, g.player.Y = objects.SpawnCoords(g.player.Radius, g.client.SharedGameObjects().Players, nil)
	g.player.Speed = 150.0
	g.player.Radius = 20.0

	// Send the player's initial state to the client
	g.client.SocketSend(packets.NewPlayer(g.client.Id(), g.player))

	// Send the spores to the client in the background
	go g.sendInitialSpores(20, 50*time.Millisecond)
}

func (g *InGame) HandleMessage(senderId uint64, message packets.Msg) {
	switch message := message.(type) {
	case *packets.Packet_Player:
		g.handlePlayer(senderId, message)
	case *packets.Packet_PlayerDirection:
		g.handlePlayerDirection(senderId, message)
	case *packets.Packet_Chat:
		g.handleChat(senderId, message)
	case *packets.Packet_SporeConsumed:
		g.handleSporeConsumed(senderId, message)
	case *packets.Packet_PlayerConsumed:
		g.handlePlayerConsumed(senderId, message)
	case *packets.Packet_Spore:
		g.handleSpore(senderId, message)
	}
}

func (g *InGame) OnExit() {
	if g.cancelPlayerUpdateLoop != nil {
		g.cancelPlayerUpdateLoop()
	}
	g.client.SharedGameObjects().Players.Remove(g.client.Id())
}

func (g *InGame) handlePlayer(senderId uint64, message *packets.Packet_Player) {
	if senderId == g.client.Id() {
		g.logger.Println("Received player message from our own client, ignoring")
		return
	}

	g.client.SocketSendAs(message, senderId)
}

func (g *InGame) handlePlayerDirection(senderId uint64, message *packets.Packet_PlayerDirection) {
	if senderId != g.client.Id() {
		g.logger.Println("Received player direction message from a different client, ignoring")
		return
	}

	g.player.Direction = message.PlayerDirection.Direction

	// If this is the first time receiving a player direction message from our client, start the player update loop
	if g.cancelPlayerUpdateLoop == nil {
		ctx, cancel := context.WithCancel(context.Background())
		g.cancelPlayerUpdateLoop = cancel
		go g.playerUpdateLoop(ctx)
	}
}

func (g *InGame) handleChat(senderId uint64, message *packets.Packet_Chat) {
	if senderId == g.client.Id() {
		g.client.Broadcast(message)
	} else {
		g.client.SocketSendAs(message, senderId)
	}
}

func (g *InGame) handleSporeConsumed(senderId uint64, message *packets.Packet_SporeConsumed) {
	if senderId != g.client.Id() {
		g.client.SocketSendAs(message, senderId)
		return
	}

	// If the spore was supposedly consumed by our player, we need to verify the plausibility of the event
	errMsg := "Could not verify spore consumption: "

	// First, check if the spore exists
	sporeId := message.SporeConsumed.SporeId
	spore, err := g.getSpore(sporeId)
	if err != nil {
		g.logger.Println(errMsg + err.Error())
		return
	}

	// Next, check if the spore is closed enough to be consumed
	err = g.validatePlayerCloseToObject(spore.X, spore.Y, spore.Radius, 10)
	if err != nil {
		g.logger.Println(errMsg + err.Error())
		return
	}

	// If we made this far, the spore consumption is valid, so grow the player, remove the spore, and broadcast the event
	sporeMass := radToMass(spore.Radius)
	g.player.Radius = g.nextRadius(sporeMass)

	go g.client.SharedGameObjects().Spores.Remove(sporeId)

	g.client.Broadcast(message)
}

func (g *InGame) handlePlayerConsumed(senderId uint64, message *packets.Packet_PlayerConsumed) {
	if senderId != g.client.Id() {
		g.client.SocketSendAs(message, senderId)

		if message.PlayerConsumed.PlayerId == g.client.Id() {
			g.logger.Println("Player was consumed, respawning")
			g.client.SetState(&InGame{
				player: &objects.Player{
					Name: g.player.Name,
				},
			})
		}

		return
	}

	// If the other player was supposedly consumed by our player, we need to verify the plausibility of the event
	errMsg := "Could not verify player consumption: "

	// First check if the player exists
	otherId := message.PlayerConsumed.PlayerId
	other, err := g.getOtherPlayer(otherId)
	if err != nil {
		g.logger.Println(errMsg + err.Error())
		return
	}

	// Next, check if the other player is closed enough to be consumed
	err = g.validatePlayerCloseToObject(other.X, other.Y, other.Radius, 10)
	if err != nil {
		g.logger.Println(errMsg + err.Error())
		return
	}

	// Finally, check the other player's radius is smaller than our player's
	if g.player.Radius <= other.Radius*1.5 {
		g.logger.Println(errMsg + "player's radius not big enough")
		return
	}

	// If we made it this far, the player consumption is valid, so grow the player, remove the consumed other, and broadcast the event
	otherMass := radToMass(other.Radius)
	g.player.Radius = g.nextRadius(otherMass)

	go g.client.SharedGameObjects().Players.Remove(otherId)

	g.client.Broadcast(message)
}

func (g *InGame) handleSpore(senderId uint64, message *packets.Packet_Spore) {
	g.client.SocketSendAs(message, senderId)
}

func (g *InGame) playerUpdateLoop(ctx context.Context) {
	const delta float64 = 0.05
	ticker := time.NewTicker(time.Duration(delta*1000) * time.Millisecond)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			g.syncPlayer(delta)
		case <-ctx.Done():
			return
		}
	}
}

func (g *InGame) syncPlayer(delta float64) {
	newX := g.player.X + g.player.Speed*math.Cos(g.player.Direction)*delta
	newY := g.player.Y + g.player.Speed*math.Sin(g.player.Direction)*delta

	g.player.X = newX
	g.player.Y = newY

	updatePlayer := packets.NewPlayer(g.client.Id(), g.player)
	g.client.Broadcast(updatePlayer)
	go g.client.SocketSend(updatePlayer)
}

func (g *InGame) sendInitialSpores(batchSize int, delay time.Duration) {
	sporesBatch := make(map[uint64]*objects.Spore, batchSize)

	g.client.SharedGameObjects().Spores.ForEach(func(sporeId uint64, spore *objects.Spore) {
		sporesBatch[sporeId] = spore

		if len(sporesBatch) >= batchSize {
			g.client.SocketSend(packets.NewSporesBatch(sporesBatch))
			sporesBatch = make(map[uint64]*objects.Spore, batchSize)
			time.Sleep(delay)
		}
	})

	// Send any remaining spores
	if len(sporesBatch) > 0 {
		g.client.SocketSend(packets.NewSporesBatch(sporesBatch))
	}
}

func (g *InGame) getSpore(sporeId uint64) (*objects.Spore, error) {
	spore, exists := g.client.SharedGameObjects().Spores.Get(sporeId)
	if !exists {
		return nil, fmt.Errorf("spore with ID %d does not exist", sporeId)
	}
	return spore, nil
}

func (g *InGame) getOtherPlayer(playerId uint64) (*objects.Player, error) {
	player, exists := g.client.SharedGameObjects().Players.Get(playerId)
	if !exists {
		return nil, fmt.Errorf("player with ID %d does not exist", playerId)
	}
	return player, nil
}

func (g *InGame) validatePlayerCloseToObject(objX, objY, objRadius, buffer float64) error {
	realDX := g.player.X - objX
	realDY := g.player.Y - objY
	realDistSq := realDX*realDX + realDY*realDY

	thresholdDist := g.player.Radius + buffer + objRadius
	thresholdDistSq := thresholdDist * thresholdDist

	if realDistSq > thresholdDistSq {
		return fmt.Errorf("player is too far from the object (distSq: %f, thresholdSq: %f)", realDistSq, thresholdDistSq)
	}
	return nil
}

func radToMass(radius float64) float64 {
	return math.Pi * radius * radius
}

func massToRad(mass float64) float64 {
	return math.Sqrt(mass / math.Pi)
}

func (g *InGame) nextRadius(massDiff float64) float64 {
	oldMass := radToMass(g.player.Radius)
	newMass := oldMass + massDiff
	return massToRad(newMass)
}
