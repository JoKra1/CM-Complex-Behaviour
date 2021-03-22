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
    weak var syncedDelegate: BeverbendeDelegate?
    var asyncQueue: DispatchQueue
    
    var knocked = false
    var gameEnded = false
    var countdown = 0 // This will only start ticking when knocked is true
    
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
            Array(repeating: Action.twice, count: 5)
            + Array(repeating: Action.swap, count: 9)
        
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
        self.asyncQueue = DispatchQueue(label: "DelegateQueue", attributes: .concurrent)
        
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
    
    func addSync(delegate: BeverbendeDelegate) {
        self.syncedDelegate = delegate
    }
    
    private func notifyDelegates(for event: EventType, with info: [String: Any]) {
        // Notify cognitive model delegates
        for wd in self.delegates {
            let delegate = wd.value
            
            self.asyncQueue.async {
                delegate?.handleEvent(for: event, with: info)
            }
        }
        
        // Notify ViewController (which has to be called from the main thread)
        DispatchQueue.main.async {
            self.syncedDelegate?.handleEvent(for: event, with: info)
        }
    }

    func nextPlayer() -> Player {
        if self.gameEnded {
            return self.players[self.currentPlayerIndex]
        }
        
        self.currentPlayerIndex = (self.currentPlayerIndex + 1) % self.players.count
        
        let player = self.players[self.currentPlayerIndex]
        self.notifyDelegates(
            for: .nextTurn(player),
            with: ["player": player])
        
        // Check for end of game - if so, notify delegates
        if self.knocked && self.countdown == 0 {
            // Game has ended, determine winner
            var scores: [String: Int] = [:]
            var lowestScore = 4 * 9
            var winner = self.players[0]
            
            self.notifyDelegates(for: .tradingLeftoverActionCards, with: [:])
            
            for player in self.players {
                scores[player.getId()] = 0
                
                // Sum all values
                for (index, card) in player.getCardsOnTable().enumerated() {
                    let c = card!
                    var drawnCard: Card
                    switch c.getType() {
                    case .action:
                        // Keep drawing until receiving a value card
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
            
            self.gameEnded = true
            self.notifyDelegates(
                for: .gameEnded(winner),
                with: ["winner": winner])
        } else if self.knocked {
            self.countdown -= 1
        }
        
        return player
    }
    
    func isValueCard(card: Card) -> Bool {
        if case .value = card.getType() {
            return true
        }
        
        return false
    }
    
    func knock(from player: Player) {
        if !self.knocked {
            self.knocked = true
            self.countdown = self.players.count - 1
        
            self.notifyDelegates(
                for: .knocked(player),
                with: ["player": player])
        }
    }
    
    
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
        
        self.notifyDelegates(
            for: .cardDrawn(player, card!),
            with: ["player": player, "card": card!])
        
        return card!
    }
    
    // Might supersede tradeDiscardedCardWithCard
    func drawDiscardedCard(for player: Player) -> Card {
        let card = self.discardPile.pop()!
        let topOfDeckCard = self.discardPile.peek()
        player.setCardOnHand(with: card)
        
        self.notifyDelegates(
            for: .discardedCardDrawn(player, card, topOfDeckCard),
            with: ["player": player, "card":card, "topOfDeckCard": topOfDeckCard as Any])
        
        return card
    }
    
    func discardDrawnCard(for player: Player) {
        var card = player.getCardOnHand()!
        player.setCardOnHand(with: nil)
        self.discard(card: card)
        
        self.notifyDelegates(
            for: .cardDiscarded(player, card, card.isFaceUp),
            with: ["player": player, "card": card, "isFaceUp":card.isFaceUp]) // TODO: THIS isFaceUp VALUE IS NOT CORRECT, FOR TESTING
        
        card.isFaceUp = false // is it okay to do this here?
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
        
        self.notifyDelegates(
            for: .cardInspected(player, card, index),
            with: ["player": player, "card": card, "cardIndex": index])
        
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
        var heldCard = player.getCardOnHand()!
        player.setCardOnHand(with: nil)
        let replacedCard = self.replaceCard(at: index, with: heldCard, for: player)
        self.discard(card: replacedCard)
        self.notifyDelegates(
            for: .cardTraded(player, replacedCard, index, heldCard.isFaceUp),
            with: ["player": player, "cardFromPlayer":replacedCard, "cardFromPlayerIndex": index, "toIsFaceUp": heldCard.isFaceUp]) // TODO: THIS isFaceUp VALUE IS NOT CORRECT, FOR TESTING
        
        heldCard.isFaceUp = false
    }
    
    func tradeDiscardedCardWithCard(at index: Int, for player: Player) {
        let discardedCard = self.discardPile.pop()!
        let topOfDeckCard = self.discardPile.peek()
        let replacedCard = self.replaceCard(at: index, with: discardedCard, for: player)
        self.discard(card: replacedCard)
        
        self.notifyDelegates(
            for: .discardedCardTraded(player, discardedCard, replacedCard, index, topOfDeckCard),
            with: ["player": player, "cardToPlayer": discardedCard, "cardFromPlayer": replacedCard, "cardFromPlayerIndex": index, "topOfDeckCard": topOfDeckCard as Any])
        
    }
    
    func swapCards(cardAt index1: Int, for player1: Player, withCardAt index2: Int, for player2: Player) {
        let swappedCard1 = player1.getCardsOnTable()[index1]!
        let swappedCard2 = self.replaceCard(at: index2, with: swappedCard1, for: player2)
        _ = self.replaceCard(at: index1, with: swappedCard2, for: player1)
        
        // i think this is the correct way to swap them
        
        self.notifyDelegates(
            for: .cardsSwapped(index1, player1, index2, player2),
            with: ["cardIndex": index1, "player": player1, "cardIndex2": index2, "player2": player2])
    }
}
