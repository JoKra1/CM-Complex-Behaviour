//
//  BeverbendeDelegate.swift
//  Beverbende
//
//  Created by L. Knol on 03/03/2021.
//

import Foundation

enum EventType {
    case nextTurn(Player),
         cardDrawn(Player, Card),
         discardedCardDrawn(Player, Card, Card?),
         discardedCardTraded(Player, Card, Card, Int, Card?),
         cardPlayed(Player, ActionCard),
         cardDiscarded(Player, Card, Bool),
         cardsSwapped(Int, Player, Int, Player),
         cardTraded(Player, Card, Int, Bool),
         cardInspected(Player, Card, Int),
         knocked(Player),
         gameEnded(Player)
}

protocol BeverbendeDelegate: AnyObject {
    func handleEvent(for event: EventType, with info: [String: Any])
}

/*
 EventType          Info object
 ---------          -----------
 nextTurn           ["player": Player]
 cardDrawn          ["player": Player, "card": Card] changed, also already in Beverbende.swift
 discardedCardDrawn ["player": Player, "card": Card, "topOfDeckCard": Card] changed, also already in Beverbende.swift
 discardedCardTraded ["player": Player, "CardToPlayer": Card, "cardFromPlayer": Card, "cardFromPlayerIndex": Int, "topOfDeckCard": Card] changed, also already in Beverbende.swift
 cardPlayed         ["player": Player, "card": ActionCard]
 cardDiscarded      ["player": Player, "card": Card, "isFaceUp":Bool] changed, we need to see who handles the isFaceUp, perhaps the controller.
 cardsSwapped       ["cardIndex1": Int, "player": Player, "cardIndex": Int, "player2" Player] needs code implementation, animations should work
 cardTraded       ["player": Player, "cardFromPlayer":Card, "cardFromPlayerIndex": Int, "toIsFaceUp":Bool] changed (also renamed form "cardReplaced", for consistency) already changed
 cardInspected      ["player": Player, "card": Card, "cardIndex": Int] added, not yet added to Beverbende.swift
 knocked            ["player": Player]
 gameEnded          ["winner": Player]
 */

// a FROM card goed From the player to the discard pile, a TO card moves from the hand or the discard pile to the player's on table cards

// is use this rather than onTable and onHand, as these obviously change during the animations
