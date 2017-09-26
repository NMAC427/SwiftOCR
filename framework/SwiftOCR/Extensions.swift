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





extension Array where Element: Collection, Element.Index == Int, Element.IndexDistance == Int, Element.Iterator.Element: Any {
    func transpose() -> [[Element.Iterator.Element]] {
        if self.isEmpty { return [] }
        
        typealias InnerElement = Element.Iterator.Element
        
        let count = self[0].count
        var out = [[InnerElement]](repeating: [InnerElement](), count: count)
        for outer in self {
            for (index, inner) in outer.enumerated() {
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
            self.swapAt(i, j)
        }
    }
}
