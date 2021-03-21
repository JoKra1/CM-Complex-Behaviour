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
    private static let cut_off_low = 8
    
    private static let cut_off_decide = 16

    private static let learning_rate = 0.1
    
    private var explorationScheduleDecision = 1.0
    
    // Utilities for swap production rules
    private var utilities = [0.0,0.0,0.0] // Discard, swapRandom, swapRecent
    
    // swap action fire enumeration
    private enum productionFired {
        case discard, swapRandom, swapRecent
    }
    
    // swap history for rewarding
    private var swapHistory = [(production:productionFired,atTime:Double)]()
    
    // Model identifier and Player implmementation variables
    var id: String
    
    var cardOnHand: Card?
    
    var cardsOnTable: [Card?]
    
    // Game state, for cognitive control
    private enum GameState:Equatable {
        case Begin // Begin of a turn, model decides whether to take top card from discarded.
        case Processed_Discarded // Model has decided not to take discarded. Draws card from Deck.
        case Processed_All // Model either looked at deck or discarded, is ready to decide.
        case DecideContinue // turn decision made to continue.
        case DecideEnd // turn decision made to end.
    }
    
    // Quasi goal buffer, but also serves as an imaginal buffer.
    // Allows to keep track of game state and to maintain a representation of
    // the hand of cards and their latencies. (The latter is not ACT-R typical)
    private var goal:(state:GameState,remembered:[CardType?]?,latencies:[Double]?)
    
    private var didKnock = false
    private var endCutoff:Int?
    
    weak var game:Beverbende?
    
    required init(with ID: String) {
        //setup(with: ID)
        self.id = ID
        self.goal.state = .Begin
        self.goal.remembered = nil
        self.goal.latencies = nil
        self.cardsOnTable = []
        super.init()
        self.setup()
    }
    
    init(with ID: String, with Cards: [Card?], for Game: Beverbende) {
        
        self.id = ID
        self.goal.state = .Begin
        self.goal.remembered = nil
        self.goal.latencies = nil
        self.cardsOnTable = Cards
        self.game = Game
        
        super.init()
        self.game?.add(delegate: self)
        self.setup()
        print("DM: \(self.dm.chunks)")
    }
    
    func setup() {
        
        /**
         Peak first two cards.
         */
        
        let leftCard = self.game?.inspectCard(at: 0, for: self)
        self.memorizeCard(at: 1, with: leftCard!)
        self.game?.moveCardBackFromHand(to: 0, for: self)
        let rightCard = self.game?.inspectCard(at: 3, for: self)
        self.memorizeCard(at: 4, with: rightCard!)
        self.game?.moveCardBackFromHand(to: 3, for: self)
        
    }
    
    /**
     PUBLIC API
     */
    
    /**
     Player Protocol implementation
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
        self.cardOnHand = card
    }
    
    
    func getCardsOnTable() -> [Card?] {
        return self.cardsOnTable
    }
    
    
    func setCardOnTable(with card: Card?, at index: Int) {
        self.cardsOnTable[index] = card
    }
    
    func setCardsOnTable(with cards: [Card?]) {
        self.cardsOnTable = cards
    }
    
    
    func replaceCardOnTable(at pos: Int, with card: Card) -> Card {
        let currentCard = self.cardsOnTable[pos]!
        self.cardsOnTable[pos] = card
        return currentCard
    }
    
    /**
     BeverbendeDelegate implementation
     */
    
    func handleEvent(for event: EventType, with info: [String : Any]) {
        switch event {
        case .nextTurn(let player):
            if player.id == self.id, let game = self.game {
                self.time += 15.0
                self.summarizeDM()
                print("It is Model \(self.id)'s turn.")
                self.advanceGame()
                let _ = game.nextPlayer()
            } else {
                // Rehearse
                for card_index in 1...4 {
                    print("Model \(self.id) is rehearsing since it is not its turn.")
                    _ = self.rehearsal(at: card_index)
                }
            }
        
        case .gameEnded(let winner):
            print("\(self.id) received game ended signal.")
            if winner.id == self.id {
                print("Hooray")
                if self.didKnock {
                    let cutoff = self.endCutoff!
                    
                    self.memorizeDecision(for: "end_value_fact", was: true, for: cutoff)
                    self.reinforceSwap(with: 1.0)
                                        
                } else {
                    // Model did not knock but won, so remembers card sum as good
                    let sum = sumCards(for: self)
                    self.memorizeDecision(for: "end_value_fact", was: true, for: sum)
                    self.reinforceSwap(with: 1.0)
                }
            } else {
                // Model lost
                if self.didKnock {
                    let cutoff = self.endCutoff!
                    
                    self.memorizeDecision(for: "end_value_fact", was: false, for: cutoff)
                    self.reinforceSwap(with: 0.0)
                } else {
                    let sum = sumCards(for: self)
                    self.memorizeDecision(for: "end_value_fact", was: false, for: sum)
                    self.reinforceSwap(with: 0.0)
                }
                
                // Also memorize winners sum as a good
                let winnerSum = sumCards(for: winner)
                self.memorizeDecision(for: "end_value_fact", was: true, for: winnerSum)
            }
            // Put all models in restricted game ended mode.
            self.goal.state = .DecideEnd
        
        case .cardsSwapped(let pos1, let player1,
                           let pos2, let player2):
            if player1.id != self.id {
                // Someone other than me swapped recently
                print("\(self.id) stores a recent swapper.")
                self.memorizeSwapper(who: player1.id, at: pos1 + 1)
            }
            
            if player2.id == self.id {
                // Someone swapped with me, I should forget the card in that position
                print("\(self.id) adaptively forgets all knowledge about a swapped card.")
                self.memorizeUnknown(isa: "Pos_Fact",
                                     for: "type",
                                     at: pos2 + 1)
            }
            
            // ToDo: implement adaptive positional forgetting of person that was swapped.
            // This requires changing the storage of the swapper facts!
        
        case .discardedCardTraded(let player, let discardedCard, let replacedCard, _, _):
            // Whenever any other player decided to replace a card on the hand with the
            // top discarded card, the model can use this as an opportunity to learn more
            // about the low value cut-off, by going to the same steps when having to make
            // the same decision.
            
            if player.id != self.id {
                // Only handle this case if it wasn't the model itself.
                switch discardedCard.getType() {
                case .action:
                    // This should never happen, because it is objectively speaking
                    // not a good move. However, human opponenst not always act rational so...
                    ()
                case .value(let points):
                    // Judge (and memorize) whether the move by the opponent was "good" or "bad"
                    print("\(self.id) judges the discarded card trade made by an opponent.")
                    self.memorizeLowDecision(for: points,
                                             compare_against: replacedCard,
                                             and: points)
                }
            }
            
        
            
        default:
            // Do nothing.
            ()
        }
    }
    
    
    func IDToPlayer (for id:String) -> Player? {
        for player in game!.players {
            if player.getId() == id {
                return player
            }
        }
        return nil
    }
    
    
    private func resetPosfacts() {
        for chunk in self.dm.chunks {
            if chunk.value.slotvals["isa"]!.text()! == "Pos_Fact" {
                self.dm.chunks.removeValue(forKey: chunk.key)
            }
            
        }
    }
    
    private func resetTimeFacts(for fact:String) {
        for chunk in self.dm.chunks {
            if chunk.value.slotvals["isa"]!.text()! == fact {
                for i in 0..<chunk.value.referenceList.count {
                    chunk.value.referenceList[i] = 0.0
                }
            }
        }
    }
    
    private func sumCards(for player: Player) -> Int {
        let cards = player.cardsOnTable
        var sum = 0
        for card in cards {
            if card != nil {
                switch card!.getType() {
                case .value(let points):
                    sum += points
                case .action:
                    sum += 10
                }
            } else {
                sum += 10
            }
        }
        return sum
    }
    
    func resetOpponent(){
        // Reset time
        self.time = 0.0
        // Reset any game ending decisions
        self.didKnock = false
        self.endCutoff = nil
        self.goal.state = .Begin
        self.goal.remembered = nil
        self.goal.latencies = nil
        // Clear all positional facts and reset time for decision facts
        self.resetPosfacts()
        self.resetTimeFacts(for: "end_value_fact")
        self.resetTimeFacts(for: "low_value_fact")
        
        // Inspect first two cards.
        let leftCard = self.game?.inspectCard(at: 0, for: self)
        self.memorizeCard(at: 1, with: leftCard!)
        self.game?.moveCardBackFromHand(to: 0, for: self)
        
        let rightCard = self.game?.inspectCard(at: 3, for: self)
        self.memorizeCard(at: 4, with: rightCard!)
        self.game?.moveCardBackFromHand(to: 3, for: self)
    }
    
    /**
     Some wrappers to get information about the model
     */
    
    func summarizeDM(){
        print("Summarizing DM")
        for pos in 1...4{
            for chunk in self.dm.chunks {
                if chunk.value.slotvals["isa"]!.text()! == "low_value_fact__" {
                    if chunk.value.slotvals["pos"]!.number()! == Double(pos){
                        print(chunk.value.slotvals)
                        print(chunk.value.baseLevelActivation())
                        print(chunk.value.referenceList)
                    }
                }
            }
        }
    }
    
    func attachGame(with game:Beverbende) {
        self.game = game
    }
    
    
    override func mismatchFunction(x: Value, y: Value) -> Double? {
        // Mismatch function adapted from Lebiere Anderson and Reder (1994)
        // Returns 0 if two values are identical, and increasingly more negative
        // values (bounded at -1) the larger the absolute difference between the
        // two values is.
        let x_val = x.number()
        let y_val = y.number()
        if (x_val != nil) && (y_val != nil) {
            let diff = fabs(x_val! - y_val!)
            return exp(-diff)-1
        }
        return nil
    }
    

    /**
     PRIVATE
     */
    
    private func formatTime() -> String {
        // Source: https://www.hackingwithswift.com/example-code/system/how-to-convert-dates-and-times-to-a-string-using-dateformatter
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "H:m:ss.SSSS"
        return formatter.string(from: date)
        
    }
    
    private func rehearsal(at index:Int) -> (latency: Double,retrieved: Chunk?){
        /**
         Model rehearses card at a given position.
         */
        let request = Chunk(s: "Retrieval",m: self)
        request.isRequest = true
        request.slotvals["isa"] = Value.Text("Pos_Fact")
        request.slotvals["pos"] = Value.Number(Double(index))
        let (latency,retrieval) = self.dm.retrieve(chunk: request)
        self.time += latency
        if let retrievedChunk = retrieval {
            // Create a new chunk (with different id)
            let chunk = self.generateNewChunk(string: "Pos")
            chunk.slotvals["__id"] = Value.Text(String(self.dm.chunks.count) + "_" + self.formatTime())
            chunk.slotvals["isa"] = Value.Text("Pos_Fact")
            chunk.slotvals["pos"] = retrievedChunk.slotvals["pos"]
            chunk.slotvals["type"] = retrievedChunk.slotvals["type"]
            chunk.slotvals["value"] = retrievedChunk.slotvals["value"]
            self.dm.addToDM(chunk)
            self.time += 0.05
            return (latency,retrievedChunk)
        }
        return (latency,nil)
    }
    
    
    private func memorizeCard(at position:Int, with card: Card) {
        /**
         Creates memory for new card.
         
         Acts as the interface from cards to ACT-R chunks.
         */
        let chunk = self.generateNewChunk(string: "Pos")
        chunk.slotvals["__id"] = Value.Text(String(self.dm.chunks.count) + "_" + self.formatTime())
        chunk.slotvals["isa"] = Value.Text("Pos_Fact")
        chunk.slotvals["pos"] = Value.Number(Double(position))
        let cardType = card.getType()
        switch cardType {
        case .value(let points):
            chunk.slotvals["type"] = Value.Text("value")
            chunk.slotvals["value"] = Value.Number(Double(points))
            print("Model \(self.id) memorized \(points) at position \(position)")
        case .action(let action):
            print("Model \(self.id) memorized \(action) at position \(position)")
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
    
    
    private func memorizeSwapper(who swapped: String,
                                 at position: Int) {
        // Allows for adaptive forgetting for position facts and
        // recent swapper facts.
        let chunk = self.generateNewChunk(string: "Swapper")
        chunk.slotvals["isa"] = Value.Text("swapped_recently_fact")
        chunk.slotvals["__id"] = Value.Text(String(self.dm.chunks.count) + "_" + self.formatTime())
        chunk.slotvals["pos"] = Value.Number(Double(position))
        chunk.slotvals["who"] = Value.Text(swapped)
        
        self.dm.addToDM(chunk)
        self.time += 0.05
    }
    
    
    private func memorizeUnknown(isa: String,
                                 for type: String,
                                 at position: Int) {
        // Allows for adaptive forgetting for position facts and
        // recent swapper facts.
        let chunk = self.generateNewChunk(string: "Forget")
        chunk.slotvals["isa"] = Value.Text(isa)
        chunk.slotvals["__id"] = Value.Text(String(self.dm.chunks.count) + "_" + self.formatTime())
        chunk.slotvals["pos"] = Value.Number(Double(position))
        chunk.slotvals[type] = Value.Text("unknown")
        
        self.dm.addToDM(chunk)
        self.time += 0.05
    }
    
    
    private func memorizeDecision(for fact:String,
                                  was successful:Bool,
                                  for value: Int) {
        // Memorizes whether for a specific cut-off (low value or end decision)
        // the decision was a good or a bad one. The definition of a good or
        // bad decision is included in the decide value method and the decide game method.
        let chunk = self.generateNewChunk(string: fact)
        chunk.slotvals["isa"] = Value.Text(fact)
        chunk.slotvals["value"] = Value.Number(Double(value))
        
        switch successful {
            case true:
                chunk.slotvals["outcome"] = Value.Text("good")
            case false:
                chunk.slotvals["outcome"] = Value.Text("bad")
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
                    print("Model \(self.id) remembered an action card: \(retrieved_action) at position: \(pos)")
                    // Check possible cases
                    if retrieved_action == "twice" {
                        representationHand.append(.action(.twice))
                    } else if retrieved_action == "inspect" {
                        representationHand.append(.action(.inspect))
                    } else {
                        representationHand.append(.action(.swap))
                    }
                    
                } else if retrievedType == "value" {
                    // Retrieved card is a value card
                    let retrieved_value = Int(retrievedChunk.slotvals["value"]!.number()!)
                    print("Model \(self.id) remembered a value card: \(retrieved_value) at position: \(pos)")
                    representationHand.append(.value(retrieved_value))
                } else {
                    // Recalled that this card was adaptively forgotten!.
                    representationHand.append(nil)
                }
            } else {
                // Did not recall anything at all for this position!
                representationHand.append(nil)
            }
        }
        print("Model \(self.id) latencies: \(latencies) ")
        return (representationHand,latencies)
    }
    
    
    private func findLeastCertain(for remembered: [CardType?], with latencies: [Double]) -> Int{
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
                if latencies[pos - 1] > max_uncertainty {
                    max_uncertainty = latencies[pos - 1]
                    max_uncertain_loc = pos
                }
            } else {
                unknown.append(pos)
            }
        }
        if unknown.count > 0 {
            let choice =  Int.random(in:0..<unknown.count)
            return unknown[choice]
        }
        return max_uncertain_loc
    }
    
    
    private func decideInspect() {
        
        game!.discardDrawnCard(for: self)
        
        let remembered = goal.remembered!
        let latencies = goal.latencies!
        
        let least_certain_pos = self.findLeastCertain(for: remembered, with: latencies)
        let hidden_card = game!.inspectCard(at: least_certain_pos - 1, for: self)
        self.memorizeCard(at: least_certain_pos, with: hidden_card)
        game!.moveCardBackFromHand(to: least_certain_pos - 1, for: self)
    }
    
    
    private func decideTwice() {
        game!.discardDrawnCard(for: self)
        for iteration in 0..<2 {
            print("Model \(self.id) draws \(iteration+1) card of take twice action.")
            let newCard = game!.drawCard(for: self)
            switch newCard.getType() {
            case .action:
                // Model wants value cards, discards new .action cards.
                print("Model \(self.id) got a new action card.. discards it.")
                game!.discardDrawnCard(for: self)
            case .value:
                print("Model \(self.id) got a new value card! Will decide now.")
                let decision = self.decideValue(for: newCard as! ValueCard)
                switch decision {
                case true:
                    print("Model \(self.id) takes the value card in iteration \(iteration+1)")
                    return 
                case false:
                    game!.discardDrawnCard(for: self)
                }
            }
        }
    }
    
    
    private func swapDiscard() {
        // Nothing more than adding an
        // entry to the swap history.
        swapHistory.append((production: .discard, atTime: self.time))
    }
    
    
    private func swapRecent() {
        // Attempt to retrieve who swapped for the
        // last time. If that is possible swap
        // with that person and forget the person!!
        // Else swapRandom.
        let remembered = goal.remembered!
        let request = Chunk(s: "Retrieval",m: self)
        request.slotvals["isa"] = Value.Text("swapped_recently_fact")
        let (latency,retrieval) = self.dm.retrieve(chunk: request)
        self.time += latency
        
        if let retrievedFact = retrieval {
            let retrievedRecentSwapper = retrievedFact.slotvals["who"]!.text()!
            
            if retrievedRecentSwapper == "unknown" {
                // Adaptively forgotten.
                self.swapRandom()
            } else {
                let retrievedReplacedCard = Int(retrievedFact.slotvals["pos"]!.number()!) - 1
                // Check whether there is an unknown card still.
                var unknown = [Int]()
                for (index,possiblyRemembered) in remembered.enumerated() {
                    
                    if possiblyRemembered == nil {
                        unknown.append(index)
                    }
                }
                // If there is an unknown card, swap that one.
                if unknown.count > 0 {
                    let choice = Int.random(in:0..<unknown.count)
                    let player = self.IDToPlayer(for: retrievedRecentSwapper)!
                    game!.swapCards(cardAt: unknown[choice],
                                    for: self,
                                    withCardAt: retrievedReplacedCard,
                                    for: player)
                    
                    // Forget the recent swapper so that you do not swap your own card if you swap again.
                    self.memorizeUnknown(isa: "swapped_recently_fact",
                                         for: "who",
                                         at: -1)
                }
                swapHistory.append((production: .swapRecent, atTime: self.time))
            }
        } else {
            // Fall back to random swap if no recent swapper
            // can be retrieved.
            self.swapRandom()
        }
    }
    
    
    private func swapRandom() {
        let players = game!.players
        let remembered = goal.remembered!
        var choicePLAY = Int.random(in:0..<players.count)
        
        while players[choicePLAY].id == self.id {
            choicePLAY = Int.random(in:0..<players.count)
        }
        var unknown = [Int]()
        for (index,possiblyRemembered) in remembered.enumerated() {
            
            if possiblyRemembered == nil {
                unknown.append(index)
            }
        }
        // If there is an unknown card, swap that one.
        if unknown.count > 0 {
            let choiceUNK = Int.random(in:0..<unknown.count)
            game!.swapCards(cardAt: unknown[choiceUNK],
                            for: self,
                            withCardAt: Int.random(in:0..<4),
                            for: players[choicePLAY])
        }
        swapHistory.append((production: .swapRecent, atTime: self.time))
        
    }
    
    
    
    private func decideSwap() {
        // Discard the action card and match rule
        // with highest utility.
        game!.discardDrawnCard(for: self)
        let utilityDiscard = utilities[0] + actrNoise(noise: self.procedural.utilityNoise)
        let utilitySwapRandom = utilities[1] + actrNoise(noise: self.procedural.utilityNoise)
        let utilitySwapRecent = utilities[2] + actrNoise(noise: self.procedural.utilityNoise)
        
        // Select action with highest utlity.
        if utilityDiscard > utilitySwapRandom,
           utilityDiscard > utilitySwapRecent {
            swapDiscard()
        } else if utilitySwapRandom > utilityDiscard,
                  utilitySwapRandom > utilitySwapRecent {
            swapRandom()
        } else {
            swapRecent()
        }
    }
    
    
    private func reinforceSwap(with reward:Double) {
        
        let timeDist = self.time
        print("Model \(self.id) timeDist \(timeDist)")
        for (production,timeMatched) in swapHistory {
            print("Model \(self.id) production \(production) at time: \(timeMatched)")
            let timeDiff = (timeDist - timeMatched) / timeDist // Ratio of time diff
            print("Model \(self.id) time-diff: \(timeDiff)")
            let actual_reward = reward - timeDiff
            print("Model \(self.id) actual-reward: \(actual_reward)")
            
            switch production {
                case .discard:
                    let q_update = actual_reward - utilities[0]
                    utilities[0] = utilities[0] + BeverbendeOpponent.learning_rate * q_update
                    print("Model \(self.id) utility for discard: \(utilities[0])")
                case .swapRandom:
                    let q_update = actual_reward - utilities[1]
                    utilities[1] = utilities[1] + BeverbendeOpponent.learning_rate * q_update
                    print("Model \(self.id) utility for random: \(utilities[1])")
                case .swapRecent:
                    let q_update = actual_reward - utilities[2]
                    utilities[2] = utilities[2] + BeverbendeOpponent.learning_rate * q_update
                    print("Model \(self.id) utility for recent: \(utilities[2])")
            }
            
        }
    }
        
    
    private func matchAction(for card:ActionCard) {
        /**
         Decides how to deal with an action card
         */
        switch self.goal.state {
        case .Begin:
            print("Model \(self.id) skips top discarded action card")
            // Cannot take action cards from discarded pile.
            game!.discardDrawnCard(for: self)
            goal.state = .Processed_Discarded
        default:
            print("Model \(self.id) matches action card")
            let action = card.getAction()
            switch action {
            case .inspect:
                // Always plays this card.
                print("Model \(self.id) will decide inspect.")
                self.decideInspect()
            case .twice:
                // Always play this card.
                print("Model \(self.id) will decide twice.")
                self.decideTwice()
            case .swap:
                print("Model \(self.id) will decide swap.")
                self.decideSwap()
            }
            // No matter the outcome set goal to processed all
            goal.state = .Processed_All
        }
        
    }
    
    
    private func memorizeLowDecision(for value:Int,
                                     compare_against previousCard: Card,
                                     and retrievedCutoff: Int) {
        
        
        switch previousCard.getType() {
        case .action(_):
            /**
            Action cards can be beneficial or detrimental at the end
            of a game. Thus, their usefulness is hard (if not impossible)
            to predict, which is why replacing them is always considered
            a good idea.
            */
            print("Model \(self.id) memorizes the cut-off for low value decision as good")
            self.memorizeDecision(for: "low_value_fact", was: true, for: retrievedCutoff)
            self.time += 0.05
        case .value(let previousValue):
            /**
            The retrieved cut-off should be reinforced only if the previousValue (the
             value of the previously unknown card) was higher or equal to the value of the
             card with which this unknown was replaced. Equal cards are still considered an
             improvement since knowing the value of the card is beneficial in any case.
            */
            if previousValue > value {
                print("Model \(self.id) memorizes the cut-off for low value decision as good")
                self.memorizeDecision(for: "low_value_fact", was: true, for: retrievedCutoff)
                self.time += 0.05
            } else {
                print("Model \(self.id) memorizes the cut-off for low value decision as bad")
                self.memorizeDecision(for: "low_value_fact", was: false, for: retrievedCutoff)
                self.time += 0.05
            }
        }
    }
    
    
    private func decideValue(for card:ValueCard) -> Bool{
        // Create constants for representation of hand
        // and a variable for the hand/latencies
        let value = card.value
        var hand = goal.remembered!
        var latencies = goal.latencies!
        
        // Compare the value of the current card to the representation of the hand.
        let (known_max, unknown) = compareHand(for: card, with: hand)
        if let found_max = known_max {
            print("Model \(self.id) took the value card to replace a known higher one.")
            memorizeCard(at: found_max, with: card)
            self.summarizeDM()
            print(self.time)
            game!.tradeDrawnCardWithCard(at: found_max - 1,
                                        for: self)
            // Update the representation of the hand and latencies
            hand[found_max - 1] = CardType.value(value)
            latencies[found_max - 1] = 0.0
            goal.remembered = hand
            goal.latencies = latencies

            return true // Replace card
        } else if unknown.count > 0 {
            /**
             Retrieve a blend of the cut-off for what counts as a low enough card.
             If the value of the current card  is lower than the retrieved cut-off
             decide to replace a random one.
             */
            
            let request = Chunk(s: "Retrieval",m: self)
            request.slotvals["isa"] = Value.Text("low_value_fact")
            request.slotvals["value"] = Value.Number(Double(value))
            let (latency,retrieval) = self.dm.partialRetrieve(chunk: request,
                                                              mismatchFunction: self.mismatchFunction)
            
            self.time += latency
            
            // Successful partial retrieval!
            if let retrievedChunk = retrieval {
                
                self.dm.addToDM(retrievedChunk)
                self.time += 0.05
                
                let retrievedOutcome = retrievedChunk.slotvals["outcome"]!.text()!
                let retrievedValue = Int(retrievedChunk.slotvals["value"]!.number()!)
                print("Model \(self.id) retrieved an outcome of \(retrievedOutcome) based on retrieved value: \(retrievedValue)")
                if retrievedOutcome == "good" {
                    let choice = Int.random(in:0..<unknown.count)
                    memorizeCard(at: unknown[choice], with: card)
                    
                    self.summarizeDM()
                    print(self.time)
                    game!.tradeDrawnCardWithCard(at: unknown[choice] - 1,
                                                for: self)
                    
                    // Update the representation of the hand and latencies
                    hand[unknown[choice] - 1] = CardType.value(value)
                    latencies[unknown[choice] - 1] = 0.0
                    goal.remembered = hand
                    goal.latencies = latencies
                    
                    /**
                     Now model gets feedback whether replacing the card was a good decision. Only If the card
                     picked at random was higher in value (or an action card) the replacement should be remembered as
                     a good decision.
                     */
                    let previousCard = game!.drawDiscardedCard(for: self)
                    self.memorizeLowDecision(for: value,
                                             compare_against: previousCard,
                                             and: value)
                    
                    game!.discardDrawnCard(for: self)
                    return true // Replace card
                    
                }
            } else {
                print("Model \(self.id) could not retrieve a strategy, falls back to cut-off.")
                // Failure to retrieve a strategy for the current value, fall back to cut-off
                if value < BeverbendeOpponent.cut_off_low {
                    let choice = Int.random(in:0..<unknown.count)
                    memorizeCard(at: unknown[choice], with: card)
                    
                    self.summarizeDM()
                    print(self.time)
                    game!.tradeDrawnCardWithCard(at: unknown[choice] - 1,
                                                for: self)
                    
                    // Update the representation of the hand and latencies
                    hand[unknown[choice] - 1] = CardType.value(value)
                    latencies[unknown[choice] - 1] = 0.0
                    goal.remembered = hand
                    goal.latencies = latencies
                    
                    /**
                     Now model gets feedback whether replacing the card was a good decision as well. This time
                     however, a new memory for this value will be created (depending on outcome this value will be marked
                     as good or bad)
                     */
                    let previousCard = game!.drawDiscardedCard(for: self)
                    self.memorizeLowDecision(for: value,
                                             compare_against: previousCard,
                                             and: value)
                    
                    game!.discardDrawnCard(for: self)
                    return true // Replace card
                }
            }
        }
        
        return false // Reject card
    }
    
    
    private func matchValue(for card: ValueCard) {
        
        let didReplace = self.decideValue(for: card)
        if !didReplace {
            // Discard the card on hand.
            game!.discardDrawnCard(for: self)
            // Update Goal based on current game state
            if goal.state == .Begin {
                goal.state = .Processed_Discarded
            } else {
                goal.state = .Processed_All
            }
        } else {
            goal.state = .Processed_All
        }
    }
    
    
    private func matchCard(for card: Card) {
        /**
         Match card type.
         */
        switch card.getType(){
            case .value:
                self.matchValue(for: card as! ValueCard)
            case .action:
                self.matchAction(for: card as! ActionCard)
        }
    }
    
    
    private func matchTurnDecision() {
        /**
         Advances model game by one step and returns
         */
        
        switch goal.state {
            case .Begin:
                print("Model \(self.id) representation \(goal.remembered)")
                print("Model \(self.id) latencies \(goal.latencies)")
                self.time += 0.05
                print("Model \(self.id) will look at discarded pile now:")
                // Place card in hand
                let card = game!.drawDiscardedCard(for: self)
            
                // Attempt to remember the deck
                print("Model \(self.id) will try to remember its cards now.")
                let (remembered,latencies) = self.rememberHand()
                
                // Update Goal (Imaginal) slots
                goal.remembered = remembered
                goal.latencies = latencies
                
                // Make decision based on card type.
                self.matchCard(for: card)
                
            case .Processed_Discarded:
                self.time += 0.05
                print("Model \(self.id) looked at discarded, will look at Deck as well.")
                // Place card in hand
                let card = game!.drawCard(for: self)
                // Make decision based on card type.
                self.matchCard(for: card)

            case .Processed_All:
                self.time += 0.05
                print("Model \(self.id) looked at Discarded pile and/or Deck.")
                
                if !game!.knocked {
                    let decision = self.decideGame()
                    switch decision {
                        case true:
                            print("\(self.id): I knock")
                            game!.knock(from: self)
                            goal.state = .DecideEnd
                        case false:
                            goal.state = .DecideContinue
                    }
                } else {
                    print("Someone already knocked so I will continue.")
                    goal.state = .DecideContinue
                }
                
                
            case .DecideContinue:
                self.time += 0.05
                print("Model has decided to continue.")
                // Clear all slots
                goal.state = .Begin
                goal.remembered = nil
                goal.latencies = nil
            
            case .DecideEnd:
                print("I am out of the game.")
        }
    }
    
    
    private func decideGame() -> Bool{
        /**
         Model decides whether to end game or not.
         */
        let remembered = goal.remembered!
        print("Model \(self.id) representation \(remembered)")
        print("Model \(self.id) latencies \(goal.latencies)")
        var sum = 0
        for possiblyRetrieved in remembered{
            if let retrievedType = possiblyRetrieved {

                switch retrievedType {
                case .action:
                    sum += 10
                case .value(let value):
                    sum += value
                }
            } else {
                sum += 10
            }
        }
        
        /**
         Retrieve a blend of the cut-off for the decision to end the game.
         If the calculated sum is lower than the retrieved cut-off
         decide to end the game.
         */
        
        let request = Chunk(s: "Retrieval",m: self)
        request.slotvals["isa"] = Value.Text("end_value_fact")
        request.slotvals["value"] = Value.Number(Double(sum))
        let (latency,retrieval) = self.dm.partialRetrieve(chunk: request,
                                                          mismatchFunction: self.mismatchFunction)
        self.time += latency
        
        // Retrieval of outcome in a similar situation in the past.
        if let retrievedChunk = retrieval {
            self.dm.addToDM(retrievedChunk)
            self.time += 0.05
            
            let retrievedOutcome = retrievedChunk.slotvals["outcome"]!.text()!
            let retrievedValue = Int(retrievedChunk.slotvals["value"]!.number()!)
            print("Model \(self.id) retrieved end outcome of \(retrievedOutcome) for \(retrievedValue).")
            if retrievedOutcome == "good" {
                // Set did knock to true so that retrieved cut-off
                // can be reinforced.
                self.didKnock = true
                self.endCutoff = sum
                return true
            }
        } else {
            print("Model \(self.id) could not retrieve end outcome, falls back to cut-off.")
            // Fall back to cut-off.
            if sum < BeverbendeOpponent.cut_off_decide {
                // Set did knock to true so that retrieved cut-off
                // can be reinforced.
                self.didKnock = true
                self.endCutoff = sum
                return true
            }
        }
        return false
    }
    
    
    private func advanceGame() {
        /**
         Model will perform a turn and signals whether it wants to end or not
         */
        repeat {
            self.matchTurnDecision()
        } while (self.goal.state != .Begin) && (self.goal.state != .DecideEnd)
    }
}
