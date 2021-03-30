//
//  SettingsViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 30/03/2021.
//

import UIKit



class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        activationSlider.setValue(Float(activationNoise), animated: true)
        utilitySlider.setValue(Float(utilityNoise), animated: true)
        frozenSwitch.setOn(frozen, animated: true)
        pretrainedSwitch.setOn(pretrained, animated: true)
        // Do any additional setup after loading the view.
    }
    
    var activationNoise = 0.2 // Default value
    var utilityNoise = 0.2 // Default value
    var frozen = false // Default value
    var pretrained = true // Default value
    
    @IBOutlet weak var activationSlider: UISlider!
    @IBOutlet weak var utilitySlider: UISlider!
    @IBOutlet weak var frozenSwitch: UISwitch!
    @IBOutlet weak var pretrainedSwitch: UISwitch!
    
    @IBAction func noiseSliderChanged(_ sender: UISlider) {
        activationNoise = Double(sender.value)
    }
    
    @IBAction func utilitySliderChanged(_ sender: UISlider) {
        utilityNoise = Double(sender.value)
    }
  
    @IBAction func frozenSwitchChanged(_ sender: UISwitch) {
        frozen = sender.isOn
    }
    
    @IBAction func pretrainedSwitchChanged(_ sender: UISwitch) {
        pretrained = sender.isOn
    }
    
    
    @IBAction func sequeToMain(_ sender: UIButton) {
        performSegue(withIdentifier: "segueToMainFromSettings", sender: self)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMainFromSettings" {
            guard let startViewController = segue.destination as? StartViewController else { return }
            startViewController.activationNoise = self.activationNoise
            startViewController.utilityNoise = self.utilityNoise
            startViewController.frozen = self.frozen
            startViewController.pretrained = self.pretrained
        }
    }


}
