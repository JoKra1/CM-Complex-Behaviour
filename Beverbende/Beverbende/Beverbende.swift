//
//  Beverbende.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class Beverbende {
    var models: [Int] // Int is just a placeholder
    var drawPile: Stack<Card>
    var discardPile: Stack<Card>
    var playerCards: [Card]
    
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
            Array(repeating: ActionCard.Values.inspect, count: 7) +
            Array(repeating: ActionCard.Values.double, count: 5) +
            Array(repeating: ActionCard.Values.swap, count: 9)
        
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
        self.models = [] // Placeholder
        self.discardPile = Stack<Card>()
        
        self.drawPile = Stack<Card>(initialArray: Beverbende.allCards().shuffled())
        self.discardPile.push(self.drawPile.pop()!)
        
        self.playerCards = []
        for _ in 0..<4 {
            self.playerCards.append(self.drawPile.pop()!)
        }
        
        for _ in self.models {
            print("I still need to be implemented")
            // Assign cards to every model
        }
    }
    
    func drawCard() -> Card {
        let card = self.drawPile.pop()
        if card != nil {
            return card!
        }
        
        // Draw pile was empty,
        // shuffle all but the top of the discard pile back into the draw pile
        let topDiscardedCard = self.discardPile.pop()!
        while self.discardPile.peek() != nil {
            var c = self.discardPile.pop()!
            c.faceUp = false
            self.drawPile.push(c)
        }
        // Shuffle the draw pile
        self.drawPile.shuffle()
        // Place the card that was on the top of the discard pile back
        self.discardPile.push(topDiscardedCard)
        
        return self.drawPile.pop()!
    }
    
    func drawDiscardedCard() -> Card {
        return self.discardPile.pop()!
    }
    
    func discard(card c: Card) {
        var card = c // Make the card mutable
        card.faceUp = true
        self.discardPile.push(card)
    }
}
