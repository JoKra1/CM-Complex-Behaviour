//
//  Player.swift
//  Beverbende
//
//  Created by L. Knol on 24/02/2021.
//

import Foundation

protocol Player {
    var id: String { get }
    var cardOnHand: Card { get set }
    var cardsOnTable: [Card] { get set }
    
    init(withID: String, withCards: [Card])
    
    func getId() -> String
    func getCardOnHand() -> Card
    func setCardOnHand(with: Card)
    func getCardsOnTable() -> [Card]
    
    func replaceCardOnTable(at: Int, with: Card) -> Card
    
}
