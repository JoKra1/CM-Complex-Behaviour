//
//  cognitive_model.swift
//  model_playground
//
//  Created by Joshua Krause on 20.02.21.
//

import Foundation

class BeverbendeOpponent:Model,Player{
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
    private enum GameState {
        case Begin // Begin of a turn, model decides whether to take top card from discarded.
        case Processed_Discarded // Model has decided not to take discarded. Draws card from Deck.
        case Processed_All // Model either looked at deck or discarded, is ready to decide.
        case DecideContinue // turn decision made to continue.
        
        case DecideEnd // turn decision made to end.
    }
    
    private var goal:GameState
    
    required init(with ID: String, with Cards: [Card]) {
        self.id = ID
        self.goal = .Begin
        self.cardsOnTable = Cards
        super.init()
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
    
    func setCardOnHand(with card: Card) {
        self.cardOnHand = card
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
    
    func advanceGame(for game: Beverbende) -> Bool {
        /**
         Model will perform a turn and signals whether it wants to end or not
         */
        repeat {
            self.matchTurnDecision(with: game)
            if self.goal == .DecideContinue {
                self.goal = .Begin
                return false
            } else if self.goal == .DecideEnd{
                return true
            }
        } while self.goal != .Begin
        return false
    }
    
    /**
     PRIVATE
     */
    
    private func memorizeCard(at position:Int, with card: Card) {
        /**
         Creates memory for new card.
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
    
    private func compareHand(for value:Int) -> (known_location: Int?,
                                                    unknown_locations: Array<Int>){
        /**
         Model compares its hand to a card. Returns
         a known location (if there is any) of the current highest card that
         the model knows about and the array of unknown location.
         */
        var unknown = Array<Int>()
        var max_val = value
        var max_loc: Int?
        // Iterate over all positional facts.
        for pos in 1...4 {
            print("I am thinking about the card in the \(pos) position...")
            // We could use the latency here as a measure of confidence as well.
            let (_,retrieval) = rehearsal(at: pos)
            if let retrievedChunk = retrieval {
                print("I remembered the value of the card in the \(pos) position.")
                
                let retrievedType = retrievedChunk.slotvals["type"]!.text()
                
                switch retrievedType {
                case "action":
                    // What to do if action card on hand? Always replace, or just if lower than cut-off?
                    continue
                default: // card is regular.
                    let retrieved_value = Int(retrievedChunk.slotvals["value"]!.number()!)
                    print("I remembered the value \(retrieved_value).")
                    if  retrieved_value > max_val {
                        max_val = value
                        max_loc = pos
                    }
                }
            } else {
                unknown.append(pos)
            }
        }
        return (max_loc,unknown)
    }
    
    private func decideAction(for card:ActionCard) -> (decision: Bool, replace: Int?) {
        return (false,nil)
    }
    
    private func decideRegular(for card:ValueCard) -> (decision: Bool, replace: Int?) {
        let value = card.value
        let (known_max, unknown) = compareHand(for: value)
        if let found_max = known_max {
            print("I decided to use the card to replace the one in the \(found_max) position, because I remembered it to be higher.")
            memorizeCard(at: found_max, with: card)
            return (true,found_max) // Accept card to replace highest current card.
        } else if unknown.count > 0, value < BeverbendeOpponent.cut_off_low {
            
            let choice = Int.random(in:0..<unknown.count)
            print("I decided to replace the unknown card in the \(unknown[choice]) position, because it is lower than my decision value.")
            memorizeCard(at: unknown[choice], with: card)
            return (true,unknown[choice]) // Accept card to replace a random unknown card.
        }
        
        print("I decided to discard this card.")
        return (false,nil) // Reject card
    }
    
    private func decideDraw(for card:Card) ->  (decision: Bool, replace: Int?) {
        /**
         Model decides whether to use a card or whether to discard it.
         */
        
        switch card.getType(){
        case .value(_):
            return decideRegular(for: card as! ValueCard)
        case .action(_):
            return decideAction(for: card as! ActionCard)
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
        if sum < BeverbendeOpponent.cut_off_decide {
            return true
        }
        return false
    }
    
    private func replaceCardInHand(in game: Beverbende, at pos: Int, for card:Card) {
        let currentCard = self.cardsOnTable[pos]
        game.discardPile.push(currentCard)
        setCardOnTable(with: card, at: pos)
        self.cardOnHand = nil
    }
    
    private func matchTurnDecision(with game:Beverbende) {
        /**
         Advances model game by one step and returns
         */
        switch goal {
            case .Begin:
                print("Model will look at discarded pile now:")
                let top_discarded = game.drawDiscardedCard(for: self)
                setCardOnHand(with: top_discarded)
                let (decision, replace_loc) = self.decideDraw(for: top_discarded)
                switch decision {
                    case true: // should replace
                        replaceCardInHand(in: game, at: replace_loc!, for: top_discarded)
                        goal = .Processed_All
                    case false: // Model does not want card on discarded pile
                        // move back top discarded to deck
                        game.discardPile.push(top_discarded)
                        goal = .Processed_Discarded
                }
            case .Processed_Discarded:
                print("Model looked at discarded, will look at Deck as well.")
                let top_deck = game.drawCard(for: self)
                let (decision, replace_loc) = self.decideDraw(for: top_deck)
                switch decision {
                    case true: // should replace
                        replaceCardInHand(in: game, at: replace_loc!, for: top_deck)
                        // ToDo: change player card
                    case false: // Model does not want card on deck pile
                        game.discardPile.push(top_deck)
                }
                goal = .Processed_All
            case .Processed_All:
                print("Model looked at Discarded pile and/or Deck")
                let decision = self.decideGame()
                if decision {
                    print("I knock")
                    goal = .DecideEnd
                } else {
                    goal = .DecideContinue
                }
                
            case .DecideContinue:
                print("Model has decided to continue")
                goal = .Begin
            
            case .DecideEnd:
                print("I am out of the game")
        }
    }
}
