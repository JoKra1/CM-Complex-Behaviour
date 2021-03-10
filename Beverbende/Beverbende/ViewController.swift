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
    
    var discardPileSelected: Bool = false
    var selectedForPlayerIndex: Int?
    var selectedForModelAtIndex: (Actor, Int)?
    
    func endUserTurn() {
        _ = game.nextPlayer()
        isUserTurn = false
    }
    
    @objc func drawCard(_ recognizer: UITapGestureRecognizer) {
        print("constrains!")
//        print(animationViewThree.constraints)
        switch recognizer.state {
        case .ended:
            if isUserTurn, user.getCardOnHand() == nil {
                _ = game.drawCard(for: user)
            }
        default:
            break
        }
    }
    
    @objc func tapDiscardPile(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if isUserTurn {
                if user.getCardOnHand() != nil { // discard drawn card
                    game.discardDrawnCard(for: user)
                    endUserTurn()
                } else { //user.getCardOnHand() == nil, get into the process of trading with the discarded pile
                    if let cardIndex = selectedForPlayerIndex { // the user already selected one of their own cards
                        game.tradeDiscardedCardWithCard(at: cardIndex, for: user)
                        discardPileSelected = false
                        selectedForPlayerIndex = nil
                        endUserTurn()
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
    
    func handleCardSelectionForPlayer(forView cardView: UIImageView, withIndex cardIndex: Int) {
        if let selectedIndex = selectedForPlayerIndex, selectedIndex == cardIndex { // the touched card was already selected so deselect it
            cardView.alpha = 1
            selectedForPlayerIndex = nil
        } else { // set the touched card as selected, doesnt matter if another one was already selected or not
            playerCardViews.forEach { $0.alpha = 1 }
            cardView.alpha = 0.5
            selectedForPlayerIndex = cardIndex
        }
    }
    
    func handleCardSelectionForModel(forModel actor: Actor, forView cardView: UIImageView, withIndex cardIndex: Int) {
        if let selectedIndex = selectedForPlayerIndex, selectedIndex == cardIndex { // the touched card was already selected so deselect it
            cardView.alpha = 1
            selectedForPlayerIndex = nil
        } else { // set the touched card as selected, doesnt matter if another one was already selected or not
            retrieveOnTableCardViews(for: actor).forEach { $0.alpha = 1 }
            cardView.alpha = 0.5
            selectedForModelAtIndex = (actor, cardIndex)
        }
    }
    
    @objc func tapPlayerCard(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let touchedCardView = recognizer.view as? UIImageView {
                let TouchedCardIndex = playerCardViews.firstIndex(of: touchedCardView)!
                
                if user.getCardOnHand() == nil { // prcoess of trading with the discarded pile
                    if discardPileSelected { // the discarded pile was already selected
                        game.tradeDiscardedCardWithCard(at: TouchedCardIndex, for: user)
                        discardPileSelected = false
                        selectedForPlayerIndex = nil
                        endUserTurn()
                    } else { // handle selection of the player's cards
                        handleCardSelectionForPlayer(forView: touchedCardView, withIndex: TouchedCardIndex)
                    }
                } else { // user.getCardOnHand() != nil, a card was already drawn
                    switch user.getCardOnHand()?.getType() {
                    case .value:
                        game.tradeDrawnCardWithCard(at: TouchedCardIndex, for: user)
                        endUserTurn()
                    case .action:
                        let actionCard = user.getCardOnHand()! as! ActionCard
                        switch actionCard.getAction() {
                        case .inspect:
                            _ = game.inspectCard(at: TouchedCardIndex, for: user)
                            game.moveCardBackFromHand(to: TouchedCardIndex, for: user)
                            endUserTurn()
                        case .swap:
                            if let (selectedModel, selectedForModelIndex) = selectedForModelAtIndex {
                                // TODO: do the trade, Loran adds this to the game model first
                                selectedForPlayerIndex = nil
                                selectedForModelAtIndex = nil
                                endUserTurn()
                            } else { // handle selection of the player's cards
                                handleCardSelectionForPlayer(forView: touchedCardView, withIndex: TouchedCardIndex)
                            }
                        case .twice:
                            // TODO: implement, perhaps a counter??
                            print("hoi")
                        }
                    default:
                        break
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
                if let selectedPlayerIndex = selectedForPlayerIndex {
                    // TODO: do the trade, Loran adds this to the game model first
                    selectedForPlayerIndex = nil
                    selectedForModelAtIndex = nil
                    endUserTurn()
                } else { // handle selection of the model's cards
                    handleCardSelectionForModel(forModel: touchedModel, forView: touchedCardView, withIndex: touchedCardIndex)
                }
            }
        default:
            break
        }
    }
    
    func findActorAndIndexForView(for cardView: UIImageView) -> (Actor, Int) {
        if let cardIndex = leftModelCardViews.firstIndex(of: cardView){
            return (.leftModel, cardIndex)
        } else if let cardIndex = rightModelCardViews.firstIndex(of: cardView){
            return (.rightModel, cardIndex)
        } else if let cardIndex = topModelCardViews.firstIndex(of: cardView) {
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
                let cardView = playerCardViews[index]
                let value = getStringMatchingWithCard(forCard: user.getCardsOnTable()[index]!)
                flipOpen(show: value, on: cardView, for: .player)
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
            showBackOfCard(on: cardView, for: .player)
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
        for cardView in leftModelCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapModelCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
        for cardView in topModelCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapModelCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
        for cardView in rightModelCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapModelCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
    }

    func showFrontOfCard(show value: String, on cardView: UIImageView, for actor: Actor) {
        let frontImage = UIImage(named: value)!
        
        let orientedImage = UIImage(cgImage: frontImage.cgImage!,
                                    scale: frontImage.scale,
                                    orientation: returnImageOrientation(for: actor))
        
        cardView.image = orientedImage
    }

    func showBackOfCard(on cardView: UIImageView, for actor: Actor){
        let backImage = UIImage(named: "back")!
        
        let orientedImage = UIImage(cgImage: backImage.cgImage!,
                                    scale: backImage.scale,
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
        case .player:
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
        case .player:
            return CGAffineTransform(rotationAngle: 0)
        case .game:
            return CGAffineTransform(rotationAngle: 0)
        }
    }

    func hideDrawnCardInfoButton() {
        drawnCardInfoButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        drawnCardInfoButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        drawnCardInfoButton.setTitle("", for: UIControl.State.normal)
        drawnCardInfoButton.setImage(UIImage(systemName: "info.circle"), for: UIControl.State.normal)
        drawnCardInfoButton.isHidden = true
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
    
    func flipOpen(show value: String, on cardView: UIImageView, for actor: Actor){
        var flipFrom: UIView.AnimationOptions {
            switch actor {
            case .leftModel:
                return .transitionFlipFromLeft
            case .rightModel:
                return .transitionFlipFromRight
            case .player:
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
    
    func flipClosed(hide cardView: UIImageView, for actor: Actor){
        var flipFrom: UIView.AnimationOptions {
            switch actor {
            case .leftModel:
                return .transitionFlipFromRight
            case .rightModel:
                return .transitionFlipFromLeft
            case .player:
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
        
        if actor == .player {
            duration += 1.01
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.01) {
                self.flipOpen(show: value, on: onHandCardView, for: actor)
            }
        }
        return duration + 0.01
    }
    
    func animateTradeFromDiscardPile(withCardAtIndex cardIndex: Int, fromValue: String, toValue: String, by actor: Actor) -> Double {
//        from the discard pile to an onHand location
        let onHandCardView = retrieveOnHandCardView(for: actor)
        
        animationViewOne.transform = returnRotationTransform(for: .game)
        _ = setViewToOverlay(set: animationViewOne, to: discardPileView)

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
        return 1 + 0.01 + 1.61 + 0.01
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
        case .player:
            return playerCardViews
        case .leftModel:
            return leftModelCardViews
        case .rightModel:
            return rightModelCardViews
        case .topModel:
            return topModelCardViews
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
        for cardView in playerCardViews {
            flipOpen(show: String(value), on: cardView, for: .player)
        }
        value += 1
        for cardView in leftModelCardViews {
            flipOpen(show: String(value), on: cardView, for: .leftModel)
        }
        value += 1
        for cardView in topModelCardViews {
            flipOpen(show: String(value), on: cardView, for: .topModel)
        }
        value += 1
        for cardView in rightModelCardViews {
            flipOpen(show: String(value), on: cardView, for: .rightModel)
        }
        return 0.61
    }

    // ############################ EVENT HANDLING ############################
    
    var isUserTurn = true // user starts the game
    
    func handleEvent(for event: EventType, with info: [String : Any]) {
        let player = info["player"] as! Player
        if player.getId() == user.getId() {
            if event == .nextTurn { // start animating all the models actions
                if let (firstEvent, firstInfo) = eventQueue.dequeue() {
                    animateEvent(for: firstEvent, with: firstInfo)
                    isUserTurn = true
                } else { print("there should be events in the eventQueueueue") }
            } else {
                animateEvent(for: event, with: info) // imediatelly animate the user's actions
            }
        } else { // event not pertaining to the user, but to a model
            eventQueue.enqueue(element: (event, info))
        }
    }
    
    func animateEvent(for event: EventType, with info: [String : Any]) {
//        Actor is the UI complement to the Player class
        disableUserInteraction()
        var duration = 0.0
        
        switch event {
        case .cardDrawn: // info: ["player": Player]
            let player = info["player"] as! Player
            let card = info["card"] as! Card
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let cardValue = getStringMatchingWithCard(forCard: card)
            duration = animateCardDraw(by: actor, withValue: cardValue)
    
        case .cardDiscarded:// info: ["player": Player]
            let player = info["player"] as! Player
            let card = info["card"] as! Card
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let value = getStringMatchingWithCard(forCard: card)
            let openOnHand = !(info["isFaceUp"] as! Bool)
            duration = animateDiscardFromHand(by: actor, withValue: value, openOnHand: openOnHand)
        
        case .cardPlayed: // info: ["player": Player, "card": ActionCard]
            let player = info["player"] as! Player
            let actionCard = info["card"] as! ActionCard
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let value = getStringMatchingWithCard(forCard: actionCard)
            flipOpen(show: value, on: retrieveOnHandCardView(for: actor), for: actor)
            duration = 0.61
        
        case .cardsSwapped: // ["cardIndex1": Int, "player1": Player, "cardIndex2": Int, "player2" Player]
            let player1 = info["player1"] as! Player
            let player2 = info["player2"] as! Player
            let cardIndex1 = info["cardIndex1"] as! Int
            let cardIndex2 = info["cardIndex2"] as! Int
            let actor1 = findActorMatchingWithPLayer(withId: player1.getId())
            let actor2 = findActorMatchingWithPLayer(withId: player2.getId())
            duration = animateCardTrade(ofCardAtIndex: cardIndex1, by: actor1, withCardAtIndex: cardIndex2, from: actor2)
        
        case .cardReplaced: // ["player": Player, "cardFromPlayer":Card, "cardFromPlayerIndex": Int,  "toIsFaceUp":Bool]
            let player = info["player"] as! Player
            let cardFromPlayer = info["cardFromPlayer"] as! Card
            let cardFromPlayerIndex = info["cardFromPlayerIndex"] as! Int
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let closeOnHand = (info["toIsFaceUp"] as! Bool)
            duration = animateTradeOnHand(withCardAtIndex: cardFromPlayerIndex, by: actor, withValue: getStringMatchingWithCard(forCard: cardFromPlayer), closeOnHand: closeOnHand)
            
        case .discardedCardTraded: // ["player": Player, "CardToPlayer": Card, "cardFromPlayer": Card, "cardFromPlayerIndex": Int]
            let player = info["player"] as! Player
            let cardFromPlayer = info["cardFromPlayer"] as! Card
            let cardFromPlayerIndex = info["cardFromPlayerIndex"] as! Int
            let cardToPlayer = info["cardToPlayer"] as! Card
            let actor = findActorMatchingWithPLayer(withId: player.getId())
            let fromValue = getStringMatchingWithCard(forCard: cardFromPlayer)
            let toValue = getStringMatchingWithCard(forCard: cardToPlayer)
            duration = animateTradeFromDiscardPile(withCardAtIndex: cardFromPlayerIndex, fromValue: fromValue, toValue: toValue, by: actor)
        default:
            break
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
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
            return .player
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

