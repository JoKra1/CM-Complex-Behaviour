//
//  BeverbendeDelegate.swift
//  Beverbende
//
//  Created by L. Knol on 03/03/2021.
//

import Foundation

enum EventType {
    case nextTurn
}

protocol BeverbendeDelegate {
    func handleEvent(for event: EventType, with info: [String: Any])
}
