//
//  rulesViewController.swift
//  Beverbende
//
//  Created by C. Wijs on 24/03/2021.
//

import UIKit

class rulesViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        configureRulesText()
    }
    
    @IBOutlet weak var rulesText: UITextView!
    
    func configureRulesText() {
        rulesText.text = "Hi!"
        rulesText.textColor = .secondaryLabel
        rulesText.backgroundColor = .secondarySystemBackground
        rulesText.layer.cornerRadius = 20
        
        rulesText.layer.shadowColor = UIColor.gray.cgColor;
        rulesText.layer.shadowOffset = CGSize(width: 0.75, height: 0.75)
        rulesText.layer.shadowOpacity = 0.4
        rulesText.layer.shadowRadius = 20
        rulesText.layer.masksToBounds = false
    
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
