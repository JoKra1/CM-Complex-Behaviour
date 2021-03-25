//
//  ViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 16/02/2021.
//

import UIKit

class ViewController: UIViewController, BeverbendeDelegate {
    
    var user = User(with: "user")
    lazy var game = Beverbende(with: user, cognitiveIds: ["left", "top", "right"])
            
    var animationViewOne: UIImageView = {
        let theImageView = UIImageView()
        theImageView.image = nil
        theImageView.contentMode = .scaleToFill
        theImageView.clipsToBounds = true
        theImageView.translatesAutoresizingMaskIntoConstraints = false //You need to call this property so the image is added to your view
        return theImageView
        }()
    
    var animationViewTwo: UIImageView = {
        let theImageView = UIImageView()
        theImageView.image = nil
        theImageView.contentMode = .scaleToFill
        theImageView.clipsToBounds = true
        theImageView.translatesAutoresizingMaskIntoConstraints = false //You need to call this property so the image is added to your view
        return theImageView
        }()
    
    override func viewDidLoad() {
        print("ViewDidLoad()")
        super.viewDidLoad()
        showBackOfAllCards()
        view.addSubview(animationViewOne)
        view.addSubview(animationViewTwo)
        sizeUpAnimationViews()
        view.bringSubviewToFront(animationViewTwo)
        view.bringSubviewToFront(animationViewOne)
        afterTurnButtons.forEach { $0.isHidden = true}
        onHandCardInfoButton.isHidden = true
        leftKnockLabel.alpha = 0
        rightKnockLabel.alpha = 0
        topKnockLabel.alpha = 0
        addCardGestures()
        self.game.addSync(delegate: self)
        let discardePileValue = returnStringMatchingWithCard(forCard: game.discardPile.peek()!)
        showFrontOfCard(show: discardePileValue, on: discardPileView, for: user)
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
    var selectedForModelAtIndex: (Player, Int)? = nil
    
    var playedAction: Action?
    
    func endUserTurn() {
        isUserTurn = false
        discardPileSelected = false
        playedAction = nil
        selectedForUserIndex = nil
        selectedForModelAtIndex = nil
        onHandCardInfoButton.isHidden = true
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
                if user.getCardOnHand() != nil { // discard drawn card
                    onHandCardInfoButton.isHidden = true
                    playedAction == .twice ? playedAction = nil : endUserTurn() // a discard does not end the turn if the draw twice action card was played
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
    
    @objc func tapOnHandCard(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            if let onHandCard = user.getCardOnHand() { // activate action card
                onHandCardInfoButton.isHidden = true
                switch onHandCard.getType() {
                case .value:
                    break
                case .action:
                    let actionCard = onHandCard as! ActionCard
                    playedAction = actionCard.getAction()
                    game.discardDrawnCard(for: user)
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
    
    func handleCardSelectionForModel(forModel player: Player, forView cardView: UIImageView, withIndex cardIndex: Int) {
        if let selectedIndex = selectedForUserIndex, selectedIndex == cardIndex { // the touched card was already selected so deselect it
            cardView.alpha = 1
            selectedForUserIndex = nil
        } else { // set the touched card as selected, doesnt matter if another one was already selected or not
            leftModelOnTableCardViews.forEach { $0.alpha = 1 }
            rightModelOnTableCardViews.forEach { $0.alpha = 1 }
            topModelOnTableCardViews.forEach { $0.alpha = 1 }
            cardView.alpha = 0.5
            selectedForModelAtIndex = (player, cardIndex)
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
                            game.swapCards(cardAt: touchedCardIndex, for: user, withCardAt: selectedForModelIndex, for: selectedModel)
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
                let (touchedModel, touchedCardIndex) = returnPlayerAndIndexForView(for: touchedCardView)
                if playedAction == .swap { // the action card had to be played for this to work
                    if let selectedUserIndex = selectedForUserIndex {
                        // TODO: do the trade, Loran adds this to the game model first
                        undoCardSelections()
                        endUserTurn()
                        game.swapCards(cardAt: selectedUserIndex, for: user, withCardAt: touchedCardIndex, for: touchedModel)
                    } else { // handle selection of the model's cards
                        handleCardSelectionForModel(forModel: touchedModel, forView: touchedCardView, withIndex: touchedCardIndex)
                    }
                }
            }
        default:
            break
        }
    }
    
    @IBOutlet var afterTurnButtons: [UIButton]!
    
    @IBAction func endUserTurn(_ sender: UIButton) {
        afterTurnButtons.forEach { $0.isHidden = true }
        letModelsPlay()
        
    }
    
    @IBAction func knockOnTable(_ sender: Any) {
        afterTurnButtons.forEach { $0.isHidden = true }
        game.knock(from: user)
        letModelsPlay()
    }
    
    
    func letModelsPlay() {
        disableUserInteraction()
        userEndTime = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000
        let userElapsedTime = userEndTime - userStartTime - userAnimationsDuration
        print("USER ELAPSED TIME: \(userElapsedTime)")
        userStartTime = 0.0
        userEndTime = 0.0
        userAnimationsDuration = 0.0
        let modelLeftTime = game.nextPlayer(previous: userElapsedTime)
        let modelTopTime = game.nextPlayer(previous: modelLeftTime)
        let modelRightTime = game.nextPlayer(previous: modelTopTime)
        _ = game.nextPlayer(previous: modelRightTime)
        // the models have made all there moves and signaled that it is the users turn, time to animate the model actions (and the wrap up of the game, in case the game ends at the user)
        animateEventQueue()
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
                let value = returnStringMatchingWithCard(forCard: user.getCardsOnTable()[index]!)
                flipOpen(show: value, on: cardView, for: user)
            }
        } else {
            for index in [0, 3] {
                let cardView = userOnTableCardViews[index]
                flipClosed(hide: cardView, for: user)
                isUserTurn = true // the user can now play the rest of the game
            }
            userStartTime = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000
            sender.isHidden = true
        }
    }
    
    @IBOutlet weak var userCardStack: UIStackView!
    @IBOutlet weak var leftCardStack: UIStackView!
    @IBOutlet weak var topCardStack: UIStackView!
    @IBOutlet weak var rightCardStack: UIStackView!
    
    func showBackOfAllCards() {
        showBackOfCard(on: deckView, for: user)
        // Rotate the figures on the back of the cards
        for (playerIndex, cardViewCollection) in [userOnTableCardViews, leftModelOnTableCardViews, topModelOnTableCardViews, rightModelOnTableCardViews].enumerated() {
            for cardView in cardViewCollection! {
                showBackOfCard(on: cardView, for: game.players[playerIndex])
            }
        }
    }
    
    func addCardGestures() {
        deckView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(drawCard(_:))))
        deckView.isUserInteractionEnabled = true
        discardPileView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapDiscardPile(_:))))
        discardPileView.isUserInteractionEnabled = true
        userOnHandCardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapOnHandCard(_:))))
        userOnHandCardView.isUserInteractionEnabled = true
        
        for cardView in userOnTableCardViews {
            cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapUserCard(_:))))
            cardView.isUserInteractionEnabled = true
        }
        for cardViewCollection in [leftModelOnTableCardViews, topModelOnTableCardViews, rightModelOnTableCardViews] {
            for cardView in cardViewCollection! {
                cardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapModelCard(_:))))
                cardView.isUserInteractionEnabled = true
            }
        }
    }

    func sizeUpAnimationViews() {
        NSLayoutConstraint.activate([animationViewOne.widthAnchor.constraint(equalTo: deckView.widthAnchor),
                                     animationViewOne.heightAnchor.constraint(equalTo: deckView.heightAnchor),
                                     animationViewTwo.widthAnchor.constraint(equalTo: deckView.widthAnchor),
                                     animationViewTwo.heightAnchor.constraint(equalTo: deckView.heightAnchor),
                                     ])
    }

    // ############################ EVENT HANDLING ############################
    
    var isUserTurn = false // user starts the game, but first needs to inspect the cards, only then is it really its turn
    
    var eventQueue = Queue<Event>()
    
    var gameWrapUp = false
    
    var knockedBy: Player? = nil
    
    var userAnimationsDuration = 0.0
    var userStartTime = 0.0
    var userEndTime = 0.0
    
    func animateEventQueue() {
        if let firstEvent = eventQueue.dequeue() {
                _ = self.animateEvent(for: firstEvent)
                self.isUserTurn = true
        } else { print("there should be events in the eventQueueueue") }
    }
    
    func handleEvent(for type: EventType, with info: [String : Any]) {
        print("incoming event: \(type)")

        let event = Event(type: type, info: info)
        
        switch event.type {
        case .tradingLeftoverActionCards: // this needs separate management due to user related animations being added to the queueueueue
            gameWrapUp = true
        case let .knocked(player):
            knockedBy = player
        default:
            break
        }
        
        if gameWrapUp { // finishing of the game, trading all action cards for value cards from the pile
            eventQueue.enqueue(element: event) // these come in during the animation of the model's actions, fast enough not to be an issue i assume
        } else { // normal gameplay
            if let player = event.info["player"] as? Player {
                if player.getId() == user.getId() { // event relating to the user require the start of animation(s) (under certain conditions)
                    switch event.type {
                    case .knocked:
                        () // this case should not trigger the animations as the models are allowed to play first
                    case .nextTurn:
                        () // // this case should not trigger the animations as their should be no wait between the last model and the player
                    default:
                        let duration = animateEvent(for: event) // imediatelly animate the user's actions
                        userAnimationsDuration += duration
                    }
                } else {
                    eventQueue.enqueue(element: event) // add the model actions to the queue, wait with animation till the user's turn
                }
            }
        }
    }
    
    func tryProgressGameFromUser(forAnimationWithDuration duration: Double) {
        /*
         This function determines when not only the players actions, but also the acompanying animations, are done, the player then chooses to progress to the next player (e.i. the model to the left) or to knock and then progress)
         */
        if playerPlaceholder.getId() == user.getId(), !isUserTurn { // isUserTurn is set false when the player performs his last gesture/action
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                self.afterTurnButtons[0].isHidden = false //always show next turn button
                if self.knockedBy == nil {
                    self.afterTurnButtons[1].isHidden = false // only show when no one knocked already
                }
            }
        }
    }
    
    lazy var playerPlaceholder: Player = self.user
    
    func animateEvent(for event: Event) -> Double {
        disableUserInteraction()
        var duration = 0.0
        
        print("ANIMATION START")
        print("WITH EVENT: \(event)")
        
        switch event.type {
        case let .cardDrawn(player, card): // ["player": Player, "card": Card]
            playerPlaceholder = player
            let cardValue = returnStringMatchingWithCard(forCard: card)
            duration = animateCardDraw(by: player, withValue: cardValue)
    
        case let .cardDiscarded(player, card, isFaceUp): // ["player": Player, "card": Card, "isFaceUp":Bool]
            playerPlaceholder = player
            let value = returnStringMatchingWithCard(forCard: card)
            duration = animateDiscardFromHand(by: player, withValue: value, openOnHand: !isFaceUp)
            
        case let .discardedCardDrawn(player, cardToPlayer, topOfDeckCard): // only ever issued by model, if followed by a trade, then the model chose to trade with discarded
            playerPlaceholder = player
            if let nextEvent = self.eventQueue.dequeue() {
                switch nextEvent.type {
                case let .cardTraded(_, cardFromPlayer, cardFromPlayerIndex, _):
                    let fromValue = returnStringMatchingWithCard(forCard: cardFromPlayer)
                    let toValue = returnStringMatchingWithCard(forCard: cardToPlayer)
                    var tempDiscardPileValue: String? = nil
                    if topOfDeckCard != nil {
                        tempDiscardPileValue = returnStringMatchingWithCard(forCard: topOfDeckCard!)
                    }
                    duration = animateTradeFromDiscardPile(withCardAtIndex: cardFromPlayerIndex, fromValue: fromValue, toValue: toValue, tempDiscardPileValue: tempDiscardPileValue, by: player)
                default:
                    break
                }
            } else { print("I expected another event after a discarded card being drawn by the model") }
        
        case let .cardsSwapped(cardIndex1, player1, cardIndex2, player2): // ["cardIndex1": Int, "player": Player, "cardIndex": Int, "player2" Player]
            playerPlaceholder = player1
            duration = animateCardTrade(ofCardAtIndex: cardIndex1, by: player1, withCardAtIndex: cardIndex2, from: player2)
        
        case let .cardTraded(player, cardFromPlayer, cardFromPlayerIndex, toIsFaceUp): // ["player": Player, "cardFromPlayer":Card, "cardFromPlayerIndex": Int, "toIsFaceUp":Bool]
            playerPlaceholder = player
            duration = animateTradeOnHand(withCardAtIndex: cardFromPlayerIndex, by: player, withValue: returnStringMatchingWithCard(forCard: cardFromPlayer), closeOnHand: toIsFaceUp)
            
        case let .discardedCardTraded(player, cardToPlayer, cardFromPlayer, cardFromPlayerIndex, topOfDeckCard): // ["player": Player, "CardToPlayer": Card, "cardFromPlayer": Card, "cardFromPlayerIndex": Int]
            // only ever issued by model
            playerPlaceholder = player
            var tempDiscardPileValue: String? = nil
            if topOfDeckCard != nil {
                tempDiscardPileValue = returnStringMatchingWithCard(forCard: topOfDeckCard!)
            }
            let fromValue = returnStringMatchingWithCard(forCard: cardFromPlayer)
            let toValue = returnStringMatchingWithCard(forCard: cardToPlayer)
            duration = animateTradeFromDiscardPile(withCardAtIndex: cardFromPlayerIndex, fromValue: fromValue, toValue: toValue, tempDiscardPileValue: tempDiscardPileValue, by: player)
            
        case let .cardInspected(player, card, cardIndex): // ["player": Player, "card": Card, "cardIndex": Int]
            playerPlaceholder = player
            let value = returnStringMatchingWithCard(forCard: card)
            duration = animateCardInspection(by: player, withCardAtIndex: cardIndex, withValue: value)
            
        case let .nextTurn(player,_):
            playerPlaceholder = player
            duration = 0.6
            
        case let .knocked(player):
            playerPlaceholder = player
            print("knock by \(player.getId())")
            duration = animateKnock(by: player)
            
        case let .gameEnded(player):
            playerPlaceholder = player
            showWinner(for: player)
        default:
            playerPlaceholder = game.players[1]
            duration = 0.01
        }
        
        tryProgressGameFromUser(forAnimationWithDuration: duration)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
            print("ANIMATION END")
            if let nextEvent = self.eventQueue.dequeue() { // there is a next event in the queue
                _ = self.animateEvent(for: nextEvent)
            } else { // the eventQueue is empty (during player turn, or at the end of all animations for the models)
                if self.playerPlaceholder.getId() == self.game.players[3].getId() { // end of model animations signify the start of the models turn
                    self.userStartTime = Double(DispatchTime.now().uptimeNanoseconds) / 1000000000
                }
                self.enableUserInteractionAfterDelay(lasting: 0)
                print("USER INTERACTION ENABLED")
            }
        }
        
        return duration
    }
    
    func showWinner(for player: Player) {
        let winnerPopUp = UIAlertController(title: "End of the Game", message: "\(player.getId()) is the winner!", preferredStyle: .alert)
        
        winnerPopUp.addAction(UIAlertAction(title: "Exit to Menu", style: .cancel, handler: {_ in
                    print("winner was shown")
                    }))
        
        _ = flipOpenAllCards()
        
        present(winnerPopUp, animated: true)
    }
    
    // ############################ AUXILAIRIES ############################
    
    func returnOnHandCardView(for player: Player) -> UIImageView {
        switch player.getId() {
        case user.getId():
            return userOnHandCardView
        case game.players[1].getId():
            return leftModelOnHandCardView
        case game.players[2].getId():
            return topModelOnHandCardView
        case game.players[3].getId():
            return rightModelOnHandCardView
        default:
            print("There is no onHandCardView for this player")
            exit(0)
        }
    }
    
    func returnOnTableCardViews(for player: Player) -> [UIImageView] {
        switch player.getId() {
        case user.getId():
            return userOnTableCardViews
        case game.players[1].getId():
            return leftModelOnTableCardViews
        case game.players[2].getId():
            return topModelOnTableCardViews
        case game.players[3].getId():
            return rightModelOnTableCardViews
        default:
            print("There is no onTableCardView for this player")
            exit(0)
        }
    }
    
    func returnPlayerAndIndexForView(for cardView: UIImageView) -> (Player, Int) {
        if let cardIndex = leftModelOnTableCardViews.firstIndex(of: cardView){
            return (game.players[1], cardIndex)
        } else if let cardIndex = topModelOnTableCardViews.firstIndex(of: cardView) {
            return (game.players[2], cardIndex)
        } else if let cardIndex = rightModelOnTableCardViews.firstIndex(of: cardView){
            return (game.players[3], cardIndex)
        } else {
            print("the selected UIImageView does not belong to any of the models. return (Actor.game, 0)")
            return (user, 0)
        }
    }
    
    func returnStringMatchingWithCard(forCard card: Card) -> String {
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
    
    func returnImageOrientation(for player: Player) -> UIImage.Orientation {
        switch player.getId() {
        case game.players[1].getId():
            return .right
        case game.players[3].getId():
            return .left
        default:
            // for the decks in the center, the user, and the top model
            return .up
        }
    }
    
    func returnRotationTransform(for player: Player) -> CGAffineTransform {
        switch player.getId() {
        case game.players[1].getId():
            return CGAffineTransform(rotationAngle: CGFloat.pi/2)
        case game.players[3].getId():
            return CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        default:
            // for the decks in the center, the user, and the top model
            return CGAffineTransform(rotationAngle: 0)
        }
    }
    
    // ############################ SHOW CARD IMAGES ############################
    
    func showFrontOfCard(show value: String, on cardView: UIImageView, for player: Player) {
        let frontImage = UIImage(named: value) ?? UIImage(named: "empty")
        
        let orientedImage = UIImage(cgImage: frontImage!.cgImage!,
                                    scale: frontImage!.scale,
                                    orientation: returnImageOrientation(for: player))
        
        cardView.image = orientedImage
    }

    func showBackOfCard(on cardView: UIImageView, for player: Player){
        let backImage = UIImage(named: "back") ?? UIImage(named: "empty")
        
        let orientedImage = UIImage(cgImage: backImage!.cgImage!,
                                    scale: backImage!.scale,
                                    orientation: returnImageOrientation(for: player))
        
        cardView.image = orientedImage
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
        if targetView.image != nil {
            animationView.image = UIImage(cgImage: (targetView.image?.cgImage)!, scale: 1, orientation: .up)
        } else {
            animationView.image = UIImage(named: "empty")
        }
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
    
    func flipOpen(show value: String, on cardView: UIImageView, for player: Player) {
        var flipFrom: UIView.AnimationOptions {
            switch player.getId() {
            case game.players[1].getId():
                return .transitionFlipFromLeft
            case game.players[2].getId():
                return .transitionFlipFromBottom
            case game.players[3].getId():
                return .transitionFlipFromRight
            default: //user.getId()
                return .transitionFlipFromTop
            }
        }
        
        UIView.transition(with: cardView,
                          duration: 0.6,
                          options: flipFrom,
                          animations: {
                            self.showFrontOfCard(show: value, on: cardView, for: player)
                          },
                          completion: nil
        )
    }
    
    func flipClosed(hide cardView: UIImageView, for player: Player) {
        var flipFrom: UIView.AnimationOptions {
            switch player.getId() {
            case game.players[1].getId():
                return .transitionFlipFromRight
            case game.players[2].getId():
                return .transitionFlipFromTop
            case game.players[3].getId():
                return .transitionFlipFromLeft
            default: // user.getId()
                return .transitionFlipFromBottom
            }
        }
        
        UIView.transition(with: cardView,
                          duration: 0.6,
                          options: flipFrom,
                          animations: {
                            self.showBackOfCard(on: cardView, for: player)
                          },
                          completion: nil
        )
    }
    
    func animateCardInspection(by player: Player, withCardAtIndex cardIndex: Int, withValue value: String) -> Double {
        let cardView = returnOnTableCardViews(for: player)[cardIndex]
        
        var duration: Double
        
        if player.getId() == user.getId() {
            duration = 0.61 * 2 + 1 // time to: flip open, flip closed, inspect
            flipOpen(show: value, on: cardView, for: player)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.61 + 1) {
                self.flipClosed(hide: cardView, for: player)
            }
        } else { // model
            duration = 1.01
            
            animationViewOne.transform = returnRotationTransform(for: player)
            _ = setViewToOverlay(set: animationViewOne, to: cardView)
            
            UIView.transition(with: animationViewOne,
                              duration: 1.0,
                              options: [.curveEaseInOut],
                              animations: {
                                self.animationViewOne.transform = CGAffineTransform(scaleX: 4, y: 4)
                                self.animationViewOne.transform = self.returnRotationTransform(for: player)
                              }, completion: {_ in
                                self.animationViewOne.image = nil
                              }
            )
        }
        return duration
    }
    
    func animateCardDraw(by player: Player, withValue value: String) -> Double {
//        from the deck to an onHand location
        
        var duration = 1.0

        let onHandCardView = returnOnHandCardView(for: player)
        
        animationViewOne.transform = returnRotationTransform(for: user)
        _ = setViewToOverlay(set: animationViewOne, to: deckView)

        let overlayConstraints = retrieveOverlayConstraints(set: animationViewOne, to: onHandCardView)
        NSLayoutConstraint.activate(overlayConstraints)
        
        UIView.transition(with: animationViewOne,
                          duration: 1,
                          options: [.curveEaseInOut],
                          animations: {
                            self.animationViewOne.transform = self.returnRotationTransform(for: player)
                            self.animationViewOne.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.animationViewOne.image = nil
                            self.showBackOfCard(on: onHandCardView, for: player)
                          } )
        NSLayoutConstraint.deactivate(overlayConstraints)
        
        if player.getId() == user.getId(), !gameWrapUp {
            duration += 0.01 + 0.61
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.01) {
                self.flipOpen(show: value, on: onHandCardView, for: player)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.6) {
                    self.onHandCardInfoButton.isHidden = false
                }
            }
        }
        return duration + 0.01
    }
    
    func animateTradeFromDiscardPile(withCardAtIndex cardIndex: Int, fromValue: String, toValue: String, tempDiscardPileValue: String?, by player: Player) -> Double {
//        from the discard pile to an onHand location
        let onHandCardView = returnOnHandCardView(for: player)
        
        animationViewOne.transform = returnRotationTransform(for: user)
        _ = setViewToOverlay(set: animationViewOne, to: discardPileView)
        
        if tempDiscardPileValue != nil {
            showFrontOfCard(show: tempDiscardPileValue!, on: discardPileView, for: user)
        } else {
            discardPileView.image = nil
        }

        let overlayConstraints = retrieveOverlayConstraints(set: animationViewOne, to: onHandCardView)
        NSLayoutConstraint.activate(overlayConstraints)
        
        UIView.transition(with: animationViewOne,
                          duration: 1,
                          options: [.curveEaseInOut],
                          animations: {
                            self.animationViewOne.transform = self.returnRotationTransform(for: player)
                            self.animationViewOne.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.animationViewOne.image = nil
                            self.showFrontOfCard(show: toValue, on: onHandCardView, for: player)
                          } )
        NSLayoutConstraint.deactivate(overlayConstraints)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.01) {
            _ = self.animateTradeOnHand(withCardAtIndex: cardIndex, by: player, withValue: fromValue, closeOnHand: true)
        }
        return 1 + 0.01 + 0.61 + 1.0 + 0.01 //time to move from pile, then to flip, then to move again
    }

    func animateDiscardFromHand(by player: Player, withValue value: String, openOnHand: Bool) -> Double {
        var duration = 1.0
        var delay = 0.0
        
        let onHandView = returnOnHandCardView(for: player)
        
        if openOnHand {
            flipOpen(show: value, on: onHandView, for: player)
            delay = 0.61
            duration += delay
        }

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            self.animationViewOne.transform = self.returnRotationTransform(for: player)
            _ = self.setViewToOverlay(set: self.animationViewOne, to: onHandView)
            onHandView.image = nil

            let overlayConstraints = self.retrieveOverlayConstraints(set: self.animationViewOne, to: self.discardPileView)
            NSLayoutConstraint.activate(overlayConstraints)

            UIView.transition(with: self.animationViewOne,
                              duration: 1,
                              options: [.curveEaseInOut],
                              animations: {
                                self.animationViewOne.transform = self.returnRotationTransform(for: self.user)
                                self.animationViewOne.superview?.layoutIfNeeded()
                              }, completion: {_ in
                                self.animationViewOne.image = nil
                                self.showFrontOfCard(show: value, on: self.discardPileView, for: self.user)
                              }
            )
            NSLayoutConstraint.deactivate(overlayConstraints)
        }
        
        return duration + 0.01
    }

    func animateTradeOnHand(withCardAtIndex cardIndex: Int, by player: Player, withValue value: String, closeOnHand: Bool) -> Double {
//        trade the drawn card with one of your own (for either model or player)
        let onHandCardView = returnOnHandCardView(for: player)
        
        if closeOnHand {
            flipClosed(hide: onHandCardView, for: player)
        }
        
        let onTableCardView = returnOnTableCardViews(for: player)[cardIndex]
        flipOpen(show: value, on: onTableCardView, for: player)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.61) { // delay due to card flip(s)
            
            self.animationViewOne.transform = self.returnRotationTransform(for: player)
            self.animationViewTwo.transform = self.returnRotationTransform(for: player)
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
                            self.animationViewOne.transform = self.returnRotationTransform(for: player)
                            self.animationViewTwo.transform = self.returnRotationTransform(for: self.user)
                            self.animationViewOne.superview?.layoutIfNeeded()
                           },
                           completion: {_ in
                            self.animationViewOne.image = nil
                            self.animationViewTwo.image = nil
                            self.showBackOfCard(on: onTableCardView, for: player)
                            self.showFrontOfCard(show: value, on: self.discardPileView, for: self.user)
                           })

            NSLayoutConstraint.deactivate(OverlayConstraints1)
            NSLayoutConstraint.deactivate(OverlayConstraints2)

        }
        return 1.61 + 0.01
    }
    
    func animateCardTrade(ofCardAtIndex cardIndex1: Int, by player1: Player, withCardAtIndex cardIndex2: Int, from player2: Player) -> Double {
        // Trade cars between Actors
        let cardView1 = returnOnTableCardViews(for: player1)[cardIndex1]
        let cardView2 = returnOnTableCardViews(for: player2)[cardIndex2]
        
        self.animationViewOne.transform = self.returnRotationTransform(for: player1)
        self.animationViewTwo.transform = self.returnRotationTransform(for: player2)
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
                            self.animationViewOne.transform = self.returnRotationTransform(for: player2)
                            self.animationViewTwo.transform = self.returnRotationTransform(for: player1)
                            self.animationViewOne.superview?.layoutIfNeeded()
                          }, completion: {_ in
                            self.showBackOfCard(on: cardView1, for: player1)
                            self.showBackOfCard(on: cardView2, for: player2)
                            self.animationViewOne.image = nil
                            self.animationViewTwo.image = nil
                          }
        )
        NSLayoutConstraint.deactivate(endOverlayConstraints1)
        NSLayoutConstraint.deactivate(endOverlayConstraints2)
        
        return 1.0 + 0.01 // duration
    }
    
    func flipOpenAllCards() -> Double {
        for (playerIndex, onTableCardViewsCollection) in [userOnTableCardViews, leftModelOnTableCardViews, topModelOnTableCardViews, rightModelOnTableCardViews].enumerated() {
            let player = game.players[playerIndex]
            for (cardIndex, onTableCardView) in onTableCardViewsCollection!.enumerated() {
                let value = returnStringMatchingWithCard(forCard: player.getCardsOnTable()[cardIndex]!)
                flipOpen(show: value, on: onTableCardView, for: player)
            }
        }
        return 0.61
    }
    
    @IBOutlet weak var leftKnockLabel: UILabel!
    @IBOutlet weak var topKnockLabel: UILabel!
    @IBOutlet weak var rightKnockLabel: UILabel!
    
    func animateKnock(by player: Player) -> Double {
        if player.getId() != user.getId() {
            
            var knockLabel: UILabel {
                switch player.getId() {
                case game.players[1].getId():
                    return leftKnockLabel
                case game.players[2].getId():
                    return topKnockLabel
                default: // game.players[3].getId():
                    return rightKnockLabel
                }
            }
            
            let nKnocks = 3
            
            flashKnockLabel(flashesToMake: nKnocks*2, forLabel: knockLabel)

            
            return Double(nKnocks) * (0.4 + 0.1) * 2 + 0.01
        }
        return 0.0
    }
    
    func flashKnockLabel(flashesToMake count: Int, forLabel label: UILabel) {
        print("knock count: \(count)")
        if count != 0 {
            UIView.animate(withDuration: 0.4, delay: 0.1,
                           options: [],
                           animations: {
                            label.alpha = (label.alpha == 1) ? 0 : 1},
                           completion: { _ in
                            self.flashKnockLabel(flashesToMake: count-1, forLabel: label)
                           })
        }
    }

    // ############################ INFORMATION PROVIDANCE ############################
    
    let infoText = InfoText()
    
    @IBAction func showCardInfo(_ sender: UIButton) {
        
        let message = infoText.getCardInfo(forCardWithName: returnStringMatchingWithCard(forCard: user.getCardOnHand()!))
        
        let infoPopUp = UIAlertController(title: "Drawn Card", message: message, preferredStyle: .alert)
        
        infoPopUp.addAction(UIAlertAction(title: "Got it!", style: .cancel, handler: {_ in
                    print("info about drawn card popped up")
                    }))
        
        present(infoPopUp, animated: true)
    }
    
    @IBAction func showGameInfo(_ sender: UIButton) {
        
        var gameState: String

        if isUserTurn == false { // only during initial inspection, buttons cant be pressed during animations
            gameState = "initialInspect"
        } else if user.getCardOnHand() == nil {
            if playedAction == .swap {
                gameState = "swap"
            } else if playedAction == .inspect {
                gameState = "inspect"
            } else {
                gameState = "start"
            }
        } else {
            gameState = "drawn"
        }
        
        let message = infoText.getGameInfo(forGameStateWithName: gameState)
        
        let infoPopUp = UIAlertController(title: "What to do?", message: message, preferredStyle: .alert)
        
        infoPopUp.addAction(UIAlertAction(title: "Got it!", style: .cancel, handler: {_ in
                    print("info about drawn card popped up")
                    }))
        
        present(infoPopUp, animated: true)
    }
}
