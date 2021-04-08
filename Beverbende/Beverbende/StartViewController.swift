//
//  StartViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 15/03/2021.
//

import UIKit

class StartViewController: UIViewController {
    let defaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        startGameView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(segueToGame(_ :))))
        startGameView.isUserInteractionEnabled = true
        settingsView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(segueToSettings(_:))))
        settingsView.isUserInteractionEnabled = true
        gameRulesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(segueToRules(_ :))))
        gameRulesView.isUserInteractionEnabled = true
        
        // Check whether user has ever used the app
        let hasCustomized = defaults.bool(forKey: "hasCustomized")
        
        if !hasCustomized{
            defaults.set(0.1,forKey: "activationNoise")
            defaults.set(0.2,forKey: "utilityNoise")
            defaults.set(false,forKey: "frozen")
            defaults.set(true,forKey: "pretrained")
            defaults.set(true,forKey: "hasCustomized")
            defaults.set(true,forKey: "changedModelSettings")
        }
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
    
}
