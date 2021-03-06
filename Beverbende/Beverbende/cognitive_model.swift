//
//  cognitive_model.swift
//  model_playground
//
//  Created by Joshua Krause on 20.02.21.
//

import Foundation

class BeverbendeOpponent:Model,Player,BeverbendeDelegate{
    
    /**
     Beverbende opponent, inherits from Model class and implements Player protocol.
     */

    // Model tuning parameters (Class level)
    private static let cut_off_low = 6
    
    private static let cut_off_decide = 10
    
    // Model identifier and Player implmementation variables
    var id: String
    
    var cardOnHand: Card?
    
    var cardsOnTable: [Card]
    
    // Game state, basically goal buffer (cognitive control)
    private enum GameState:Equatable {
        case Begin // Begin of a turn, model decides whether to take top card from discarded.
        case Processed_Discarded(remembered: [CardType?],latencies: [Double]) // Model has decided not to take discarded. Draws card from Deck.
        case Processed_All // Model either looked at deck or discarded, is ready to decide.
        case DecideContinue // turn decision made to continue.
        
        case DecideEnd // turn decision made to end.
        
        static func == (lhs: BeverbendeOpponent.GameState,
                        rhs: BeverbendeOpponent.GameState) -> Bool {
            // Source: https://medium.com/flawless-app-stories/equatable-for-enum-with-associated-value-e07d9ab20e8e
            switch (lhs,rhs) {
            case (.Begin, .Begin):
                return true
            case (.Processed_Discarded(remembered: _, latencies: _),
                  .Processed_Discarded(remembered: _, latencies: _)):
                return true
            case (.Processed_All, .Processed_All):
                return true
            case (.DecideContinue, .DecideContinue):
                return true
            case (.DecideEnd, .DecideEnd):
                return true
            default:
                return false
            }
        }
    }
    
    private var goal:GameState
    
    required init(with ID: String, with Cards: [Card]) {
        self.id = ID
        self.goal = .Begin
        self.cardsOnTable = Cards
        super.init()
        
        /**
         Instantiate cut-off for the decision about whether a card is low or not.
         */
        let sampler = BoxMuller(mu: Double(BeverbendeOpponent.cut_off_low), sd: 1.5)
        let (sample_low,_,_) = sampler.sample(for: 150)
        self.instantiateMemory(for: "low_value_fact", with: sampler.castToInt(for: sample_low))
        
        /**
         Instantiate cut-off for the decision about whether the model should end the game.
         */
        sampler.mu = Double(BeverbendeOpponent.cut_off_decide)
        sampler.sd =  3.0
        let (sample_decide,_,_) = sampler.sample(for: 150)
        self.instantiateMemory(for: "end_value_fact", with: sampler.castToInt(for: sample_decide))
        
        /**
         Peak first two cards. ToDo: make use of Game api.
         */
        self.memorizeCard(at: 1, with: self.cardsOnTable[0])
        self.memorizeCard(at: 4, with: self.cardsOnTable[3])
        print("DM: \(self.dm.chunks)")
    }
    
    /**
     PUBLIC API
     */
    
    func getId() -> String {
        return self.id
    }
    
    
    func getCardOnHand() -> Card? {
        if let currentCard = self.cardOnHand {
            return currentCard
        }
        return nil
    }
    
    
    func setCardOnHand(with card: Card?) {
        if let isaCard = card {
            self.cardOnHand = isaCard
        } else {
            self.cardOnHand = nil
        }
        
    }
    
    
    func getCardsOnTable() -> [Card] {
        return self.cardsOnTable
    }
    
    
    func setCardOnTable(with card: Card, at index: Int) {
        self.cardsOnTable[index] = card
    }
    
    
    func replaceCardOnTable(at pos: Int, with card: Card) -> Card {
        let currentCard = self.cardsOnTable[pos]
        self.cardsOnTable[pos] = card
        return currentCard
    }
    
    
    func handleEvent(for event: EventType, with info: [String : Any]) {
        switch event {
        case .nextTurn:
            
            let player = info["player"] as! Player
            let game = info["game"] as! Beverbende
            if player.id == self.id {
                self.advanceGame(for: game)
            } else {
                for card_index in 1...4 {
                    _ = self.rehearsal(at: card_index)
                }
            }
            
        default:
            // Do nothing.
            ()
        }
    }
    
    
    func summarizeDM(){
        for chunk in self.dm.chunks {
            print(chunk.value.slotvals)
        }
    }
    
    
    func rehearsal(at index:Int) -> (latency: Double,retrieved: Chunk?){
        /**
         Model rehearses card at a given position.
         */
        let request = Chunk(s: "Retrieval",m: self)
        request.slotvals["isa"] = Value.Text("Pos_Fact")
        request.slotvals["pos"] = Value.Number(Double(index))
        let (latency,retrieval) = self.dm.retrieve(chunk: request)
        self.time += latency
        if let retrievedChunk = retrieval {
            // Strengthen
            self.dm.addToDM(retrievedChunk)
            return (latency,retrievedChunk)
        }
        return (latency,nil)
    }

    
    /**
     PRIVATE
     */
    
    private func instantiateMemory(for fact:String, with values:[Int]) {
        /**
         Instantiates/updates a cut-off fact using a sample of values, generated using the Box-Mueller algorithm.
         */
        for val in values {
            let factChunk = self.generateNewChunk(string: fact)
            factChunk.slotvals["isa"] = Value.Text(fact)
            factChunk.slotvals["value"] = Value.Number(Double(val))
            self.dm.addToDM(factChunk)
        }
    }
    
    private func memorizeCard(at position:Int, with card: Card) {
        /**
         Creates memory for new card.
         
         Acts as the interface from cards to ACT-R chunks.
         */
        let chunk = self.generateNewChunk(string: "Pos")
        chunk.slotvals["isa"] = Value.Text("Pos_Fact")
        chunk.slotvals["pos"] = Value.Number(Double(position))
        let cardType = card.getType()
        switch cardType {
        case .value(let points):
            print("Regular card")
            chunk.slotvals["type"] = Value.Text("regular")
            chunk.slotvals["value"] = Value.Number(Double(points))
        case .action(let action):
            print("Action card")
            chunk.slotvals["type"] = Value.Text("action")
            switch action {
            case .twice:
                chunk.slotvals["value"] = Value.Text("twice")
            case .inspect:
                chunk.slotvals["value"] = Value.Text("inspect")
            case .swap:
                chunk.slotvals["value"] = Value.Text("swap")
            }
            
        }
        
        self.dm.addToDM(chunk)
        self.time += 0.05
    }
    
    
    private func compareHand(for newCard: ValueCard,
                             with hand: [CardType?]) -> (known_max: Int?,
                                                         unknown: [Int]) {
        /*
         Model compares its hand to a value card. Returns the location of the
         highest card it remembers that is higher than the presented card. If the model
         encounters a card position for which it cannot remember the corresponding card,
         it will add this location to the list of positions it does not remember.
         **/
        var unknown = Array<Int>()
        var max_val = newCard.getValue()
        var max_loc: Int?
        
        for pos in 1...4 {
            if let card = hand[pos - 1] {
                switch card {
                case .action(let action):
                    switch action {
                        // If we go with the current strategy we can simply default here.
                        case .inspect:
                            max_val = 10 // not in game so will always be replaced
                            max_loc = pos
                        case .swap:
                            max_val = 10
                            max_loc = pos
                        case .twice:
                            max_val = 10
                            max_loc = pos
                    }
                case .value(let value):
                    if value > max_val {
                        max_val = value
                        max_loc = pos
                    }
                }
            } else {
                // Did not remember the card at this position
                unknown.append(pos)
            }
        }
        return (max_loc,unknown)
    }
    
    
    private func rememberHand() -> (remembered: [CardType?], latencies: [Double]){
        /**
         At the beginning of a turn model tries to remember its own cards. It therefore
         requests the retrieval of position facts from the DM and "stores" the retrieved representations
         in the active part of its working memory.
         
         Acts as the interface back from ACT-R chunks to card-types.
         */
        var representationHand = Array<CardType?>()
        var latencies = Array<Double>()

        // Iterate over all positional facts.
        for pos in 1...4 {
            
            let (latency ,retrieval) = rehearsal(at: pos)
            latencies.append(latency)
            if let retrievedChunk = retrieval {
                
                let retrievedType = retrievedChunk.slotvals["type"]!.text()
                
                if retrievedType == "action"{
                    // Retrieved card is an action card
                    let retrieved_action = String(retrievedChunk.slotvals["value"]!.text()!)
                    // Check possible cases
                    if retrieved_action == "twice" {
                        representationHand.append(.action(.twice))
                    } else if retrieved_action == "inspect" {
                        representationHand.append(.action(.inspect))
                    } else {
                        representationHand.append(.action(.swap))
                    }
                    
                } else {
                    // Retrieved card is a value card
                    let retrieved_value = Int(retrievedChunk.slotvals["value"]!.number()!)
                    representationHand.append(.value(retrieved_value))
                }
            } else {
                representationHand.append(nil)
            }
        }
        return (representationHand,latencies)
    }
    
    
    private func findLeastCertain(for remembered: [CardType?], with uncertainty: [Double]) -> Int{
        /**
         Uses latency as a measure of certainty. If one or more cards could not be remembered at all
         one of their positions (at random if there are multiple) will be returned. Otherwise it returns the
         location for which the initial retrieval took the longest.
         */
        var unknown = Array<Int>()
        var max_uncertainty = 0.0
        var max_uncertain_loc = 1
        for pos in 1...4{
            if let _ = remembered[pos - 1] {
                if uncertainty[pos - 1] > max_uncertainty {
                    max_uncertainty = uncertainty[pos - 1]
                    max_uncertain_loc = pos
                }
            } else {
                unknown.append(pos)
            }
        }
        if unknown.count > 0 {
            return Int.random(in:0..<unknown.count)
        }
        return max_uncertain_loc
    }
    
    private func decideInspect(with remembered: [CardType?],
                               and uncertainty: [Double],
                               in game: Beverbende) {
        game.discardDrawnCard(for: self)
        let least_certain_pos = self.findLeastCertain(for: remembered, with: uncertainty)
        let hidden_cards = game.inspectCard(at: least_certain_pos - 1, for: self)
        // ToDo: remove inspected card again
        self.memorizeCard(at: least_certain_pos, with: hidden_cards)
    }
    
    
    private func decideTwice(with remembered: [CardType?],
                             in game: Beverbende) {
        game.discardDrawnCard(for: self)
        for _ in 0..<2 {
            let newCard = game.drawCard(for: self)
            switch newCard.getType() {
            case .action(_):
                // Model wants value cards, discards new .action cards.
                game.discardDrawnCard(for: self)
                continue
            case .value(_):
                let decision = self.decideValue(for: newCard as! ValueCard,
                                                with: remembered,
                                                in: game)
                switch decision {
                case true:
                    break
                case false:
                    game.discardDrawnCard(for: self)
                    continue
                }
            }
        }
    }
    
    
    private func decideSwap(with remembered: [CardType?],
                            and uncertainty: [Double],
                            in game: Beverbende) {
        game.discardDrawnCard(for: self)
        // Too: Implement strategy
    }
        
    
    private func matchAction(for card:ActionCard,
                              with remembered: [CardType?],
                              and uncertainty: [Double],
                              in game: Beverbende) {
        /**
         Decides how to deal with an action card
         */
        let action = card.getAction()
        switch action {
        case .inspect:
            // Always plays this card.
            self.decideInspect(with: remembered,
                               and: uncertainty,
                               in: game)
        case .twice:
            // Always play this card.
            self.decideTwice(with: remembered,
                             in: game)
        case .swap:
            self.decideSwap(with: remembered,
                            and: uncertainty,
                            in: game)
        }
        // No matter the outcome set goal to processed all
        goal = .Processed_All
    }
    
    
    private func decideValue(for card:ValueCard,
                             with hand: [CardType?],
                             in game: Beverbende) -> Bool{
        let value = card.value
        let (known_max, unknown) = compareHand(for: card, with: hand)
        if let found_max = known_max {
            
            memorizeCard(at: found_max, with: card)
            game.tradeDrawnCardWithCard(at: found_max,
                                        for: self)
            return true // Replace card
        } else if unknown.count > 0 {
            /**
             Retrieve a blend of the cut-off for what counts as a low enough card.
             If the value of the current card  is lower than the retrieved cut-off
             decide to replace a random one.
             */
            
            let request = Chunk(s: "Retrieval",m: self)
            request.slotvals["isa"] = Value.Text("low_value_fact")
            let (latency,retrieval) = self.dm.blendedRetrieve(chunk: request)
            self.time += latency
            if let retrievedChunk = retrieval {
                let retrievedCutoff = Int(retrievedChunk.slotvals["value"]!.number()!)
                if value < retrievedCutoff {
                    let choice = Int.random(in:0..<unknown.count)
                    
                    memorizeCard(at: unknown[choice], with: card)
                    game.tradeDrawnCardWithCard(at: unknown[choice],
                                                for: self)
                    /**
                     Now model gets feedback whether replacing the card was a good decision. If the card
                     picked at random was higher in value (or an action card) the selected cutoff should be
                     reinforced.
                     */
                    let previousCard = game.drawDiscardedCard(for: self)
                    switch previousCard.getType() {
                    case .action(_):
                        /**
                        Action cards can be beneficial or detrimental at the end
                        of a game. Thus, their usefulness is hard (if not impossible)
                        to predict, which is why replacing them is always considered
                        a good idea.
                        */
                        self.instantiateMemory(for: "low_value_fact", with: [retrievedCutoff])
                        self.time += 0.05
                    case .value(let previousValue):
                        /**
                        The retrieved cut-off should be reinforced only if the previousValue (the
                         value of the previously unknown card) was higher or equal to the value of the
                         card with which this unknown was replaced. Equal cards are still considered an
                         improvement since knowing the value of the card is beneficial in any case.
                        */
                        if previousValue > value {
                            self.instantiateMemory(for: "low_value_fact", with: [retrievedCutoff])
                            self.time += 0.05
                        }
                    }
                    game.discardDrawnCard(for: self)
                    return true // Replace card
                }
            }
        }
        
        return false // Reject card
    }
    
    
    private func matchValue(for card: ValueCard,
                            with remembered: [CardType?],
                            and uncertainty: [Double],
                            in game: Beverbende) {
        
        let didReplace = self.decideValue(for: card,
                                          with: remembered,
                                          in: game)
        if !didReplace {
            // Discard the card on hand.
            game.discardDrawnCard(for: self)
            // Update Goal based on current game state
            if goal == .Begin {
                goal = .Processed_Discarded(remembered: remembered,
                                            latencies: uncertainty)
            } else {
                goal = .Processed_All
            }
        } else {
            goal = .Processed_All
        }
    }
    
    
    private func matchTurnDecision(with game:Beverbende) {
        /**
         Advances model game by one step and returns
         */
        
        switch goal {
            case .Begin:
                self.time += 0.05
                print("Model will look at discarded pile now:")
                // Place card in hand
                let card = game.drawDiscardedCard(for: self)
            
                // Attempt to remember the deck
                print("Model will try to remember its cards now!")
                let (remembered,latencies) = self.rememberHand()
                
                // Make decision based on card type.
                switch card.getType(){
                case .value(_):
                    self.matchValue(for: card as! ValueCard,
                                    with: remembered,
                                    and: latencies,
                                    in: game)
                case .action(_):
                    self.matchAction(for: card as! ActionCard,
                                      with: remembered,
                                      and: latencies,
                                      in: game)
                }
                
            case .Processed_Discarded(let remembered, let latencies):
                self.time += 0.05
                print("Model looked at discarded, will look at Deck as well.")
                // Place card in hand
                let card = game.drawCard(for: self)
                // Make decision based on card type.
                switch card.getType(){
                case .value(_):
                    self.matchValue(for: card as! ValueCard,
                                    with: remembered,
                                    and: latencies,
                                    in: game)
                case .action(_):
                    self.matchAction(for: card as! ActionCard,
                                      with: remembered,
                                      and: latencies,
                                      in: game)
                }

            case .Processed_All:
                self.time += 0.05
                print("Model looked at Discarded pile and/or Deck")
                let decision = self.decideGame()
                switch decision {
                    case true:
                        print("I knock")
                        goal = .DecideEnd
                    case false:
                        goal = .DecideContinue
                }
                
            case .DecideContinue:
                self.time += 0.05
                print("Model has decided to continue")
                goal = .Begin
            
            case .DecideEnd:
                print("I am out of the game")
        }
    }
    
    
    private func decideGame() -> Bool{
        /**
         Model decides whether to end game or not.
         */
        var sum = 0
        for pos in 1...4{
            let (_,retrieved) = rehearsal(at: pos)
            if let retrievedChunk = retrieved {
                let retrievedType = retrievedChunk.slotvals["type"]!.text()
                switch retrievedType {
                case "action":
                    return false
                default:
                    sum += Int(retrievedChunk.slotvals["value"]!.number()!)
                }
            } else {
                return false
            }
        }
        
        /**
         Retrieve a blend of the cut-off for the decision to end the game.
         If the calculated sum is lower than the retrieved cut-off
         decide to end the game.
         */
        
        let request = Chunk(s: "Retrieval",m: self)
        request.slotvals["isa"] = Value.Text("end_value_fact")
        let (latency,retrieval) = self.dm.blendedRetrieve(chunk: request)
        self.time += latency
        if let retrievedChunk = retrieval {
            let retrievedCutoff = Int(retrievedChunk.slotvals["value"]!.number()!)
            if sum < retrievedCutoff {
                // ToDo: Implement reinforcement of this retrieved cut-off,
                // if the model ends winning the game.
                return true
            }
        }
        return false
    }
    
    
    private func advanceGame(for game: Beverbende) {
        /**
         Model will perform a turn and signals whether it wants to end or not
         */
        repeat {
            self.matchTurnDecision(with: game)
            if self.goal == .DecideContinue {
                self.goal = .Begin
            }
        } while (self.goal != .Begin) && (self.goal != .DecideEnd)
    }
}
