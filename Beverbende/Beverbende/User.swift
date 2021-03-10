//
//  User.swift
//  Beverbende
//
//  Created by Loran on 10/03/2021.
//

import Foundation

class User: Player {
    var id: String
    
    var cardOnHand: Card?
    
    var cardsOnTable: [Card?]
    
    required init(with ID: String) {
        self.id = ID
        self.cardOnHand = nil
        self.cardsOnTable = []
    }
    
    func getId() -> String {
        return self.id
    }
    
    func getCardOnHand() -> Card? {
        return self.cardOnHand
    }
    
    func setCardOnHand(with card: Card?) {
        self.cardOnHand = card
    }
    
    func getCardsOnTable() -> [Card?] {
        return self.cardsOnTable
    }
    
    func setCardOnTable(with card: Card?, at index: Int) {
        self.cardsOnTable[index] = card
    }
    
    func setCardsOnTable(with cards: [Card?]) {
        self.cardsOnTable = cards
    }
    
    func replaceCardOnTable(at pos: Int, with card: Card) -> Card {
        let replacedCard = self.cardsOnTable[pos]
        self.cardsOnTable[pos] = card
        return replacedCard!
    }
    
    
}
