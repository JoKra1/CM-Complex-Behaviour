//
//  ActionCard.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class ActionCard: Card {
    
    var action: Action
    
    var type: CardType
    var isFaceUp: Bool
    
    required init(value: Int) {
        self.action = Action(rawValue: value)!
        self.isFaceUp = false
        self.type = CardType.action(self.action)
    }
    
    init(value action: Action) {
        self.action = action
        self.isFaceUp = false
        self.type = CardType.action(self.action)
    }
    
    func getValue() -> Int {
        return self.action.rawValue
    }
    
    func getAction() -> Action {
        return self.action
    }
    
    func getType() -> CardType {
        return self.type
    }
}
