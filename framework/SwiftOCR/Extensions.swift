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

extension Array where Element: _ArrayType, Element.Generator.Element: Any {
    func transpose() -> [Element] {
        if self.isEmpty { return [Element]() }
        let count = self[0].count
        var out = [Element](count: count, repeatedValue: Element())
        for outer in self {
            for (index, inner) in outer.enumerate() {
                out[index].append(inner)
            }
        }
        return out
    }
}

extension Array {
    mutating func shuffle() {
        for i in 0 ..< (count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            swap(&self[i], &self[j])
        }
    }
}