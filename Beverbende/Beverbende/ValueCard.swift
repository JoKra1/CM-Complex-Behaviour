//
//  ValueCard.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

class ValueCard: Card {
    var value = 0
    var faceUp = false
    
    required init(value: Int) {
        self.value = value
    }
}
