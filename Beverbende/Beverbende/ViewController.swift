//
//  ViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 16/02/2021.
//

import UIKit

enum Actor {
    case player
    case leftModel
    case topModel
    case rightModel
    case game
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        showBackOfAllCards()
        view.bringSubviewToFront(animationViewTwo)
        view.bringSubviewToFront(animationViewOne)
//        showEmptyDrawnCardButtons()
//        showEmptyArea(for: discardPileButton)
//        showInspectButton()
        hideDrawnCardInfoButton()
        addCardGestures()
        
    }

    @IBOutlet weak var deckView: UIImageView!
    @IBOutlet weak var discardPileView: UIImageView!
    
    @IBOutlet weak var inspectButton: UIButton!
    
    @IBOutlet var playerCardViews: [UIImageView]!
    @IBOutlet var leftModelCardViews: [UIImageView]!
    @IBOutlet var topModelCardViews: [UIImageView]!
    @IBOutlet var rightModelCardViews: [UIImageView]!
    
    @IBOutlet weak var playerDrawnCardView: UIImageView!
    @IBOutlet weak var leftModelDrawnCardView: UIImageView!
    @IBOutlet weak var topModelDrawnCardView: UIImageView!
    @IBOutlet weak var rightModelDrawnCardView: UIImageView!
    
    @IBOutlet weak var drawnCardInfoButton: UIButton!
    
    @IBOutlet weak var animationViewOne: UIImageView!
    @IBOutlet weak var animationViewTwo: UIImageView!
    
    var draw = 0
    
    @objc func drawCard(_ recognizer: UITapGestureRecognizer) {
        print("constrains!")
        print(animationViewOne.constraints)
        switch recognizer.state {
        case .ended:
            animateCardDraw(by: .player)
        default:
            break
        }
        
    }
    
    @objc func tapDiscardPile(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            animateDiscardFromHand(by: .player)
        default:
            break
        }
    }
    
    var isFaceUp: Bool = false
    
    @objc func tapPlayerCard(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            print("here")
            if let chosenCardView = recognizer.view as? UIImageView {
                let cardIndex = playerCardViews.firstIndex(of: chosenCardView)
                switch cardIndex {
                case 0:
                    print("tradeOnHand")
                    animateTradeOnHand(withCardAtIndex: 1, by: .player)
                case 1:
                    print("cardTrade")
                    animateCardTrade(ofCardAtIndex: 1, by: .player, withCardAtIndex: 3, from: .rightModel)
                default:
                    break
                }
                
            }
        default:
            break
        }
    }
    
    func showInspectButton() {
        initialInspection = false
        inspectButton.isHidden = false
        inspectButton.setTitle("Inspect", for: UIControl.State.normal)
        inspectButton.backgroundColor = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
        inspectButton.layer.cornerRadius = 10
    }
    
    var initialInspection = false
    
    @IBAction func touchInspectButton(_ sender: UIButton) {
        if initialInspection == false {
            initialInspection = true
            sender.setTitle("Hide", for: UIControl.State.normal)
            for index in [0, 3] { // the outer cards
                let cardView = playerCardViews[index]
                flipOpen(show: "4", on: cardView, for: .player)
            }
        } else {
            for index in [0, 3] {
                let cardView = playerCardViews[index]
                flipClosed(hide: cardView, for: .player)
            }
            sender.isHidden = true
        }
    }
    
    
    
    @IBOutlet weak var playerCardStack: UIStackView!
    @IBOutlet weak var leftCardStack: UIStackView!
    @IBOutlet weak var topCardStack: UIStackView!
    @IBOutlet weak var rightCardStack: UIStackView!
    
    func showBackOfAllCards() {
        showBackOfCard(on: deckView, for: .game)
        // Rotate the figures on the back of the cards
        for cardView in playerCardViews {
            showBackOfCard(on: cardView, for: .player )
        }
        for cardView in leftModelCardViews {
            showBackOfCard(on: cardView, for: .leftModel)
        }
        for cardView in topModelCardViews {
            showBackOfCard(on: cardView, for: .topModel)
        }
        for cardView in rightModelCardViews {
            showBackOfCard(on: cardView, for: .rightModel)
        }
    }
    
    func addCardGestures() {
        
        deckView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(drawCard(_:))))
        deckView.isUserInteractionEnabled = true
        discardPileView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDiscardPile(_:))))
        discardPileView.isUserInteractionEnabled = true
        
        for cardView in playerCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPlayerCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
//        for cardView in leftModelCardViews {
//            showBackOfCard(for: cardView, at: .left)
//        }
//        for cardView in topModelCardViews {
//            showBackOfCard(for: cardView, at: .top)
////            cardView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
//        }
//        for cardView in rightModelCardViews {
//            showBackOfCard(for: cardView, at: .right)
////            cardView.transform = CGAffineTransform(rotationAngle:  -CGFloat.pi / 2)
//        }
    }

    func showFrontOfCard(show value: String, on cardView: UIImageView, for actor: Actor) {
        let frontImage = UIImage(named: value)!
        
        let orientedImage = UIImage(cgImage: frontImage.cgImage!,
                                    scale: frontImage.scale,
                                    orientation: returnCardOrientation(for: actor))
        
        cardView.image = orientedImage
    }

    func showBackOfCard(on cardView: UIImageView, for actor: Actor){
        let backImage = UIImage(named: "back")!
        
        let orientedImage = UIImage(cgImage: backImage.cgImage!,
                                    scale: backImage.scale,
                                    orientation: returnCardOrientation(for: actor))
        
        cardView.image = orientedImage
    }

    func returnCardOrientation(for actor: Actor) -> UIImage.Orientation {
        switch actor {
        case .leftModel:
            return .right
        case .rightModel:
            return .left
        case .topModel:
            return .down
        case .player:
            return .up
        case .game:
            return .up
        }
    }

    func hideDrawnCardInfoButton() {
        drawnCardInfoButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        drawnCardInfoButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        drawnCardInfoButton.setTitle("", for: UIControl.State.normal)
        drawnCardInfoButton.setImage(UIImage(systemName: "info.circle"), for: UIControl.State.normal)
        drawnCardInfoButton.isHidden = true
    }
    
    // ############################ ANIMATIONS ############################
    
    func retrieveOverlayConstraints(set animationView: UIImageView, to targetView: UIImageView) -> [NSLayoutConstraint] {
        var constraintCollection: [NSLayoutConstraint] = []
        for attribute in [NSLayoutConstraint.Attribute.centerX, .centerY] { //, .height, .width
            let newConstraint = NSLayoutConstraint(item: animationView,
                                          attribute: attribute,
                                          relatedBy: .equal,
                                          toItem: targetView,
                                          attribute: attribute,
                                          multiplier: CGFloat(1),
                                          constant: CGFloat(0))
            constraintCollection.append(newConstraint)
        }
        return constraintCollection
    }
    
    func setViewToOverlay(set animationView: UIImageView, to targetView: UIImageView, deactivateAfter: Bool = true) -> [NSLayoutConstraint] {
        //without animation
        let overlayConstraints = retrieveOverlayConstraints(set: animationView, to: targetView)
        NSLayoutConstraint.activate(overlayConstraints)
        animationView.image = targetView.image
        animationView.superview?.layoutIfNeeded()
        if deactivateAfter {
            NSLayoutConstraint.deactivate(overlayConstraints)
            return []
        } else {
            return overlayConstraints
        }
    }
    
    func setViewToOverlayDouble(set animationView1: UIImageView, to targetView1: UIImageView, andSet animationView2: UIImageView, to targetView2: UIImageView) {
        // function for trades
        let startOverlayConstraints1 = setViewToOverlay(set: animationViewOne, to: targetView1, deactivateAfter: false)
        let startOverlayConstraints2 = setViewToOverlay(set: animationViewTwo, to: targetView2, deactivateAfter: false)
        self.animationViewOne.superview?.layoutIfNeeded()
        NSLayoutConstraint.deactivate(startOverlayConstraints1)
        NSLayoutConstraint.deactivate(startOverlayConstraints2)
    }
    
    func flipOpen(show value: String, on cardView: UIImageView, for actor: Actor){
        var flipFrom: UIView.AnimationOptions {
            switch actor {
            case .leftModel:
                return .transitionFlipFromRight
            case .rightModel:
                return .transitionFlipFromLeft
            case .player:
                return .transitionFlipFromTop
            case .topModel:
                return .transitionFlipFromBottom
            case .game:
                return .transitionFlipFromBottom
            }
        }
        
        UIView.transition(with: cardView,
                          duration: 0.6,
                          options: flipFrom,
                          animations: {
                            self.showFrontOfCard(show: "4", on: cardView, for: actor)
                          },
                          completion: nil
        )
    }
    
    func flipClosed(hide cardView: UIImageView, for actor: Actor){
        var flipFrom: UIView.AnimationOptions {
            switch actor {
            case .leftModel:
                return .transitionFlipFromLeft
            case .rightModel:
                return .transitionFlipFromRight
            case .player:
                return .transitionFlipFromBottom
            case .topModel:
                return .transitionFlipFromTop
            default:
                return .transitionFlipFromBottom
            }
        }
        
        UIView.transition(with: cardView,
                          duration: 0.6,
                          options: flipFrom,
                          animations: {
                            self.showBackOfCard(on: cardView, for: actor)
                          },
                          completion: nil
        )
    }
    
//    func animateMovingClosedCard(from viewA: UIImageView, to viewB: UIImageView, using animationView: UIImageView, withDuration dur: Double) {
//        _ = setViewToOverlay(set: animationView, to: viewA)
//        let overlayConstraints = retrieveOverlayConstraints(set: animationView, to: viewB)
//        NSLayoutConstraint.activate(overlayConstraints)
//        UIView.transition(with: animationView,
//                          duration: dur,
//                          options: [.curveEaseInOut],
//                          animations: {
//                            animationView.superview?.layoutIfNeeded()
//                          }, completion: {_ in
//                            animationView.image = nil
//                          } )
//        NSLayoutConstraint.deactivate(overlayConstraints)
//    }
    
    func retrieveOnHandCardView(for actor: Actor) -> UIImageView {
        switch actor {
        case .player:
            return playerDrawnCardView
        case .leftModel:
            return leftModelDrawnCardView
        case .rightModel:
            return rightModelDrawnCardView
        case .topModel:
            return topModelDrawnCardView
        case .game:
            exit(0)
        }
    }
    
    func animateCardDraw(by actor: Actor) {
//        from the deck to an onHand location
        let onHandCardView = retrieveOnHandCardView(for: actor)
        
        _ = setViewToOverlay(set: animationViewOne, to: deckView)
        let overlayConstraints = retrieveOverlayConstraints(set: animationViewOne, to: onHandCardView)
        NSLayoutConstraint.activate(overlayConstraints)
        
        UIView.transition(with: animationViewOne,
                          duration: 1,
                          options: [.curveEaseInOut],
                          animations: {
                            self.animationViewOne.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.animationViewOne.image = nil
                            self.showBackOfCard(on: onHandCardView, for: actor)
                          } )
        NSLayoutConstraint.deactivate(overlayConstraints)
        
        if actor == .player {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.01) {
                self.flipOpen(show: "4", on: onHandCardView, for: actor)
            }
        }
        
    }

    func animateDiscardFromHand(by actor: Actor) {
        let onHandView = retrieveOnHandCardView(for: actor)
        
        var delayInSeconds = 0.0
        
        if actor != .player{
            flipOpen(show: "4", on: onHandView, for: actor)
            delayInSeconds = 0.61
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
            _ = self.setViewToOverlay(set: self.animationViewOne, to: onHandView)
            onHandView.image = nil
            
            let overlayConstraints = self.retrieveOverlayConstraints(set: self.animationViewOne, to: self.discardPileView)
            NSLayoutConstraint.activate(overlayConstraints)
            
            UIView.transition(with: self.animationViewOne,
                              duration: 1,
                              options: [.curveEaseInOut],
                              animations: {
                                self.animationViewOne.superview?.layoutIfNeeded()
                              }, completion: {_ in
                                self.animationViewOne.image = nil
                                self.showFrontOfCard(show: "4", on: self.discardPileView, for: .game)
                              }
            )
            NSLayoutConstraint.deactivate(overlayConstraints)
        }
    }
    
    func retrieveOnTableCardViews(for actor: Actor, withIndex cardIndex: Int) -> UIImageView {
        switch actor {
        case .player:
            return playerCardViews[cardIndex]
        case .leftModel:
            return leftModelCardViews[cardIndex]
        case .rightModel:
            return rightModelCardViews[cardIndex]
        case .topModel:
            return topModelCardViews[cardIndex]
        case .game:
            exit(0)
        }
    }
    
    func prepareAnimationFromViewToView(from view1: UIImageView, to view2: UIImageView) {
    }
    
    func animateCardTrade(ofCardAtIndex cardIndex1: Int, by actor1: Actor, withCardAtIndex cardIndex2: Int, from actor2: Actor) {
        // Trade cars between Actors
        let cardView1 = retrieveOnTableCardViews(for: actor1, withIndex: cardIndex1)
        let cardView2 = retrieveOnTableCardViews(for: actor2, withIndex: cardIndex2)
        
        setViewToOverlayDouble(set: animationViewOne, to: cardView1, andSet: animationViewTwo, to: cardView2)
        
        cardView1.image = nil//.isHidden does not work as these are in a stackView
        cardView2.image = nil
        
        let endOverlayConstraints1 = retrieveOverlayConstraints(set: animationViewOne, to: cardView2)
        let endOverlayConstraints2 = retrieveOverlayConstraints(set: animationViewTwo, to: cardView1)

        NSLayoutConstraint.activate(endOverlayConstraints1)
        NSLayoutConstraint.activate(endOverlayConstraints2)
        
        UIView.transition(with: animationViewOne,
                          duration: 1,
                          options: [.curveEaseInOut],
                          animations: {
                            self.animationViewOne.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.showBackOfCard(on: cardView1, for: actor1)
                            self.showBackOfCard(on: cardView2, for: actor2)
                            self.animationViewOne.image = nil
                            self.animationViewTwo.image = nil
                          }
        )
        NSLayoutConstraint.deactivate(endOverlayConstraints1)
        NSLayoutConstraint.deactivate(endOverlayConstraints2)
    }
//
    func animateTradeOnHand(withCardAtIndex cardIndex: Int, by actor: Actor) {
//        trade the drawn card with one of your own (for either model or player)
        
        let onHandCardView = retrieveOnHandCardView(for: actor)
        if actor == .player {
            flipClosed(hide: onHandCardView, for: actor)
        }
        
        let onTableCardView = retrieveOnTableCardViews(for: actor, withIndex: cardIndex)
        flipOpen(show: "4", on: onTableCardView, for: actor)
        
        let delayInSeconds = 0.61
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {

            self.setViewToOverlayDouble(set: self.animationViewOne, to: onHandCardView, andSet: self.animationViewTwo, to: onTableCardView)
            
            onHandCardView.image = nil
            onTableCardView.image = nil
            
            let OverlayConstraints1 = self.retrieveOverlayConstraints(set: self.animationViewOne, to: onTableCardView)
            let OverlayConstraints2 = self.retrieveOverlayConstraints(set: self.animationViewTwo, to: self.discardPileView)
            
            NSLayoutConstraint.activate(OverlayConstraints1)
            NSLayoutConstraint.activate(OverlayConstraints2)
            
            UIView.animate(withDuration: 1,
                           delay: 0,
                           options: [.curveEaseInOut],
                           animations: {
                            self.animationViewOne.superview?.layoutIfNeeded()
                           },
                           completion: {_ in
                            self.animationViewOne.image = nil
                            self.animationViewTwo.image = nil
                            self.showBackOfCard(on: onTableCardView, for: actor)
                            self.showFrontOfCard(show: "4", on: self.discardPileView, for: actor)
                           })

            NSLayoutConstraint.deactivate(OverlayConstraints1)
            NSLayoutConstraint.deactivate(OverlayConstraints2)

        }
        
        
    }
}

