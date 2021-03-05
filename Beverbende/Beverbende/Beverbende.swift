//
//  Beverbende.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class Beverbende {
    var playerIds: [String]
    var players: [Player]
    var currentPlayerIndex: Int
    var drawPile: Stack<Card>
    var discardPile: Stack<Card>
    
    static func allCards() -> [Card] {
        var values = Array(repeating: 0, count: 4)
        values = values + Array(repeating: 1, count: 4)
        values = values + Array(repeating: 2, count: 4)
        values = values + Array(repeating: 3, count: 4)
        values = values + Array(repeating: 4, count: 4)
        values = values + Array(repeating: 5, count: 4)
        values = values + Array(repeating: 6, count: 4)
        values = values + Array(repeating: 7, count: 4)
        values = values + Array(repeating: 8, count: 4)
        values = values + Array(repeating: 9, count: 9)
        let actions =
            Array(repeating: Action.inspect, count: 7) +
            Array(repeating: Action.twice, count: 5) +
            Array(repeating: Action.swap, count: 9)
        
        var cards: [Card] = []
        for v in values {
            cards.append(ValueCard(value: v))
        }
        for a in actions {
            cards.append(ActionCard(value: a))
        }
        
        return cards
    }
    
    init() {
        self.playerIds = [] // Placeholder
        self.players = [] // Placeholder
        self.currentPlayerIndex = 0
        self.discardPile = Stack<Card>()
        
        self.drawPile = Stack<Card>(initialArray: Beverbende.allCards().shuffled())
        self.discardPile.push(self.drawPile.pop()!)
        
        for _ in self.playerIds {
            // Assign cards to every player
            var cards: [Card] = []
            for _ in 0..<4 {
                cards.append(self.drawPile.pop()!)
            }
            // self.players.append(Player(withID: id, withCards: cards))
        }
    }
    
    func nextPlayer() -> Player {
        self.currentPlayerIndex = (self.currentPlayerIndex + 1) % self.players.count
        return self.players[self.currentPlayerIndex]
    }
    
    // Note: Does not set card.isFaceUp to true
    func drawCard(for player: Player) -> Card {
        var card = self.drawPile.pop()
        if card != nil {
            player.setCardOnHand(with: card!)
            return card!
        }
        
        // Draw pile was empty,
        // shuffle all but the top of the discard pile back into the draw pile
        let topDiscardedCard = self.discardPile.pop()!
        while self.discardPile.peek() != nil {
            var c = self.discardPile.pop()!
            c.isFaceUp = false
            self.drawPile.push(c)
        }
        // Shuffle the draw pile
        self.drawPile.shuffle()
        // Place the card that was on the top of the discard pile back
        self.discardPile.push(topDiscardedCard)
        
        card = self.drawPile.pop()
        player.setCardOnHand(with: card!)
        return card!
    }
    
    // Will probably be superseded by tradeDiscardedCardWithCard
    func drawDiscardedCard(for player: Player) -> Card {
        let card = self.discardPile.pop()!
        player.setCardOnHand(with: card)
        return card
    }
    
    func discardDrawnCard(for player: Player) {
        let card = player.getCardOnHand()!
        player.setCardOnHand(with: nil)
        self.discard(card: card)
    }
    
    func discard(card c: Card) {
        let card = c // Make the card mutable
        // card.isFaceUp = true
        self.discardPile.push(card)
    }
    
    func replaceCard(at index: Int, with c: Card, for player: Player) -> Card {
        let replacementCard = c
        // replacementCard.isFaceUp = false
        
        let replacedCard = player.getCardsOnTable()[index]
        player.setCardOnTable(with: replacementCard, at: index)
        return replacedCard
    }
    
    func inspectCard(at index: Int, for player: Player) -> Card {
        let card = player.getCardsOnTable()[index]
        // card.isFaceUp = true
        // ToDo: Allow for: player.setCardOnHand(with: card) which requires a moveCardBackFromHand method
        // ToDo: Should probably be followed with: player.setCardOnTable(with: nil, at: index)
        // but that requires player.cardsOnTable to be of type [Card?]
        return card
    }
    
    func hideCard(at index: Int, for player: Player) {
        var card = player.getCardsOnTable()[index]
        card.isFaceUp = false
    }
    
    func tradeDrawnCardWithCard(at index: Int, for player: Player) {
        let heldCard = player.getCardOnHand()!
        player.setCardOnHand(with: nil)
        let replacedCard = self.replaceCard(at: index, with: heldCard, for: player)
        self.discard(card: replacedCard)
    }
    
    func tradeDiscardedCardWithCard(at index: Int, for player: Player) {
        let discardedCard = self.discardPile.pop()!
        let replacedCard = self.replaceCard(at: index, with: discardedCard, for: player)
        self.discard(card: replacedCard)
    }
}
