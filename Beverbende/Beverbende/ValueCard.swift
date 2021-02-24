//
//  ValueCard.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class ValueCard: Card {
    
    var value: Int
    
    var isFaceUp: Bool
    var type: CardType
    
    required init(value: Int) {
        self.value = value
        self.isFaceUp = false
        self.type = CardType.value(self.value)
    }
    
    func getValue() -> Int {
        return self.value
    }
    
    func getType() -> CardType {
        return self.type
    }
}
