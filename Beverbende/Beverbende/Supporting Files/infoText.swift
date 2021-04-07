//
//  infoText.swift
//  Beverbende
//
//  Created by Chiel Wijs on 15/03/2021.
//

import Foundation

enum GameState {
    case initialInspect, start, drawn, swap, inspect, end, knockedStart, knockedEnd
}

class InfoText {
    
    private let cardInfo = [
        "swap":"You have drawn a \"swap\" card, allowing you to swap one of your own cards with a card from one of your opponents. Tap the card to make use of this action, you can then select the cards you wish to swap. If you do not wish to use this action card, tap the discard pile to get rid of it.",
        "inspect":"You have drawn an \"inspect\" card, allowing you to take a peek at one of your cards on the table. Tap the card to make use of this action, you can then select the card you wish to inspect. Pay attention, the card will flip itself shut! If you do not wish to use this action card, tap the discard pile to get rid of it.",
        "twice":"You have drawn a \"twice\" card, allowing you to draw two more cards. Tap the card to make use of this action, you can then draw a new card. If you do not wish to use this action card, tap the discard pile to get rid of it.",
        "value":"You have drawn a value card. You can tap one of your own cards if you wish to trade it with the drawn card. If you do not wish make this trade, tap the discard pile to get rid of your drawn card."
    ]
    
    private let gameInfo: [GameState:String] = [
        .initialInspect:"You are at the start of a round. You get to inspect the left- and right-most card in front of you. Tap the \"Inspect\" button to do so. Once you are confident that you have remebered the cards, tap the \"Hide\" button to start you turn. Have a nice game!",
        .start:"It is the start of your turn. You can either draw a card, or trade the card on top of the discard pile with one of your own. To draw a card, you tap the face down deck of cards in the center of the screen. To make the trade, select the discard pile as well as your own card that you wish to trade. Good luck this turn!",
        .drawn:"You have drawn a card. Tap the question mark icon next to the card you drew to learn what you can do with it. If you wish to discard the card, you can tap the discard pile.",
        .swap:"You have played the \"swap\" action card. Select a card from yourself and a card from one of you opponents to swap them.",
        .inspect:"You have played the \"inspect\" action card. Tap on one of the cards in front of you to inspect it. Pay attention, the card will flip itself shut!",
        .end:"You have played your turn. If you want the game to continue, then let the others know that your turn is done. If you think that you have a winning set of cards in front of you and you want to signal the last round for the other players, then knock on the table.\n \n Remember, you want the sum of you cards to be as low as possible. Any action cards that you still have on the table at the end of the game will be traded with cards from the top of the deck, until you have no more action cards.",
        .knockedStart:"It is the start of your turn. You can either draw a card, or trade the card on top of the discard pile with one of your own. To draw a card, you tap the face down deck of cards in the center of the screen. To make the trade, select the discard pile as well as your own card that you wish to trade. Good luck this turn!\n \n Note: Someone already knocked. This is your last turn before everyone shows their cards. Remember, you want the sum of you cards to be as low as possible. Any action cards that you still have on the table will be traded with cards from the top of the deck, until you have no more action cards.",
        .knockedEnd:"You have played your turn. If you want the game to continue, then let the others know that your turn is done. As someone already knocked, you will soon see who has won."
    ]
    
    func getCardInfo(forCardWithName: String) -> String {
        if ["0","1","2","3","4","5","6","7","8","9"].contains(forCardWithName) {
            return cardInfo["value"]!
        }
        let info = cardInfo[forCardWithName] ?? "There is no information available"
        return info
    }
    
    func getGameInfo(forGameState: GameState) -> String {
        let info = gameInfo[forGameState] ?? "There is no information available"
        return info
    }
        
}
