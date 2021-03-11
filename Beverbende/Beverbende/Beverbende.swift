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
    var delegates: [WeakContainer<BeverbendeDelegate>]
    
    var knocked = false
    var countdown = 10
    
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
        let actions = Array(repeating: Action.inspect, count: 7) +
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
    
    init(with humanPlayer: Player, cognitiveIds: [String]) {
        self.playerIds = [humanPlayer.getId()] + cognitiveIds
        self.players = [humanPlayer]
        
        self.delegates = []
        
        self.currentPlayerIndex = 0
        self.discardPile = Stack<Card>()
        
        self.drawPile = Stack<Card>(initialArray: Beverbende.allCards().shuffled())
        self.discardPile.push(self.drawPile.pop()!)
        
        for cognitiveId in cognitiveIds {
            var cards: [Card?] = []
            for _ in 0..<4 {
                cards.append(self.drawPile.pop()!)
            }
            
            let opponent = BeverbendeOpponent(with: cognitiveId, with: cards, for: self)
            self.players.append(opponent)
        }
        
        // Quick and dirty fix here, I know I know its code repetition :-(
        var cards: [Card?] = []
        for _ in 0..<4 {
            cards.append(self.drawPile.pop()!)
        }
        humanPlayer.setCardsOnTable(with: cards)
        
    }
    
    func add(delegate: BeverbendeDelegate) {
        var wd = WeakContainer<BeverbendeDelegate>()
        wd.value = delegate
        self.delegates.append(wd)
    }
    
    private func notifyDelegates(for event: EventType, with info: [String: Any]) {
        for wd in self.delegates {
            let delegate = wd.value
            delegate?.handleEvent(for: event, with: info)
        }
    }

    func nextPlayer() -> Player {
        self.currentPlayerIndex = (self.currentPlayerIndex + 1) % self.players.count
        
        let player = self.players[self.currentPlayerIndex]
        self.notifyDelegates(for: EventType.nextTurn, with: ["player": player])
        
        // Check for end of game - if so, notify delegates
        if self.countdown == 0 {
            // Game has ended
            var scores: [String: Int] = [:]
            var lowestScore = 4 * 9
            var winner = self.players[0]
            
            for player in self.players {
                scores[player.getId()] = 0
                
                for (index, card) in player.getCardsOnTable().enumerated() {
                    let c = card!
                    var drawnCard: Card
                    switch c.getType() {
                    case .action:
                        repeat {
                            drawnCard = self.drawCard(for: player)
                            self.tradeDrawnCardWithCard(at: index, for: player)
                        } while !isValueCard(card: drawnCard)
                        scores[player.getId()]! += drawnCard.getValue()
                    case .value:
                        scores[player.getId()]! += c.getValue()
                    }
                }
                
                if scores[player.getId()]! < lowestScore {
                    lowestScore = scores[player.getId()]!
                    winner = player
                }
            }
            
            self.notifyDelegates(for: EventType.gameEnded, with: ["winner": winner])
        }
        self.countdown -= 1
        
        return player
    }
    
    func isValueCard(card: Card) -> Bool {
        if case .value = card.getType() {
            return true
        }
        
        return false
    }
    
    func knock(from player: Player) {
        self.knocked = true
        self.countdown = self.players.count - 1
        
        self.notifyDelegates(for: EventType.knocked, with: ["player": player])
    }
    
    // TODO: make swapCard method
    
    // Note: Does not set card.isFaceUp to true
    func drawCard(for player: Player) -> Card {
        var card = self.drawPile.pop()
        if card == nil {
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
        }
        
        player.setCardOnHand(with: card!)
        
        self.notifyDelegates(for: EventType.cardDrawn, with: ["player": player, "card": card!])
        
        return card!
    }
    
    // Might supersede tradeDiscardedCardWithCard
    func drawDiscardedCard(for player: Player) -> Card {
        let card = self.discardPile.pop()!
        player.setCardOnHand(with: card)
        
        self.notifyDelegates(for: EventType.discardedCardDrawn, with: ["player": player, "card":card])
        
        return card
    }
    
    func discardDrawnCard(for player: Player) {
        let card = player.getCardOnHand()!
        player.setCardOnHand(with: nil)
        self.discard(card: card)
        
        self.notifyDelegates(for: EventType.cardDiscarded, with: ["player": player, "card": card, "isFaceUp":false]) // TODO: THIS isFaceUp VALUE IS NOT CORRECT, FOR TESTING
    }
    
    func discard(card c: Card) {
        let card = c
        // card.isFaceUp = true
        self.discardPile.push(card)
    }
    
    func replaceCard(at index: Int, with c: Card, for player: Player) -> Card {
        let replacementCard = c
        // replacementCard.isFaceUp = false
        
        let replacedCard = player.getCardsOnTable()[index]!
        player.setCardOnTable(with: replacementCard, at: index)
        return replacedCard
    }
    
    func inspectCard(at index: Int, for player: Player) -> Card {
        let card = player.getCardsOnTable()[index]!
        // card.isFaceUp = true
        player.setCardOnHand(with: card)
        player.setCardOnTable(with: nil, at: index)
        
        self.notifyDelegates(for: EventType.cardInspected, with: ["player": player, "card": card, "cardIndex": index])
        
        return card
    }
    
    func moveCardBackFromHand(to index: Int, for player: Player) {
        let card = player.getCardOnHand()!
        player.setCardOnHand(with: nil)
        player.setCardOnTable(with: card, at: index)
    }
    
    func hideCard(at index: Int, for player: Player) {
        var card = player.getCardsOnTable()[index]!
        card.isFaceUp = false
    }
    
    func tradeDrawnCardWithCard(at index: Int, for player: Player) {
        let heldCard = player.getCardOnHand()!
        player.setCardOnHand(with: nil)
        let replacedCard = self.replaceCard(at: index, with: heldCard, for: player)
        self.discard(card: replacedCard)
        
        self.notifyDelegates(for: EventType.cardTraded, with: ["player": player, "cardFromPlayer":replacedCard, "cardFromPlayerIndex": index, "toIsFaceUp": true]) // TODO: THIS isFaceUp VALUE IS NOT CORRECT, FOR TESTING
    }
    
    func tradeDiscardedCardWithCard(at index: Int, for player: Player) {
        let discardedCard = self.discardPile.pop()!
        let replacedCard = self.replaceCard(at: index, with: discardedCard, for: player)
        self.discard(card: replacedCard)
        
        self.notifyDelegates(for: .discardedCardTraded, with: ["player": player, "cardToPlayer": discardedCard, "cardFromPlayer": replacedCard, "cardFromPlayerIndex": index])
        
    }
}
