//
//  Player.swift
//  Beverbende
//
//  Created by L. Knol on 24/02/2021.
//

import Foundation

protocol Player {
    var id: String { get }
    var cardOnHand: Card? { get set }
    var cardsOnTable: [Card?] { get set }
    
    init(with ID: String)
    
    func getId() -> String
    func getCardOnHand() -> Card?
    func setCardOnHand(with card: Card?)
    func getCardsOnTable() -> [Card?]
    func setCardOnTable(with card: Card?, at index: Int)
    func setCardsOnTable(with cards: [Card?])
    
    func replaceCardOnTable(at pos: Int, with card: Card) -> Card
    
}
