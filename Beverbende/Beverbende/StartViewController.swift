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
        gameRulesView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(segueToRules(_ :))))
        gameRulesView.isUserInteractionEnabled = true
        // Do any additional setup after loading the view.
    }
    
    
    @IBOutlet weak var startGameView: UIImageView!
    @IBOutlet weak var gameRulesView: UIImageView!
    
    @objc func segueToGame(_ recognizer: UITapGestureRecognizer) {
        switch recognizer.state {
        case .ended:
            performSegue(withIdentifier: "segueToGame", sender: self)
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
