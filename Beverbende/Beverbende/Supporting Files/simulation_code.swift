//
//  simulation_code.swift
//  Beverbende
//
//  Created by Joshua Krause on 10.04.21.
//

import Foundation

/*
 Below is a copy of the view-controller code that was used to run the simulations.
 */

/*
 
 //
 //  ViewController.swift
 //  Beverbende
 //
 //

 import UIKit

 enum simulationType{
     case allLearners, singleLearner, longterm
 }

 class ViewController: UIViewController {
     
     func createCSV(from data:[[String:Double]], file name: String) {
         // Source: https://stackoverflow.com/questions/55870174/how-to-create-a-csv-file-using-swift
             var csvString = "\("Run"),\("Game"),\("Turns"),\("Learner"),\("Winner"),\("Util11"),\("Util21"),\("Util31"),\("Util12"),\("Util22"),\("Util32"),\("Util13"),\("Util23"),\("Util33"),\("Util14"),\("Util24"),\("Util34")\n\n"
             for dct in data {
                 csvString = csvString.appending("\(dct["Run"]!),\(dct["Game"]!) ,\(dct["Turns"]!),\(dct["Learner"]!),\(dct["Winner"]!),\(dct["Util11"]!),\(dct["Util21"]!),\(dct["Util31"]!),\(dct["Util12"]!),\(dct["Util22"]!),\(dct["Util32"]!),\(dct["Util13"]!),\(dct["Util23"]!),\(dct["Util33"]!),\(dct["Util14"]!),\(dct["Util24"]!),\(dct["Util34"]!)\n")
             }

             let fileManager = FileManager.default
             do {
                 
                 let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
                 print(path)
                 let fileURL = path.appendingPathComponent(name + ".csv")
                 try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
             } catch {
                 print("error creating file")
             }

         }
     
     let sim = simulationType.singleLearner
     var game:Beverbende?
     var learner = 0
     @IBAction func trigger(_ sender: UIButton) {
         
         
         // Play multiple games over multiple runs
         
         for run in 1..<2 {
             var gameData = [[String:Double]]()
             var turns = 0
             var previousTime = 0.0

             for g in 1..<1000{
                 game!.currentPlayerIndex = -1
                 while !game!.gameEnded {
                     previousTime = game!.nextPlayer(previous: previousTime)
                     //sleep(2)
                     turns += 1
                 }
                 print("Run \(run) Game \(g) ended after \(turns) with Learner \(learner)")
                 let winner = game!.winner!
                 // Data collection
                 var gameDict = [String:Double]()
                 gameDict["Run"] = Double(run)
                 gameDict["Game"] = Double(g)
                 gameDict["Turns"] = Double(turns)
                 gameDict["Learner"] = Double(learner + 1)
                 
                 if winner == "1" {
                     gameDict["Winner"] = 1.0
                 } else if winner == "2" {
                     gameDict["Winner"] = 2.0
                 } else if winner == "3" {
                     gameDict["Winner"] = 3.0
                 } else if winner == "4" {
                     gameDict["Winner"] = 4.0
                 }
                 
                 let model1 = game!.players[0] as! BeverbendeOpponent
                 let model2 = game!.players[1] as! BeverbendeOpponent
                 let model3 = game!.players[2] as! BeverbendeOpponent
                 let model4 = game!.players[3] as! BeverbendeOpponent
                 
                 gameDict["Util11"] = model1.utilities[0]
                 gameDict["Util21"] = model1.utilities[1]
                 gameDict["Util31"] = model1.utilities[2]
                 
                 gameDict["Util12"] = model2.utilities[0]
                 gameDict["Util22"] = model2.utilities[1]
                 gameDict["Util32"] = model2.utilities[2]
                 
                 gameDict["Util13"] = model3.utilities[0]
                 gameDict["Util23"] = model3.utilities[1]
                 gameDict["Util33"] = model3.utilities[2]
                 
                 gameDict["Util14"] = model4.utilities[0]
                 gameDict["Util24"] = model4.utilities[1]
                 gameDict["Util34"] = model4.utilities[2]
                 
                 gameData.append(gameDict)
                 
                 
                 // Resetting
                 
                 game!.reset(except: learner)
                 turns = 0
             }
             
             createCSV(from: gameData, file: "sim" + String(run))
             
             // Reinitialize game after 1000 games for new run
             var opponents = [String]()
             for i in 1..<5 {
                 opponents.append(String(i))
             }
             self.game = Beverbende(cognitiveIds: opponents)
             if sim == .singleLearner {
                 learner = Int.random(in: 0...3)
                 game!.freezeOpponents(except: learner)
             }
             
         }
    
     }
     
     override func viewDidLoad() {
         var opponents = [String]()
         for i in 1..<5 {
             opponents.append(String(i))
         }
         self.game = Beverbende(cognitiveIds: opponents)
         
         if sim == .singleLearner {
             learner = Int.random(in: 0...3)
             game!.freezeOpponents(except: learner)
         }
         
     }
     
 }
 
// The game freeze opponents method:
 
 func freezeOpponents(except learner:Int) {
     /**
      Freeze all opponents except the learner
      */
     for index in 0...3 {
         if !(index == learner) {
             (players[index] as! BeverbendeOpponent).frozen = true
         }
     }
 }

// The game reset method:
 
 func reset(except learner:Int) {
     self.winner = nil
     self.currentPlayerIndex = 0
     self.knocked = false
     self.gameEnded = false
     self.countdown = 0
     self.discardPile = Stack<Card>()
     
     self.drawPile = Stack<Card>(initialArray: Beverbende.allCards().shuffled())
     self.discardPile.push(self.drawPile.pop()!)
     
     for player in players {
         var cards: [Card?] = []
         for _ in 0..<4 {
             cards.append(self.drawPile.pop()!)
         }
         player.setCardsOnTable(with: cards)
     }
 
     for index in 0...3 {
         if !(index == learner) {
             let model = players[index] as! BeverbendeOpponent
             model.wipeMemory()
         }
     }
 }
 
 
 */
