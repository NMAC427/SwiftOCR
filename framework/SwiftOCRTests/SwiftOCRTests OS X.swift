//
//  SwiftOCRTests.swift
//  SwiftOCRTests
//
//  Created by Nicolas Camenisch on 21.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import XCTest
import SwiftOCR

class SwiftOCRTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSingleSwiftOCR() {
        let testImage = NSImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 2.png")!)!
        
        self.measureBlock({
            let expection = self.expectationWithDescription("testSingleSwiftOCR Expection")
            
            let swiftOCRInstance = SwiftOCR()
            swiftOCRInstance.image = testImage
            swiftOCRInstance.recognize({ recognizedString in
                XCTAssertEqual(recognizedString, "AB84ENS91")
                expection.fulfill()
            })
            self.waitForExpectationsWithTimeout(10, handler: nil)
        })
        
    }
    
    func testMultipleSwiftOCR() {
        let testImageOne = NSImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 1.png")!)!
        let testImageTwo = NSImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 2.png")!)!
        
        self.measureBlock({
            let expectionOne = self.expectationWithDescription("testMultipleSwiftOCR Expection One")
            let expectionTwo = self.expectationWithDescription("testMultipleSwiftOCR Expection Two")
            
            let swiftOCRInstanceOne = SwiftOCR()
            swiftOCRInstanceOne.image = testImageOne
            
            swiftOCRInstanceOne.recognize({ recognizedString in
                XCTAssertEqual(recognizedString, "GSYCNP")
                expectionOne.fulfill()
            })
            
            let swiftOCRInstanceTwo = SwiftOCR()
            swiftOCRInstanceTwo.image = testImageTwo
            
            swiftOCRInstanceTwo.recognize({ recognizedString in
                XCTAssertEqual(recognizedString, "AB84ENS91")
                expectionTwo.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(10, handler: nil)
        })
        
    }
    
    func testFFNNCopy() {
        
        let testNetwork = FFNN(inputs: 321, hidden: 100, outputs: 36, learningRate: 0.7, momentum: 0.4, weights: nil, activationFunction: .Sigmoid, errorFunction: .CrossEntropy(average: false))
        
        self.measureBlock({
            testNetwork.copy()
        })
    }
    
}
