//
//  Extensions.swift
//  SwiftOCR
//
//  Created by Nicolas Camenisch on 21.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import Foundation

internal extension Array where Element: Hashable {
    
    func uniq() -> [Element] {
        return Array(Set(self))
    }
    
    mutating func uniqInPlace() {
        self = Array(Set(self))
    }
}