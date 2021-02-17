//
//  Card.swift
//  Beverbende
//
//  Created by L. Knol on 17/02/2021.
//

import Foundation

protocol Card {
    var value: Int { get }
    var faceUp: Bool { get set }
    
    init(value: Int)
}
