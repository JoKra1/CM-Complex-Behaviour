//
//  newGameViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 08/04/2021.
//

import UIKit

class newGameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2){
            self.segueToNewGame()
        }
        // Do any additional setup after loading the view.
    }
    
    func segueToNewGame(){
        performSegue(withIdentifier: "segueToGameFromLogo", sender: self)
    }
    

}
