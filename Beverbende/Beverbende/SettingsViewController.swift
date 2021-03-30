//
//  SettingsViewController.swift
//  Beverbende
//
//  Created by Chiel Wijs on 30/03/2021.
//

import Foundation
import UIKit
// Source for default handling: https://www.hackingwithswift.com/read/12/2/reading-and-writing-basics-userdefaults

class SettingsViewController: UIViewController {

    let defaults = UserDefaults.standard
    override func viewDidLoad() {
        super.viewDidLoad()
        setSlidersAndSwitches()
        // Do any additional setup after loading the view.
    }
    
    func setDefaults() {
        activationNoise = 0.2 // Default value
        utilityNoise = 0.2 // Default value
        frozen = false // Default value
        pretrained = true // Default value
    }
    
    var activationNoise: Double {
        get {
                
                let noise = defaults.double(forKey:"activationNoise")
                return noise
            }
        set (new) {
            defaults.set(new,forKey: "activationNoise")
        }
    }
                                
    var utilityNoise: Double {
        get {
                
                let noise = defaults.double(forKey:"utilityNoise")
                return noise
            }
        set (new) {
            defaults.set(new,forKey: "utilityNoise")
        }
    }
    
    var frozen: Bool {
        get {
                let frozen = defaults.bool(forKey:"frozen")
                return frozen
            }
        set (new) {
            defaults.set(new,forKey: "frozen")
        }
    }
    
    var pretrained: Bool {
        get {
                let pretrained = defaults.bool(forKey:"pretrained")
                return pretrained
            }
        set (new) {
            defaults.set(new,forKey: "pretrained")
        }
    }
    
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
    
    func setSlidersAndSwitches() {
        activationSlider.setValue(Float(activationNoise), animated: true)
        utilitySlider.setValue(Float(utilityNoise), animated: true)
        frozenSwitch.setOn(frozen, animated: true)
        pretrainedSwitch.setOn(pretrained, animated: true)
    }
    
    
    @IBAction func setDefaultSettings(_ sender: UIButton) {
        setDefaults()
        setSlidersAndSwitches()
    }
    
    
    @IBAction func sequeToMain(_ sender: UIButton) {
        performSegue(withIdentifier: "segueToMainFromSettings", sender: self)
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMainFromSettings" {
            /*
            guard let startViewController = segue.destination as? StartViewController else { return }
            startViewController.activationNoise = self.activationNoise
            startViewController.utilityNoise = self.utilityNoise
            startViewController.frozen = self.frozen
            startViewController.pretrained = self.pretrained
             */
            ()
        }
    }


}
