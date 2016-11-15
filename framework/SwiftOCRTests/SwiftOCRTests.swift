//
//  SwiftOCRTests.swift
//  SwiftOCRTests
//
//  Created by Nicolas Camenisch on 21.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import XCTest
@testable import SwiftOCR

class SwiftOCRTests: XCTestCase {
    
    #if os(iOS)
    let testImageOne   = OCRImage(contentsOfFile: Bundle(for: SwiftOCR.self).path(forResource: "Test 1", ofType: "png")!)!
    let testImageTwo   = OCRImage(contentsOfFile: Bundle(for: SwiftOCR.self).path(forResource: "Test 2", ofType: "png")!)!
    let testImageThree = OCRImage(contentsOfFile: Bundle(for: SwiftOCR.self).path(forResource: "Test 3", ofType: "png")!)!
    #else
    let testImageOne   = OCRImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 1.png")!)!
    let testImageTwo   = OCRImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 2.png")!)!
    let testImageThree = OCRImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 3.png")!)!
    #endif
    
    override class func setUp() {
        super.setUp()
        // Called once before all tests are run
        let _ = globalNetwork //Load network from file
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBigImageSwiftOCR() {

        self.measure({
            let expection = self.expectation(description: "testSingleSwiftOCR Expection")
            
            let _ = SwiftOCR(image: self.testImageThree, delegate: nil, { recognizedString in
                expection.fulfill()
            })
            
            self.waitForExpectations(timeout: 50, handler: nil)
        })
        
    }
    
    func testSingleSwiftOCR() {

        self.measure({
            let expection = self.expectation(description: "testSingleSwiftOCR Expection")
            
            let _ = SwiftOCR(image: self.testImageTwo, delegate: nil, { recognizedString in
                XCTAssertEqual(recognizedString, "AB84ENS91")
                expection.fulfill()
            })
            
            self.waitForExpectations(timeout: 10, handler: nil)
        })
        
    }
    
    func testMultipleSwiftOCR() {

        self.measure({
            let expectionOne = self.expectation(description: "testMultipleSwiftOCR Expection One")
            let expectionTwo = self.expectation(description: "testMultipleSwiftOCR Expection Two")
            
            let _ = SwiftOCR(image: self.testImageOne, delegate: nil, { recognizedString in
                XCTAssertEqual(recognizedString, "GSYCNP")
                expectionOne.fulfill()
            })
            
            let _ = SwiftOCR(image: self.testImageTwo, delegate: nil, { recognizedString in
                XCTAssertEqual(recognizedString, "AB84ENS91")
                expectionTwo.fulfill()
            })

            self.waitForExpectations(timeout: 20, handler: nil)
        })
        
    }
    
    func testExtractBlobs() {
        let ocrInstance = SwiftOCR
        let preprocessedImage = ocrInstance.preprocessImageForOCR(self.testImageOne)
        
        measure({
            let extractedBlobs = ocrInstance.extractBlobs(preprocessedImage)
            XCTAssertEqual(extractedBlobs.count, 6)
        })
    }
    
    func testConvertImageToFloatArray() {
        let ocrInstance = SwiftOCR
        
        measure({
            let _ = ocrInstance.convertImageToFloatArray(self.testImageOne, resize: false)
        })
    }
    
    func testConvertImageToFloatArrayWithResize() {
        let ocrInstance = SwiftOCR
        
        measure({
            let _ = ocrInstance.convertImageToFloatArray(self.testImageOne, resize: true)
        })
    }
    
    func testPreprocessImageForOCR() {
        let ocrInstance = SwiftOCR
        
        measure({
            let _ = ocrInstance.preprocessImageForOCR(self.testImageOne)
        })
    }

}
