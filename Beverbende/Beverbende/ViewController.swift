//
//  ViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 16/02/2021.
//

import UIKit

enum Actor {
    case user
    case leftModel
    case topModel
    case rightModel
    case game
}

class ViewController: UIViewController, BeverbendeDelegate {
    
    var user = User(with: "user")
    lazy var game = Beverbende(with: user, cognitiveIds: ["left", "top", "right"])
    
    var eventQueue = Queue<(EventType, [String: Any])>()
            
    var animationViewOne: UIImageView = {
        let theImageView = UIImageView()
        theImageView.image = nil
        theImageView.contentMode = .scaleAspectFit
        theImageView.clipsToBounds = true
        theImageView.translatesAutoresizingMaskIntoConstraints = false //You need to call this property so the image is added to your view
        
        return theImageView
        }()
    
    var animationViewTwo: UIImageView = {
        let theImageView = UIImageView()
        theImageView.image = nil
        theImageView.contentMode = .scaleAspectFit
        theImageView.clipsToBounds = true
        theImageView.translatesAutoresizingMaskIntoConstraints = false //You need to call this property so the image is added to your view
        return theImageView
        }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showBackOfAllCards()
        view.addSubview(animationViewOne)
        view.addSubview(animationViewTwo)
        sizeUpAnimationViews()
        view.bringSubviewToFront(animationViewTwo)
        view.bringSubviewToFront(animationViewOne)
//        showEmptyDrawnCardButtons()
//        showEmptyArea(for: discardPileButton)
//        showInspectButton()
        hideDrawnCardInfoButton()
        addCardGestures()
        
        self.game.add(delegate: self)
        let discardePileValue = getStringMatchingWithCard(forCard: game.discardPile.peek()!)
        showFrontOfCard(show: discardePileValue, on: discardPileView, for: .game)
    }

    @IBOutlet weak var deckView: UIImageView!
    @IBOutlet weak var discardPileView: UIImageView!
    
    @IBOutlet weak var inspectButton: UIButton!
    
    @IBOutlet var userOnTableCardViews: [UIImageView]!
    @IBOutlet var leftModelOnTableCardViews: [UIImageView]!
    @IBOutlet var topModelOnTableCardViews: [UIImageView]!
    @IBOutlet var rightModelOnTableCardViews: [UIImageView]!
    
    @IBOutlet weak var userOnHandCardView: UIImageView!
    @IBOutlet weak var leftModelOnHandCardView: UIImageView!
    @IBOutlet weak var topModelOnHandCardView: UIImageView!
    @IBOutlet weak var rightModelOnHandCardView: UIImageView!
    
    @IBOutlet weak var onHandCardInfoButton: UIButton!
    
    var discardPileSelected: Bool = false
    var selectedForUserIndex: Int? = nil
    var selectedForModelAtIndex: (Actor, Int)? = nil
    
    var playedAction: Action?
    
    func endUserTurn() {
        isUserTurn = false
        discardPileSelected = false
        playedAction = nil
        selectedForUserIndex = nil
        selectedForModelAtIndex = nil
    }
    
    @objc func drawCard(_ recognizer: UITapGestureRecognizer) {
        print("constrains!")
//        print(animationViewThree.constraints)
        switch recognizer.state {
        case .ended:
            if isUserTurn, user.getCardOnHand() == nil, (playedAction == nil || playedAction == .twice) {
                _ = game.drawCard(for: user)
                var drawn = user.getCardOnHand()!
                drawn.isFaceUp = true
                undoCardSelections()
            }
        default:
            break
        }
    }
    
    @objc func tapDiscardPile(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if isUserTurn {
                if let onHandCard = user.getCardOnHand() { // discard drawn card
                    switch onHandCard.getType() {
                    case .value:
                        playedAction == .twice ? playedAction = nil : endUserTurn() // a discard does not end the turn if the draw twice action card was played
                    case .action:
                        let actionCard = onHandCard as! ActionCard
                        playedAction = actionCard.getAction()
                    }
                    game.discardDrawnCard(for: user)
                } else { //user.getCardOnHand() == nil, get into the process of trading with the discarded pile
                    if let cardIndex = selectedForUserIndex { // the user already selected one of their own cards
                        undoCardSelections()
                        endUserTurn()
                        game.tradeDiscardedCardWithCard(at: cardIndex, for: user)
                    } else { // toggle between selected and not
                        discardPileView.alpha = (discardPileSelected) ? 1 : 0.5
                        discardPileSelected = !discardPileSelected
                    }
                }
            }
        default:
            break
        }
    }
    
    var isFaceUp: Bool = false
    
    func handleCardSelectionForUser(forView cardView: UIImageView, withIndex cardIndex: Int) {
        if let selectedIndex = selectedForUserIndex, selectedIndex == cardIndex { // the touched card was already selected so deselect it
            cardView.alpha = 1
            selectedForUserIndex = nil
        } else { // set the touched card as selected, doesnt matter if another one was already selected or not
            userOnTableCardViews.forEach { $0.alpha = 1 }
            cardView.alpha = 0.5
            selectedForUserIndex = cardIndex
        }
    }
    
    func handleCardSelectionForModel(forModel actor: Actor, forView cardView: UIImageView, withIndex cardIndex: Int) {
        if let selectedIndex = selectedForUserIndex, selectedIndex == cardIndex { // the touched card was already selected so deselect it
            cardView.alpha = 1
            selectedForUserIndex = nil
        } else { // set the touched card as selected, doesnt matter if another one was already selected or not
            leftModelOnTableCardViews.forEach { $0.alpha = 1 }
            rightModelOnTableCardViews.forEach { $0.alpha = 1 }
            topModelOnTableCardViews.forEach { $0.alpha = 1 }
            cardView.alpha = 0.5
            selectedForModelAtIndex = (actor, cardIndex)
        }
    }
    
    func undoCardSelections(){
        discardPileView.alpha = 1
        userOnTableCardViews.forEach { $0.alpha = 1 }
        leftModelOnTableCardViews.forEach { $0.alpha = 1 }
        rightModelOnTableCardViews.forEach { $0.alpha = 1 }
        topModelOnTableCardViews.forEach { $0.alpha = 1 }
    }
    
    @objc func tapUserCard(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let touchedCardView = recognizer.view as? UIImageView , isUserTurn {
                let touchedCardIndex = userOnTableCardViews.firstIndex(of: touchedCardView)!
                
                if let action = playedAction {
                    switch action {
                    case .inspect:
                        endUserTurn()
                        _ = game.inspectCard(at: touchedCardIndex, for: user)
                        game.moveCardBackFromHand(to: touchedCardIndex, for: user) // in order to comply with the "mental card moving around" done by the model
                    case .swap:
                        if let (selectedModel, selectedForModelIndex) = selectedForModelAtIndex {
                            undoCardSelections()
                            endUserTurn()
                            let otherPlayer = findPlayerMatchingWithActor(for: selectedModel)
                            game.swapCards(cardAt: touchedCardIndex, for: user, withCardAt: selectedForModelIndex, for: otherPlayer)
                        } else { // handle selection of the player's cards
                            handleCardSelectionForUser(forView: touchedCardView, withIndex: touchedCardIndex)
                        }
                    case .twice:
                        switch user.getCardOnHand()?.getType() {
                        case .value:
                            endUserTurn()
                            game.tradeDrawnCardWithCard(at: touchedCardIndex, for: user)
                        case .action:
                            // nothing should happen here, the player first had to discard the action card to play it
                            break
                        default:
                            break
                        }
                    }
                } else { // there was no action card played
                    if user.getCardOnHand() == nil { // prcoess of trading with the discarded pile
                        if discardPileSelected { // the discarded pile was already selected
                            endUserTurn()
                            game.tradeDiscardedCardWithCard(at: touchedCardIndex, for: user)
                            undoCardSelections()
                        } else { // handle selection of the player's cards
                            handleCardSelectionForUser(forView: touchedCardView, withIndex: touchedCardIndex)
                        }
                    } else { // user.getCardOnHand() != nil, a card was already drawn
                        switch user.getCardOnHand()?.getType() {
                        case .value:
                            endUserTurn()
                            game.tradeDrawnCardWithCard(at: touchedCardIndex, for: user)
                        case .action:
                            // nothing should happen here, the player first had to discard the action card to play it
                            break
                        default:
                            break
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    func disableUserInteraction(){
        view.isUserInteractionEnabled = false
    }
    
    func enableUserInteractionAfterDelay(lasting delay: Double) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @objc func tapModelCard(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let touchedCardView = recognizer.view as? UIImageView {
                let (touchedModel, touchedCardIndex) = findActorAndIndexForView(for: touchedCardView)
                if playedAction == .swap { // the action card had to be played for this to work
                    if let selectedUserIndex = selectedForUserIndex {
                        // TODO: do the trade, Loran adds this to the game model first
                        undoCardSelections()
                        endUserTurn()
                        let otherPlayer = findPlayerMatchingWithActor(for: touchedModel)
                        game.swapCards(cardAt: selectedUserIndex, for: user, withCardAt: touchedCardIndex, for: otherPlayer)
                    } else { // handle selection of the model's cards
                        handleCardSelectionForModel(forModel: touchedModel, forView: touchedCardView, withIndex: touchedCardIndex)
                    }
                }
            }
        default:
            break
        }
    }
    
    func findActorAndIndexForView(for cardView: UIImageView) -> (Actor, Int) {
        if let cardIndex = leftModelOnTableCardViews.firstIndex(of: cardView){
            return (.leftModel, cardIndex)
        } else if let cardIndex = rightModelOnTableCardViews.firstIndex(of: cardView){
            return (.rightModel, cardIndex)
        } else if let cardIndex = topModelOnTableCardViews.firstIndex(of: cardView) {
            return (.topModel, cardIndex)
        } else {
            print("the selected UIImageView does not belong to any of the models. return (Actor.game, 0)")
            return (.game, 0)
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
                let cardView = userOnTableCardViews[index]
                let value = getStringMatchingWithCard(forCard: user.getCardsOnTable()[index]!)
                flipOpen(show: value, on: cardView, for: .user)
            }
        } else {
            for index in [0, 3] {
                let cardView = userOnTableCardViews[index]
                flipClosed(hide: cardView, for: .user)
            }
            sender.isHidden = true
        }
    }
    
    @IBOutlet weak var userCardStack: UIStackView!
    @IBOutlet weak var leftCardStack: UIStackView!
    @IBOutlet weak var topCardStack: UIStackView!
    @IBOutlet weak var rightCardStack: UIStackView!
    
    func showBackOfAllCards() {
        showBackOfCard(on: deckView, for: .game)
        // Rotate the figures on the back of the cards
        for cardView in userOnTableCardViews {
            showBackOfCard(on: cardView, for: .user)
        }
        for cardView in leftModelOnTableCardViews {
            showBackOfCard(on: cardView, for: .leftModel)
        }
        for cardView in topModelOnTableCardViews {
            showBackOfCard(on: cardView, for: .topModel)
        }
        for cardView in rightModelOnTableCardViews {
            showBackOfCard(on: cardView, for: .rightModel)
        }
    }
    
    func addCardGestures() {
        
        deckView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(drawCard(_:))))
        deckView.isUserInteractionEnabled = true
        discardPileView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDiscardPile(_:))))
        discardPileView.isUserInteractionEnabled = true
        
        for cardView in userOnTableCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUserCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
        for cardView in leftModelOnTableCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapModelCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
        for cardView in topModelOnTableCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapModelCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
        for cardView in rightModelOnTableCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapModelCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
    }

    func showFrontOfCard(show value: String, on cardView: UIImageView, for actor: Actor) {
        let frontImage = UIImage(named: value) ?? UIImage(named: "empty")
        
        let orientedImage = UIImage(cgImage: frontImage!.cgImage!,
                                    scale: frontImage!.scale,
                                    orientation: returnImageOrientation(for: actor))
        
        cardView.image = orientedImage
    }

    func showBackOfCard(on cardView: UIImageView, for actor: Actor){
        let backImage = UIImage(named: "back") ?? UIImage(named: "empty")
        
        let orientedImage = UIImage(cgImage: backImage!.cgImage!,
                                    scale: backImage!.scale,
                                    orientation: returnImageOrientation(for: actor))
        
        cardView.image = orientedImage
    }

    func returnImageOrientation(for actor: Actor) -> UIImage.Orientation {
        switch actor {
        case .leftModel:
            return .right
        case .rightModel:
            return .left
        case .topModel:
            return .down
        case .user:
            return .up
        case .game:
            return .up
        }
    }
    
    func returnRotationTransform(for actor: Actor) -> CGAffineTransform {
        switch actor {
        case .leftModel:
            return CGAffineTransform(rotationAngle: CGFloat.pi/2)
        case .rightModel:
            return CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        case .topModel:
            return CGAffineTransform(rotationAngle: CGFloat.pi)
        case .user:
            return CGAffineTransform(rotationAngle: 0)
        case .game:
            return CGAffineTransform(rotationAngle: 0)
        }
    }

    func hideDrawnCardInfoButton() {
        onHandCardInfoButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        onHandCardInfoButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        onHandCardInfoButton.setTitle("", for: UIControl.State.normal)
        onHandCardInfoButton.setImage(UIImage(systemName: "info.circle"), for: UIControl.State.normal)
        onHandCardInfoButton.isHidden = true
    }
    
    func sizeUpAnimationViews() {
        NSLayoutConstraint.activate([animationViewOne.widthAnchor.constraint(equalTo: deckView.widthAnchor),
                                     animationViewOne.heightAnchor.constraint(equalTo: deckView.heightAnchor),
                                     animationViewTwo.widthAnchor.constraint(equalTo: deckView.widthAnchor),
                                     animationViewTwo.heightAnchor.constraint(equalTo: deckView.heightAnchor),
                                     ])
    }
    
    
    // ############################ ANIMATIONS ############################
    
    func retrieveOverlayConstraints(set animationView: UIImageView, to targetView: UIImageView) -> [NSLayoutConstraint] {
        return [animationView.centerXAnchor.constraint(equalTo: targetView.centerXAnchor),
                animationView.centerYAnchor.constraint(equalTo: targetView.centerYAnchor)]
    }
    
    func setViewToOverlay(set animationView: UIImageView, to targetView: UIImageView, deactivateAfter: Bool = true) -> [NSLayoutConstraint] {
        //without animation
        print("begin setViewToOVerlay()")
        let overlayConstraints = retrieveOverlayConstraints(set: animationView, to: targetView)
        NSLayoutConstraint.activate(overlayConstraints)
        animationView.image = UIImage(cgImage: (targetView.image?.cgImage)!, scale: 1, orientation: .up)
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
    
    func flipOpen(show value: String, on cardView: UIImageView, for actor: Actor) {
        var flipFrom: UIView.AnimationOptions {
            switch actor {
            case .leftModel:
                return .transitionFlipFromLeft
            case .rightModel:
                return .transitionFlipFromRight
            case .user:
                return .transitionFlipFromTop
            case .topModel:
                return .transitionFlipFromBottom
            case .game:
                return .transitionFlipFromTop
            }
        }
        
        UIView.transition(with: cardView,
                          duration: 0.6,
                          options: flipFrom,
                          animations: {
                            self.showFrontOfCard(show: value, on: cardView, for: actor)
                          },
                          completion: nil
        )
    }
    
    func flipClosed(hide cardView: UIImageView, for actor: Actor) {
        var flipFrom: UIView.AnimationOptions {
            switch actor {
            case .leftModel:
                return .transitionFlipFromRight
            case .rightModel:
                return .transitionFlipFromLeft
            case .user:
                return .transitionFlipFromBottom
            case .topModel:
                return .transitionFlipFromTop
            case .game:
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

    func retrieveOnHandCardView(for actor: Actor) -> UIImageView {
        switch actor {
        case .user:
            return userOnHandCardView
        case .leftModel:
            return leftModelOnHandCardView
        case .rightModel:
            return rightModelOnHandCardView
        case .topModel:
            return topModelOnHandCardView
        case .game:
            exit(0)
        }
    }
    
    func animateCardInspection(for actor: Actor, withCardAtIndex cardIndex: Int, withValue value: String) -> Double {
        let cardView = retrieveOnTableCardViews(for: actor)[cardIndex]
        
        var duration: Double
        
        if actor == .user {
            duration = 0.61 * 2 + 1 // time to: flip open, flip closed, inspect
            flipOpen(show: value, on: cardView, for: actor)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.61 + 1) {
                self.flipClosed(hide: cardView, for: actor)
            }
        } else { // model
            duration = 1.01
            
            animationViewOne.transform = returnRotationTransform(for: actor)
            _ = setViewToOverlay(set: animationViewOne, to: cardView)
            
            var preventRotation: CGAffineTransform {
                switch actor {
                case .leftModel:
                    return returnRotationTransform(for: .leftModel)
                case .rightModel:
                    return returnRotationTransform(for: .rightModel)
                default: //case .topModel:
                    return CGAffineTransform(rotationAngle: CGFloat.pi) // needs work
                }
            }
            
            UIView.transition(with: animationViewOne,
                              duration: 1.0,
                              options: [.curveEaseInOut],
                              animations: {
                                self.animationViewOne.transform = CGAffineTransform(scaleX: 4, y: 4)
                                self.animationViewOne.transform = preventRotation // apparantly needed?
                              }, completion: {_ in
                                self.animationViewOne.image = nil
                              }
            )
        }
        return duration
    }
    
    func animateCardDraw(by actor: Actor, withValue value: String) -> Double {
//        from the deck to an onHand location
        
        var duration = 1.0

        let onHandCardView = retrieveOnHandCardView(for: actor)
        
        animationViewOne.transform = returnRotationTransform(for: .game)
        _ = setViewToOverlay(set: animationViewOne, to: deckView)

        let overlayConstraints = retrieveOverlayConstraints(set: animationViewOne, to: onHandCardView)
        NSLayoutConstraint.activate(overlayConstraints)
        
        UIView.transition(with: animationViewOne,
                          duration: 1,
                          options: [.curveEaseInOut],
                          animations: {
                            self.animationViewOne.transform = self.returnRotationTransform(for: actor)
                            self.animationViewOne.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.animationViewOne.image = nil
                            self.showBackOfCard(on: onHandCardView, for: actor)
                          } )
        NSLayoutConstraint.deactivate(overlayConstraints)
        
        if actor == .user {
            duration += 0.01 + 0.61
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.01) {
                self.flipOpen(show: value, on: onHandCardView, for: actor)
            }
        }
        return duration + 0.01
    }
    
    func animateTradeFromDiscardPile(withCardAtIndex cardIndex: Int, fromValue: String, toValue: String, tempDiscardPileValue: String, by actor: Actor) -> Double {
//        from the discard pile to an onHand location
        let onHandCardView = retrieveOnHandCardView(for: actor)
        
        animationViewOne.transform = returnRotationTransform(for: .game)
        _ = setViewToOverlay(set: animationViewOne, to: discardPileView)
        
        showFrontOfCard(show: tempDiscardPileValue, on: discardPileView, for: .game)

        let overlayConstraints = retrieveOverlayConstraints(set: animationViewOne, to: onHandCardView)
        NSLayoutConstraint.activate(overlayConstraints)
        
        UIView.transition(with: animationViewOne,
                          duration: 1,
                          options: [.curveEaseInOut],
                          animations: {
                            self.animationViewOne.transform = self.returnRotationTransform(for: actor)
                            self.animationViewOne.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.animationViewOne.image = nil
                            self.showFrontOfCard(show: toValue, on: onHandCardView, for: actor)
                          } )
        NSLayoutConstraint.deactivate(overlayConstraints)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.01) {
            _ = self.animateTradeOnHand(withCardAtIndex: cardIndex, by: actor, withValue: fromValue, closeOnHand: true)
        }
        return 1 + 0.01 + 0.61 + 1.0 + 0.01 //time to move from pile, then to flip, then to move again
    }

    func animateDiscardFromHand(by actor: Actor, withValue value: String, openOnHand: Bool) -> Double {
        var duration = 1.0
        var delay = 0.0
        
        let onHandView = retrieveOnHandCardView(for: actor)
        
        if openOnHand {
            flipOpen(show: value, on: onHandView, for: actor)
            delay = 0.61
            duration += delay
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            self.animationViewOne.transform = self.returnRotationTransform(for: actor)
            _ = self.setViewToOverlay(set: self.animationViewOne, to: onHandView)
            onHandView.image = nil

            let overlayConstraints = self.retrieveOverlayConstraints(set: self.animationViewOne, to: self.discardPileView)
            NSLayoutConstraint.activate(overlayConstraints)

            UIView.transition(with: self.animationViewOne,
                              duration: 1,
                              options: [.curveEaseInOut],
                              animations: {
                                self.animationViewOne.transform = self.returnRotationTransform(for: .game)
                                self.animationViewOne.superview?.layoutIfNeeded()
                              }, completion: {_ in
                                self.animationViewOne.image = nil
                                self.showFrontOfCard(show: value, on: self.discardPileView, for: .game)
                              }
            )
            NSLayoutConstraint.deactivate(overlayConstraints)
        }
        
        return duration + 0.01
    }
    
    func retrieveOnTableCardViews(for actor: Actor) -> [UIImageView] {
        switch actor {
        case .user:
            return userOnTableCardViews
        case .leftModel:
            return leftModelOnTableCardViews
        case .rightModel:
            return rightModelOnTableCardViews
        case .topModel:
            return topModelOnTableCardViews
        case .game:
            exit(0)
        }
    }

    func animateTradeOnHand(withCardAtIndex cardIndex: Int, by actor: Actor, withValue value: String, closeOnHand: Bool) -> Double {
//        trade the drawn card with one of your own (for either model or player)
        
        let onHandCardView = retrieveOnHandCardView(for: actor)
        
        if closeOnHand {
            flipClosed(hide: onHandCardView, for: actor)
        }
        
        let onTableCardView = retrieveOnTableCardViews(for: actor)[cardIndex]
        flipOpen(show: value, on: onTableCardView, for: actor)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.61) { // delay due to card flip(s)
            
            self.animationViewOne.transform = self.returnRotationTransform(for: actor)
            self.animationViewTwo.transform = self.returnRotationTransform(for: actor)
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
                            self.animationViewOne.transform = self.returnRotationTransform(for: actor)
                            self.animationViewTwo.transform = self.returnRotationTransform(for: .game)
                            self.animationViewOne.superview?.layoutIfNeeded()
                           },
                           completion: {_ in
                            self.animationViewOne.image = nil
                            self.animationViewTwo.image = nil
                            self.showBackOfCard(on: onTableCardView, for: actor)
                            self.showFrontOfCard(show: value, on: self.discardPileView, for: .game)
                           })

            NSLayoutConstraint.deactivate(OverlayConstraints1)
            NSLayoutConstraint.deactivate(OverlayConstraints2)

        }
        return 1.61 + 0.01
    }
    
    func animateCardTrade(ofCardAtIndex cardIndex1: Int, by actor1: Actor, withCardAtIndex cardIndex2: Int, from actor2: Actor) -> Double {
        // Trade cars between Actors
        let cardView1 = retrieveOnTableCardViews(for: actor1)[cardIndex1]
        let cardView2 = retrieveOnTableCardViews(for: actor2)[cardIndex2]
        
        self.animationViewOne.transform = self.returnRotationTransform(for: actor1)
        self.animationViewTwo.transform = self.returnRotationTransform(for: actor2)
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
                            self.animationViewOne.transform = self.returnRotationTransform(for: actor2)
                            self.animationViewTwo.transform = self.returnRotationTransform(for: actor1)
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
        
        return 1.0 + 0.01 // duration
    }
    
    func flipOpenAllCards() -> Double {
        var value = 0
        for cardView in userOnTableCardViews {
            flipOpen(show: String(value), on: cardView, for: .user)
        }
        value += 1
        for cardView in leftModelOnTableCardViews {
            flipOpen(show: String(value), on: cardView, for: .leftModel)
        }
        value += 1
        for cardView in topModelOnTableCardViews {
            flipOpen(show: String(value), on: cardView, for: .topModel)
        }
        value += 1
        for cardView in rightModelOnTableCardViews {
            flipOpen(show: String(value), on: cardView, for: .rightModel)
        }
        return 0.61
    }

    // ############################ EVENT HANDLING ############################
    
    var isUserTurn = true // user starts the game
    
    func handleEvent(for event: EventType, with info: [String : Any]) {
        print("incoming event: \(event)")
        let player = info["player"] as! Player
        if player.getId() == user.getId() {
            if event == .nextTurn { // start animating once all models done their thing
                if let (firstEvent, firstInfo) = eventQueue.dequeue() {
                        self.animateEvent(for: firstEvent, with: firstInfo)
                        self.isUserTurn = true
                } else { print("there should be events in the eventQueueueue") }
            } else {
                animateEvent(for: event, with: info) // imediatelly animate the user's actions
            }
        } else {
            eventQueue.enqueue(element: (event, info))
        }
    }
    
    func tryProgressGameFromUser(forAnimationWithDuration duration: Double, testFor player: Player) {
        /*
         This function determines when not only the players actions, but also the acompanying animations, are done, before the the game progresses to the first model
         */
        if player.getId() == user.getId(), !isUserTurn { // isUserTurn is set false when the player performs his last gesture/action
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration + 1) {
                _ = self.game.nextPlayer()
            }
        }
    }
    
    func animateEvent(for event: EventType, with info: [String : Any]) {
//        Actor is the UI complement to the Player class, will be discarded at some time
        disableUserInteraction()
        var duration = 0.0
        
        print("ANIMATION START")
        print("WITH EVENT: \(event)")
        
        var player = info["player"] as! Player
        
        switch event {
        case .cardDrawn: // info: ["player": Player]
            let card = info["card"] as! Card
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let cardValue = getStringMatchingWithCard(forCard: card)
            duration = animateCardDraw(by: actor, withValue: cardValue)
    
        case .cardDiscarded:// info: ["player": Player]
            let card = info["card"] as! Card
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let value = getStringMatchingWithCard(forCard: card)
            let openOnHand = !(info["isFaceUp"] as! Bool)
            duration = animateDiscardFromHand(by: actor, withValue: value, openOnHand: openOnHand)
            
        case .discardedCardDrawn: // only ever issued by model, if followed by a trade, then the model chose to trade with discarded
            let cardToPlayer = info["card"] as! Card
            let tempTopOfDeckCard = info["topOfDeckCard"] as! Card
            if let (nextEvent, nextInfo) = self.eventQueue.dequeue() {
                if nextEvent == .cardTraded { // ["player": Player, "cardFromPlayer":Card, "cardFromPlayerIndex": Int, "toIsFaceUp":Bool]
                    player = nextInfo["player"] as! Player
                    let cardFromPlayer = nextInfo["cardFromPlayer"] as! Card
                    let cardFromPlayerIndex = nextInfo["cardFromPlayerIndex"] as! Int
                    let actor = findActorMatchingWithPLayer(withId: player.getId())
                    let fromValue = getStringMatchingWithCard(forCard: cardFromPlayer)
                    let toValue = getStringMatchingWithCard(forCard: cardToPlayer)
                    let tempDiscardPileValue = getStringMatchingWithCard(forCard: tempTopOfDeckCard)
                    duration = animateTradeFromDiscardPile(withCardAtIndex: cardFromPlayerIndex, fromValue: fromValue, toValue: toValue, tempDiscardPileValue: tempDiscardPileValue, by: actor)
                }
            } else { print("I expected another event after a discarded card being drawn by the model") }
        
//        case .cardPlayed: // info: ["player": Player, "card": ActionCard]
//            let actionCard = info["card"] as! ActionCard
//            let actor = findActorMatchingWithPLayer(withId: player.getId())
//            let value = getStringMatchingWithCard(forCard: actionCard)
//            flipOpen(show: value, on: retrieveOnHandCardView(for: actor), for: actor)
//            duration = 0.61
        
        case .cardsSwapped: // ["cardIndex1": Int, "player1": Player, "cardIndex2": Int, "player2" Player]
            let player2 = info["player2"] as! Player
            let cardIndex1 = info["cardIndex"] as! Int
            let cardIndex2 = info["cardIndex2"] as! Int
            let actor1 = findActorMatchingWithPLayer(withId: player.getId())
            let actor2 = findActorMatchingWithPLayer(withId: player2.getId())
            duration = animateCardTrade(ofCardAtIndex: cardIndex1, by: actor1, withCardAtIndex: cardIndex2, from: actor2)
        
        case .cardTraded: // ["player": Player, "cardFromPlayer":Card, "cardFromPlayerIndex": Int,  "toIsFaceUp":Bool]
            let cardFromPlayer = info["cardFromPlayer"] as! Card
            let cardFromPlayerIndex = info["cardFromPlayerIndex"] as! Int
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let closeOnHand = (info["toIsFaceUp"] as! Bool)
            duration = animateTradeOnHand(withCardAtIndex: cardFromPlayerIndex, by: actor, withValue: getStringMatchingWithCard(forCard: cardFromPlayer), closeOnHand: closeOnHand)
            
        case .discardedCardTraded: // ["player": Player, "CardToPlayer": Card, "cardFromPlayer": Card, "cardFromPlayerIndex": Int]
            // only ever issued by model
            let cardFromPlayer = info["cardFromPlayer"] as! Card
            let cardFromPlayerIndex = info["cardFromPlayerIndex"] as! Int
            let cardToPlayer = info["cardToPlayer"] as! Card
            let tempTopOfDeckCard = info["topOfDeckCard"] as! Card
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let fromValue = getStringMatchingWithCard(forCard: cardFromPlayer)
            let toValue = getStringMatchingWithCard(forCard: cardToPlayer)
            let tempDiscardPileValue = getStringMatchingWithCard(forCard: tempTopOfDeckCard)
            duration = animateTradeFromDiscardPile(withCardAtIndex: cardFromPlayerIndex, fromValue: fromValue, toValue: toValue, tempDiscardPileValue: tempDiscardPileValue, by: actor)
            
        case .cardInspected: // ["player": Player, "card": Card, "cardIndex": Int]
            let card = info["card"] as! Card
            let cardIndex = info["cardIndex"] as! Int
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let value = getStringMatchingWithCard(forCard: card)
            duration = animateCardInspection(for: actor, withCardAtIndex: cardIndex, withValue: value)
            
        case .nextTurn:
            duration = 2
            
        default:
            duration = 0
        }
        
        tryProgressGameFromUser(forAnimationWithDuration: duration, testFor: player)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
            print("ANIMATION END")
            if let (nextEvent, nextInfo) = self.eventQueue.dequeue() { // there is a next event in the queue
                self.animateEvent(for: nextEvent, with: nextInfo)
            } else { // the eventQueue is empty (during player turn, or at the end of all animations for the models)
                self.enableUserInteractionAfterDelay(lasting: 0)
            }
        }
        
    }
    
    func findActorMatchingWithPLayer(withId playerId: String) -> Actor {
        switch playerId {
        case "user":
            return .user
        case "left":
            return .leftModel
        case "right":
            return .rightModel
        case "top":
            return .topModel
        default:
            print("this ID does not belong to a user as specified")
            return .game
        }
    }
    
    func findPlayerMatchingWithActor(for actor: Actor) -> Player {
        switch actor {
        case .user:
            return user
        case .leftModel:
            return game.players[1]
        case .topModel:
            return game.players[2]
        case .rightModel:
            return game.players[3]
        default:
            return user
        }
    }
    
    func getStringMatchingWithCard(forCard card: Card) -> String {
        switch card.getType() {
        case .value:
            let valueCard = card as! ValueCard
            return String(valueCard.getValue())
        case .action:
            let actionCard = card as! ActionCard
            switch actionCard.getAction() {
            case .inspect:
                return "inspect"
            case .swap:
                return "swap"
            case .twice:
                return "twice"
            }
        }
    }

}

