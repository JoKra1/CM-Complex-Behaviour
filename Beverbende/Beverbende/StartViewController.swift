//
//  StartViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 15/03/2021.
//

import UIKit

class StartViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        startGameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(segueToGame(_ :))))
        startGameView.isUserInteractionEnabled = true
        settingsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(segueToSettings(_:))))
        settingsView.isUserInteractionEnabled = true
        gameRulesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(segueToRules(_ :))))
        gameRulesView.isUserInteractionEnabled = true
        // Do any additional setup after loading the view.
    }
    
    
    @IBOutlet weak var startGameView: UIImageView!
    @IBOutlet weak var settingsView: UIImageView!
    @IBOutlet weak var gameRulesView: UIImageView!
    
    @objc func segueToGame(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            performSegue(withIdentifier: "segueToGame", sender: self)
        default:
            break
        }
    }
    
    @objc func segueToSettings(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            performSegue(withIdentifier: "segueToSettings", sender: self)
        default:
            break
        }
    }
    
    @objc func segueToRules(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            performSegue(withIdentifier: "segueToRules", sender: self)
        default:
            break
        }
    }
    
    var activationNoise = 0.2 // Default value
    var utilityNoise = 0.2 // Default value
    var frozen = false // Default value
    var pretrained = true // Default value
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToSettings" {
            /*
            guard let settingsViewController = segue.destination as? SettingsViewController else { return }
            settingsViewController.activationNoise = self.activationNoise
            settingsViewController.utilityNoise = self.utilityNoise
            settingsViewController.frozen = self.frozen
            settingsViewController.pretrained = self.pretrained
            */
            // Now all handled by defaults.
            ()
        } else if segue.identifier == "segueToGame" {
        guard let gameViewController = segue.destination as? ViewController else { return }
            gameViewController.activationNoise = self.activationNoise
            gameViewController.utilityNoise = self.utilityNoise
            gameViewController.frozen = self.frozen
            gameViewController.pretrained = self.pretrained
        }
    }


}
