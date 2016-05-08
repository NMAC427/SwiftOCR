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

public extension FFNN {
    public func copy() -> FFNN {
        return FFNN.init(inputs: self.numInputs, hidden: self.numHidden, outputs: self.numOutputs, learningRate: self.learningRate, momentum: self.momentumFactor, weights: self.getWeights(), activationFunction: self.activationFunction, errorFunction: self.errorFunction)
    }
}