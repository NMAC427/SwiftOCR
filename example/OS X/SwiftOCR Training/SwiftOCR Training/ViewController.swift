//
//  ViewController.swift
//  SwiftOCR Training
//
//  Created by Nicolas Camenisch on 02.05.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSTextFieldDelegate {

    @IBOutlet weak var fontsTableView: NSTableView!
    @IBOutlet weak var startTrainingButton: NSButton!
    @IBOutlet weak var addAllFontsButton: NSButton!
    @IBOutlet weak var charactersToTrainTextField: NSTextField!
    @IBOutlet weak var trainingProgressIndicator: NSProgressIndicator!
    
    @IBOutlet weak var accuracyLabel: NSTextField!
    
    var allFontNames      = [String]()
    var selectedFontNames = [String]()
    var isTraining        = false
    
    let trainingInstance  = SwiftOCRTraining()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        globalNetwork = FFNN(inputs: 321, hidden: 100, outputs: recognizableCharacters.characters.count, learningRate: 0.7, momentum: 0.4, weights: nil, activationFunction: .Sigmoid, errorFunction: .CrossEntropy(average: false))
        
        allFontNames = NSFontManager.sharedFontManager().availableFonts
        
        charactersToTrainTextField.delegate = self
        
        fontsTableView.reloadData()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return allFontNames.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn?.identifier == "0" {
            let cell = tableView.makeViewWithIdentifier("fontCell", owner: self) as! NSTableCellView
            let fontName = allFontNames[row]
            cell.textField?.stringValue = NSFont(name: fontName, size: 0)?.displayName ?? ""
            return cell
        } else {
            let cell = tableView.makeViewWithIdentifier("buttonCell", owner: self) as! ButtonTableCellView
            let fontName = allFontNames[row]
            
            if selectedFontNames.contains(fontName) {
                cell.button.integerValue = 1
            }
            
            cell.button.identifier = fontName
            
            return cell
        }
        
    }

    @IBAction func buttonTableCellViewButtonPressed(sender: NSButton) {
        if sender.integerValue == 0 {
            if let index = selectedFontNames.indexOf(sender.identifier ?? "") {
                selectedFontNames.removeAtIndex(index)
            }
        } else {
            if let fontName = sender.identifier {
                selectedFontNames.append(fontName)
            }
        }
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        //Generate new training network
        recognizableCharacters = Array(Set(charactersToTrainTextField.stringValue.characters.map({return String($0)}))).joinWithSeparator("")
        globalNetwork = FFNN(inputs: 321, hidden: 100, outputs: recognizableCharacters.characters.count, learningRate: 0.7, momentum: 0.4, weights: nil, activationFunction: .Sigmoid, errorFunction: .CrossEntropy(average: false))
    }
    
    @IBAction func saveButtonPressed(sender: NSButton) {
        trainingInstance.saveOCR()
    }
    
    @IBAction func startTrainingButtonPressed(sender: NSButton) {
        
        if isTraining {
            startTrainingButton.title = "Start Training"
            isTraining = false
            trainingProgressIndicator.stopAnimation(nil)
        } else {
            
            if selectedFontNames.isEmpty {
                return
            }
            
            startTrainingButton.title = "Stop Training"
            isTraining = true
            
            trainingProgressIndicator.startAnimation(nil)
            
            recognizableCharacters = Array(Set(charactersToTrainTextField.stringValue.characters.map({return String($0)}))).joinWithSeparator("")
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
                
                var callbackCount      = 0
                var minimumError:Float = Float.infinity {
                    didSet {
                        minimumError = min(oldValue, minimumError)
                    }
                }
                
                self.trainingInstance.trainingFontNames = self.selectedFontNames
                self.trainingInstance.trainWithCharSet() { error in
                    minimumError   = error
                    callbackCount += 1
                    
                    if !self.isTraining {
                        return false
                    } else if minimumError + 2 < error && callbackCount >= 150 {
                        return false
                    } else {
                        return true
                    }
   
                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    if self.isTraining == true {
                        self.startTrainingButton.title = "Start Training"
                        self.isTraining                = false
                        self.trainingProgressIndicator.stopAnimation(nil)
                    }
                })
                
            })
            
        }
        
    }

    @IBAction func addAllFontsButtonPressed(sender: NSButton) {
        if allFontNames == selectedFontNames {
            selectedFontNames.removeAll()
            addAllFontsButton.title = "Add all Fonts"
            fontsTableView.reloadData()
        } else {
            selectedFontNames = allFontNames
            addAllFontsButton.title = "Remove all Fonts"
            fontsTableView.reloadData()
        }
    }
    
    @IBAction func testButtonPressed(sender: NSButton) {
        startTrainingButton.title = "Start Training"
        isTraining = false

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.trainingInstance.testOCR() {accuracy in
                dispatch_async(dispatch_get_main_queue(), {
                    self.accuracyLabel.stringValue = "Accuracy: \(round(accuracy * 1000) / 10)%"
                })
            }
        })
    }
}

