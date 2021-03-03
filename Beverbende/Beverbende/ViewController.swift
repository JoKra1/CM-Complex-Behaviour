//
//  ViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 16/02/2021.
//

import UIKit

enum CardLocation {
    case bottom
    case left
    case right
    case top
    case central
}

enum Actor {
    case player
    case leftModel
    case topModel
    case rightModel
    
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        showBackOfAllCards()
        animationCardView.isHidden = true
        view.bringSubviewToFront(animationCardView)
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
    @IBOutlet weak var toptModelDrawnCardView: UIImageView!
    @IBOutlet weak var rightModelDrawnCardView: UIImageView!
    
    @IBOutlet weak var drawnCardInfoButton: UIButton!
    
    @IBOutlet weak var animationCardView: UIImageView!
    
    var draw = 0
    
//    @objc func drawCard(_ recognizer: UITapGestureRecognizer) {
//            print("new call")
//            switch recognizer.state {
//            case .ended:
//                deckViewLocationConstraints.forEach { constraint in constraint.isActive = false; print(constraint) }
//                deckToDrawnLocationConstraints[.player]!.forEach { constraint in constraint.isActive = true; print(constraint) }
//                UIView.transition(with: self.deckView,
//                                  duration: 1,
//                                  options: [.transitionFlipFromBottom, .curveEaseInOut],
//                                  animations: {
//                                    self.deckView.superview?.layoutIfNeeded()
//                                    self.showFrontOfNumberCard(show: String(self.draw), on: self.deckView, at: .central)
//                                  }, completion: { _ in
//                                    print("complete")
//                                    self.showFrontOfNumberCard(show: String(self.draw), on: self.playerDrawnCardView, at: .bottom)
//                                    self.showBackOfCard(for: self.deckView, at: .central)
//                                    self.draw += 1
//                                  })
//
//                self.deckView.superview?.layoutIfNeeded()
//                print("old2")
//            default:
//                break
//            }
    //        }
    
    @objc func drawCard(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            animateMovingCard(from: deckView, to: playerDrawnCardView, withDuration: 1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showFrontOfNumberCard(show: String(self.draw), on: self.playerDrawnCardView, at: .bottom)
                self.draw += 1
            }
        default:
            break
        }
        
    }
    
    @objc func tapDiscardPile(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            print("tapDiscarPile()")
                animateMovingCard(from: playerDrawnCardView, to: discardPileView, withDuration: 1)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.showFrontOfNumberCard(show: String(self.draw), on: self.discardPileView, at: .central)
                }
                
        default:
            break
        }
    }
    
    func animateMovingCard(from viewA: UIImageView, to viewB: UIImageView, withDuration dur: Double) {
        
        print(animationCardView.constraints)
        var fromConstraintCollection: [NSLayoutConstraint] = []
        for attribute in [NSLayoutConstraint.Attribute.centerX, .centerY] {
            let newConstraint = NSLayoutConstraint(item: animationCardView!,
                                          attribute: attribute,
                                          relatedBy: .equal,
                                          toItem: viewA,
                                          attribute: attribute,
                                          multiplier: CGFloat(1),
                                          constant: CGFloat(0))
            fromConstraintCollection.append(newConstraint)
        }
        NSLayoutConstraint.activate(fromConstraintCollection)
        self.animationCardView.superview?.layoutIfNeeded()
        self.animationCardView.isHidden = false
        self.animationCardView.image = viewA.image
        
        NSLayoutConstraint.deactivate(fromConstraintCollection)
        print(animationCardView.constraints)
        var toConstraintCollection: [NSLayoutConstraint] = []
        for attribute in [NSLayoutConstraint.Attribute.centerX, .centerY] {
            let newConstraint = NSLayoutConstraint(item: animationCardView!,
                                          attribute: attribute,
                                          relatedBy: .equal,
                                          toItem: viewB,
                                          attribute: attribute,
                                          multiplier: CGFloat(1),
                                          constant: CGFloat(0))
            toConstraintCollection.append(newConstraint)
        }
        NSLayoutConstraint.activate(toConstraintCollection)
        UIView.transition(with: animationCardView,
                          duration: dur,
                          options: [.curveEaseInOut],
                          animations: {
                            self.animationCardView.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.animationCardView.isHidden = true
                          } )
        NSLayoutConstraint.deactivate(toConstraintCollection)
    }
    
    var isFaceUp: Bool = false
    
    @objc func tapPlayerCard(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let chosenCardView = recognizer.view as? UIImageView {
                print("constraints")
                print(chosenCardView.constraints)
                if isFaceUp {
                    flipClosed(hide: chosenCardView, at: .bottom)
                    isFaceUp = !isFaceUp
                } else {
                    flipOpen(show: "4", on: chosenCardView, at: .bottom)
                    isFaceUp = !isFaceUp
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
                flipOpen(show: "4", on: cardView, at: .bottom)
            }
        } else {
            for index in [0, 3] {
                let cardView = playerCardViews[index]
                flipClosed(hide: cardView, at: .bottom)
            }
            sender.isHidden = true
        }
    }
    
    func flipOpen(show value: String, on cardView: UIImageView, at position: CardLocation){
        
        var flipFrom: UIView.AnimationOptions {
            switch position {
            case .left:
                return .transitionFlipFromRight
            case .right:
                return .transitionFlipFromLeft
            case .bottom:
                return .transitionFlipFromTop
            case .top:
                return .transitionFlipFromBottom
            case .central:
                return .transitionFlipFromTop
            }
        }
        
        UIView.transition(with: cardView,
                          duration: 0.6,
                          options: flipFrom,
                          animations: {
                            self.showFrontOfNumberCard(show: "4", on: cardView, at: position)
                          },
                          completion: nil
        )
    }
    
    func flipClosed(hide cardView: UIImageView, at position: CardLocation){
        
        var flipFrom: UIView.AnimationOptions {
            switch position {
            case .left:
                return .transitionFlipFromLeft
            case .right:
                return .transitionFlipFromRight
            case .bottom:
                return .transitionFlipFromBottom
            case .top:
                return .transitionFlipFromTop
            case .central:
                return .transitionFlipFromBottom
            }
        }
        
        UIView.transition(with: cardView,
                          duration: 0.6,
                          options: flipFrom,
                          animations: {
                            self.showBackOfCard(for: cardView, at: position)
                          },
                          completion: nil
        )
    }
    
    @IBOutlet weak var playerCardStack: UIStackView!
    @IBOutlet weak var leftCardStack: UIStackView!
    @IBOutlet weak var topCardStack: UIStackView!
    @IBOutlet weak var rightCardStack: UIStackView!
    
    func showBackOfAllCards() {
//        showBackOfAllCards()
        showBackOfCard(for: deckView, at: .central)
        // Rotate the figures on the back of the cards
        for cardView in playerCardViews {
            showBackOfCard(for: cardView, at: .bottom)
        }
        for cardView in leftModelCardViews {
            showBackOfCard(for: cardView, at: .left)
        }
        for cardView in topModelCardViews {
            showBackOfCard(for: cardView, at: .top)
//            cardView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }
        for cardView in rightModelCardViews {
            showBackOfCard(for: cardView, at: .right)
//            cardView.transform = CGAffineTransform(rotationAngle:  -CGFloat.pi / 2)
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
//
    func showFrontOfNumberCard(show value: String, on cardView: UIImageView, at position: CardLocation) {
        let frontImage = UIImage(named: value)!
        
        let orientedImage = UIImage(cgImage: frontImage.cgImage!,
                                    scale: frontImage.scale,
                                    orientation: returnCardOrientation(at: position))
        
        cardView.image = orientedImage
    }
//
//    func showFrontOfActionCard(show value: String, on cardButton: UIButton) {
//        // implement this for various action cards
//    }
//
    func showBackOfCard(for cardView: UIImageView, at position: CardLocation){
        let backImage = UIImage(named: "back")!
        
        let orientedImage = UIImage(cgImage: backImage.cgImage!,
                                    scale: backImage.scale,
                                    orientation: returnCardOrientation(at: position))
        
        cardView.image = orientedImage
    }

    func returnCardOrientation(at position: CardLocation) -> UIImage.Orientation {
        switch position {
        case .left:
            return .right
        case .right:
            return .left
        case .top:
            return .down
        case .bottom:
            return .up
        case .central:
            return .up
        }
    }

//    func showEmptyArea(for cardButton : UIButton) {
//        cardButton.setTitle("", for: UIControl.State.normal)
//        cardButton.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0)
//        cardButton.layer.cornerRadius = 10
//        cardButton.layer.borderWidth = 3
//        cardButton.layer.borderColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
//    }
//
    func hideDrawnCardInfoButton() {
        drawnCardInfoButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        drawnCardInfoButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        drawnCardInfoButton.setTitle("", for: UIControl.State.normal)
        drawnCardInfoButton.setImage(UIImage(systemName: "info.circle"), for: UIControl.State.normal)
        drawnCardInfoButton.isHidden = true
    }
    
    // my constraint factory
    func runConstraintFactory() -> [Actor:[NSLayoutConstraint]] {
        // center to drawn card area position constaint
        var centerToDrawnConstraints: [Actor:[NSLayoutConstraint]] = [:]
        
        for (constraintCollectionName, toItem) in [Actor.player:playerDrawnCardView, Actor.leftModel:leftModelDrawnCardView, Actor.topModel:toptModelDrawnCardView, Actor.rightModel:rightModelDrawnCardView] {
                var newConstraintCollection: [NSLayoutConstraint] = []
                for attribute in [NSLayoutConstraint.Attribute.centerX, .centerY] {
                    let newConstraint = NSLayoutConstraint(item: deckView!,
                                                  attribute: attribute,
                                                  relatedBy: .equal,
                                                  toItem: toItem,
                                                  attribute: attribute,
                                                  multiplier: CGFloat(1),
                                                  constant: CGFloat(0))
                    newConstraintCollection.append(newConstraint)
                }
            centerToDrawnConstraints[constraintCollectionName] = newConstraintCollection
        }
        return centerToDrawnConstraints
    }
    
    var deckToDrawnLocationConstraints: [Actor:[NSLayoutConstraint]] { return runConstraintFactory() }
    
}

