//
//  ViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 16/02/2021.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        for index in playerCardButtons.indices {
            showBackOfCard(for: playerCardButtons[index])
        }
        showBackOfCard(for: deckButton)
        showEmptyArea(for: drawnCardButton)
        showEmptyArea(for: discardPileButton)
    }

    @IBOutlet weak var deckButton: UIButton!
    
    @IBOutlet weak var discardPileButton: UIButton!
    
    @IBOutlet weak var drawnCardButton: UIButton!
    
    @IBOutlet var playerCardButtons: [UIButton]!
 
    func showBackOfCard(for cardButton: UIButton){
        cardButton.setTitle("🦫", for: UIControl.State.normal)
        cardButton.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        cardButton.layer.cornerRadius = 10
        cardButton.layer.borderWidth = 10
        cardButton.layer.borderColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
    }
    
    @IBAction func drawCardFromDeck(_ sender: UIButton) {
    }
    
    @IBAction func touchDiscardPile(_ sender: UIButton) {
        // either discard or draw from this pile depending on game state
    }
    
    @IBAction func touchOwnCard(_ sender: UIButton) {
        // use game state to determine appropriate action
    }
    
    // Functions for card visualization
    func showEmptyArea(for cardButton : UIButton) {
        cardButton.setTitle("", for: UIControl.State.normal)
        cardButton.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
        cardButton.layer.cornerRadius = 10
        cardButton.layer.borderWidth = 3
        cardButton.layer.borderColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
    }
    
    func showFrontOfNumberCard(show value: String, on cardButton: UIButton) {
        //very basic
        cardButton.setTitle(value, for: UIControl.State.normal)
        cardButton.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        cardButton.layer.cornerRadius = 10
    }
    
    func showFrontOfActionCard(show value: String, on cardButton: UIButton) {
        // implement this for various action cards
    }
}

