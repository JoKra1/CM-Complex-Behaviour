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
        manageCardStacks()
        showBackOfCard(for: deckButton)
        showEmptyArea(for: drawnCardButton)
        showEmptyArea(for: discardPileButton)
        showInspectButton()
        manageCardStacks()
    }

    @IBOutlet weak var deckButton: UIButton!
    
    @IBOutlet weak var discardPileButton: UIButton!
    
    @IBOutlet weak var drawnCardButton: UIButton!
    
    @IBOutlet weak var inspectButton: UIButton!
    
    @IBOutlet var playerCardButtons: [UIButton]!
    
    @IBOutlet var leftModelCardButtons: [UIButton]!
    
    @IBOutlet var topModelCardButtons: [UIButton]!
    
    @IBOutlet var rightModelCardButtons: [UIButton]!
    
    @IBAction func drawCardFromDeck(_ sender: UIButton) {
    }
    
    @IBAction func touchDiscardPile(_ sender: UIButton) {
        // either discard or draw from this pile depending on game state
    }
    
    @IBAction func touchOwnCard(_ sender: UIButton) {
        let cardIndex = playerCardButtons.firstIndex(of: sender)!
        print("cardIndex \(cardIndex)")
        // use game state to determine appropriate action
        if true {
            showFrontOfNumberCard(show: "4", on: sender)
        }
    }
    
    var initialInspection = false
    
    @IBAction func touchInspectButton(_ sender: UIButton) {
        if initialInspection == false {
            initialInspection = true
            sender.setTitle("Hide", for: UIControl.State.normal)
            for index in [0, 3] {
                let cardButton = playerCardButtons[index]
                showFrontOfNumberCard(show: "4", on: cardButton)
            }
        } else {
            for index in [0, 3] {
                let cardButton = playerCardButtons[index]
                showBackOfCard(for: cardButton)
            }
            sender.isHidden = true
        }
    }
    
    func loadViewFromModel() {
        
    }
    
    func showBackOfCard(for cardButton: UIButton){
        cardButton.setTitle("🐿", for: UIControl.State.normal)
        cardButton.backgroundColor = #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
        cardButton.layer.cornerRadius = 10
        cardButton.layer.borderWidth = 10
        cardButton.layer.borderColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
    }
    
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
    }
    
    func showFrontOfActionCard(show value: String, on cardButton: UIButton) {
        // implement this for various action cards
    }
    
    func showInspectButton() {
        initialInspection = false
        inspectButton.isHidden = false
        inspectButton.setTitle("Inspect", for: UIControl.State.normal)
        inspectButton.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        inspectButton.layer.cornerRadius = 10
    }
    
    @IBOutlet weak var playerCardStack: UIStackView!

    @IBOutlet weak var leftCardStack: UIStackView!
    
    @IBOutlet weak var topCardStack: UIStackView!
    
    @IBOutlet weak var rightCardStack: UIStackView!
    
    func manageCardStacks() {
        showBackOfAllCards()
        // Rotate the figures on the back of the cards
        for cardButton in leftModelCardButtons {
            cardButton.titleLabel?.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        }
        for cardButton in topModelCardButtons {
            cardButton.titleLabel?.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }
        for cardButton in rightModelCardButtons {
            cardButton.titleLabel?.transform = CGAffineTransform(rotationAngle:  -CGFloat.pi / 2)
        }
    }
    
    func showBackOfAllCards() {
        for cardButtonCollection in [playerCardButtons, leftModelCardButtons, topModelCardButtons, rightModelCardButtons] {
            for cardButton in cardButtonCollection! {
                showBackOfCard(for: cardButton)
            }
        }
    }
}


