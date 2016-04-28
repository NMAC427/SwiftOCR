//
//  SwiftOCRBlobUnionFind
//  SwiftOCR
//
//  Created by Nicolas Camenisch on 21.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import Foundation

internal struct SwiftOCRBlobUnionFind {
    var unionSet = Set<Set<Int>>()
    
    mutating func insertElement(element: Int) {
        unionSet.insert([element])
    }
    
    mutating func insertElement(element: UInt16) {
        unionSet.insert([Int(element)])
    }
    
    mutating func flattenInPlace() {
        //Pass One
        for unionSubSetOne in unionSet {
            for unionSubSetTwo in unionSet {
                for unionSubSetTwoContent in unionSubSetTwo {
                    if unionSubSetOne.contains(unionSubSetTwoContent) {
                        var newUnionSubSet = unionSubSetOne
                        
                        unionSet.remove(unionSubSetOne)
                        unionSet.remove(unionSubSetTwo)
                        
                        newUnionSubSet.unionInPlace(unionSubSetTwo)
                        
                        unionSet.insert(newUnionSubSet)
                    }
                }
            }
        }
        
        //Pass Two
        for unionSubSetOne in unionSet {
            for unionSubSetTwo in unionSet {
                for unionSubSetTwoContent in unionSubSetTwo {
                    if unionSubSetOne.contains(unionSubSetTwoContent) {
                        var newUnionSubSet = unionSubSetOne
                        
                        unionSet.remove(unionSubSetOne)
                        unionSet.remove(unionSubSetTwo)
                        
                        newUnionSubSet.unionInPlace(unionSubSetTwo)
                        
                        unionSet.insert(newUnionSubSet)
                    }
                }
            }
        }
    }
    
    mutating func combineSetContaining(containingA: Int, with containingB: Int) {
        
        for unionSubSet in unionSet {
            if unionSubSet.contains(containingA) {
                var newUnionSubSet = unionSubSet
                
                unionSet.remove(unionSubSet)
                newUnionSubSet.insert(containingB)
                unionSet.insert(newUnionSubSet)
            }
        }
    }
    
    mutating func combineSetContaining(containingA: UInt16, with containingB: UInt16) {
        
        for unionSubSet in unionSet {
            if unionSubSet.contains(Int(containingA)) {
                var newUnionSubSet = unionSubSet
                
                unionSet.remove(unionSubSet)
                newUnionSubSet.insert(Int(containingB))
                unionSet.insert(newUnionSubSet)
            }
        }
    }
    
    func indexOfElement(element: Int) -> Int?{
        var index:Int? = nil
        
        for unionSubSet in unionSet {
            if unionSubSet.contains(element) {
                index = unionSet.startIndex.distanceTo((unionSet.indexOf(unionSubSet)?.successor())!) - 1
                break
            }
        }
        
        return index
    }
    
    func indexOfElement(element: UInt16) -> Int?{
        var index:Int? = nil
        
        for unionSubSet in unionSet {
            if unionSubSet.contains(Int(element)) {
                index = unionSet.startIndex.distanceTo((unionSet.indexOf(unionSubSet)?.successor())!) - 1
                break
            }
        }
        
        return index
    }
    
}