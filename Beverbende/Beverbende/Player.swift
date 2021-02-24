//
//  Player.swift
//  Beverbende
//
//  Created by L. Knol on 24/02/2021.
//

import Foundation

protocol Player {
    var id: String { get }
    var hand: Card { get set }
    var cards: [Card] { get set }
}
