//
//  infoText.swift
//  Beverbende
//
//  Created by Chiel Wijs on 15/03/2021.
//

import Foundation

class InfoText {
    
    private let cardInfo = [
        "swap":"You have drawn a \"swap\" card, allowing you to swap one of your own cards with a card from one of your opponents. Tap the card to make use of this action, you can then select the cards you wish to swap. If you do not wish to use this action card, tap the discard pile to get rid of it.",
        "inspect":"You have drawn an \"inspect\" card, allowing you to take a peek at one of your cards on the table. Tap the card to make use of this action, you can then select the card you wish to inspect. Pay attention, the card will flip itself shut! If you do not wish to use this action card, tap the discard pile to get rid of it.",
        "Twice":"You have drawn a \"twice\" card, allowing you to draw two more cards. Tap the card to make use of this action, you can then draw a new card. If you do not wish to use this action card, tap the discard pile to get rid of it.",
        "value":"You have drawn a value card. You can tap one of your own cards if you wish to trade it with the drawn card. If you do not wish make this trade, tap the discard pile to get rid of your drawn card."
    ]
    
    private let gameInfo = [
        "initialInspect":"You are at the start of a round. You get to inspect the left- and right-most card in front of you. Tap the \"Inspect\" button to do so. Once you are confident that you have remebered the cards, tap the \"Hide\" button to start you turn. Have a nice game!",
        "start":"It is the start of your turn. You can either draw a card, or trade the card on top of the discard pile with one of your own. To draw a card, you tap the face down deck of cards in the center of the screen. To make the trade, select the discard pile as well as your own card that you wish to trade. Good luck this turn!",
        "drawn":"You have drawn a card. Tap the question mark icon next to the card you drew to learn what you can do with it. If you wish to discard the card, you can press the discard pile.",
        "swap":"You have played the \"swap\" action card. Select a card from yourself and a card from one of you opponents to swap them.",
        "inspect":"You have played the \"inspect\" action card. Tap on one of the cards in front of you to inspect it. Pay attention, the card will flip itself shut!"
    ]
    
    func getCardInfo(forCardWithName: String) -> String {
        if ["0","1","2","3","4","5","6","7","8","9"].contains(forCardWithName) {
            return cardInfo["value"]!
        }
        let info = gameInfo[forCardWithName] ?? "There is no information available"
        return info
    }
    
    func getGameInfo(forGameStateWithName: String) -> String {
        let info = gameInfo[forGameStateWithName] ?? "There is no information available"
        return info
    }
        
}
