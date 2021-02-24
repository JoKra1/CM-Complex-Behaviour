//
//  Card.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

enum Action: Int, CaseIterable {
    case inspect = 0, double, swap
}

enum CardType {
    case value(Int)
    case action(Action)
}

protocol Card {
    var type:CardType { get }
    var isFaceUp: Bool { get set }
    
    init(value: Int)
    func getValue() -> Int
    func getType() -> CardType
}
