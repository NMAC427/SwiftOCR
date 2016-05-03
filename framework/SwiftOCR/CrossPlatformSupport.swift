//
//  CrossPlatformSupport.swift
//  SwiftOCR
//
//  Created by Jason R Tibbetts on 5/1/16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

#if os(iOS)
    import UIKit
    public typealias OCRColor   = UIColor
    public typealias OCRFont    = UIFont
    public typealias OCRImage   = UIImage
#else
    import Cocoa
    public typealias OCRColor   = NSColor
    public typealias OCRFont    = NSFont
    public typealias OCRImage   = NSImage
#endif
