//
//  Beverbende.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class Beverbende {
    var models: [Int]
    var drawPile: [Card]
    var discardPile: [Card]
    var playerCards: [Card]
    
    static func allCards() -> [Card] {
        var values = Array(repeating: 0, count: 1)
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
        self.models = []
        self.drawPile = []
        self.discardPile = []
        self.playerCards = []
    }
}
