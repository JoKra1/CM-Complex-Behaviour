//
//  BeverbendeDelegate.swift
//  Beverbende
//
//  Created by L. Knol on 03/03/2021.
//

import Foundation

enum EventType {
    case nextTurn, cardDrawn, discardedCardDrawn, cardPlayed, cardDiscarded, cardsSwapped, cardReplaced
}

protocol BeverbendeDelegate: AnyObject {
    func handleEvent(for event: EventType, with info: [String: Any])
}

/*
 EventType          Info object
 ---------          -----------
 nextTurn           ["player": Player]
 cardDrawn          ["player": Player]
 discardedCardDrawn ["player": Player]
 discardedCardTraded ["cardIndex": Int, "player": Player]
 cardPlayed         ["player": Player, "card": ActionCard]
 cardDiscarded      ["player": Player, "card": Card]
 cardsSwapped       ["cardIndex1": Int, "player1": Player, "cardIndex2": Int, "player2" Player]
 cardReplaced       ["cardIndex": Int, "player": Player]
 knocked
 gameEnded
 */
