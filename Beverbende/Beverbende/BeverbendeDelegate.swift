//
//  BeverbendeDelegate.swift
//  Beverbende
//
//  Created by L. Knol on 03/03/2021.
//

import Foundation

enum EventType {
    case nextTurn, cardDrawn, discardedCardDrawn, discardedCardTraded, cardPlayed, cardDiscarded, cardsSwapped, cardTraded, cardInspected, knocked, gameEnded
}

protocol BeverbendeDelegate: AnyObject {
    func handleEvent(for event: EventType, with info: [String: Any])
}

/*
 EventType          Info object
 ---------          -----------
 nextTurn           ["player": Player]
 cardDrawn          ["player": Player, "card": Card] changed
 discardedCardDrawn ["player": Player]
 discardedCardTraded ["player": Player, "CardToPlayer": Card, "cardFromPlayer": Card, "cardFromPlayerIndex": Int] changed
 cardPlayed         ["player": Player, "card": ActionCard]
 cardDiscarded      ["player": Player, "card": Card, "isFaceUp":Bool] changed
 cardsSwapped       ["cardIndex1": Int, "player1": Player, "cardIndex2": Int, "player2" Player]
 cardTraded       ["player": Player, "cardFromPlayer":Card, "cardFromPlayerIndex": Int, "toIsFaceUp":Bool] changed (also renamed form "cardReplaced", for consistency)
 cardInspected      ["player": Player, "card": Card, "cardIndex": Int] added
 knocked
 gameEnded
 */

// a FROM card goed From the player to the discard pile, a TO card moves from the hand or the discard pile to the player's on table cards

// is use this rather than onTable and onHand, as these obviously change during the animations
