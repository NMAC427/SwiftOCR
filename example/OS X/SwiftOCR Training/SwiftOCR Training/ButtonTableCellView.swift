//
//  ButtonTableCellView.swift
//  SwiftOCR Training
//
//  Created by Nicolas Camenisch on 02.05.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import Cocoa

class ButtonTableCellView: NSTableCellView {
    @IBOutlet weak var button: NSButton!

    override func prepareForReuse() {
        button.integerValue = 0
        button.identifier   = NSUserInterfaceItemIdentifier(rawValue: "")
    }
    
}

