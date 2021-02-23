//
//  ActionCard.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class ActionCard: Card {
    enum Values: Int, CaseIterable {
        case inspect = 0, double, shuffle
    }
    
    var value: Values
    
    var faceUp: Bool
    
    required init(value: Int) {
        self.value = Values(rawValue: value)!
        self.faceUp = false
    }
    
    func getValue() -> Int {
        return self.value.rawValue
    }
}
