//
//  ActionCard.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class ActionCard: Card {
    enum Values: CaseIterable {
        case inspect, double, shuffle
    }
    
    var value: Int
    
    var faceUp: Bool
    
    required init(value: Int) {
        if (value in Values.allCases) { // <-- NEEDS TO BE FIXED
            
        }
    }
    
    
}
