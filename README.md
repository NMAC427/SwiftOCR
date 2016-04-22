# SwiftOCR

SwiftOCR is a fast and simple OCR library written in Swift. It uses a neural network for image recognition.
As of now, the SwiftOCR is optimized for recognizing short, one line long alphanumeric codes (e.g. DI4C9CM). We currently  support iOS and OS X. 

## Features
- [x] Easy to use training class
- [x] High accuracy
- [ ] Fast and accurate character segmentation algorithm
- [ ] Add support for lowercase characters

## How does it work?

First, SwiftOCR binarizes the input image. Afterwards it extracts the characters of the image using a technique called [Connected-component labeling](https://en.wikipedia.org/wiki/Connected-component_labeling). Finally the seperated characters get converted into numbers which then get feed into the neural network.

## How to use it?

If you ever used Tesseract you know how exhausting it can be to implement OCR into your project. 
SwiftOCR is the exact opposite of Tesseract. It can be implemented using **just 6 lines of code**. 

```swift
import SwiftOCR

let swiftOCRInstance   = SwiftOCR()
swiftOCRInstance.image = myImage
    
swiftOCRInstance.recognize({recognizedString in
    print(recognizedString)
})
```


### Dependencies

* [Swift-AI](https://github.com/collinhundley/Swift-AI)
* [GPUImage](https://github.com/BradLarson/GPUImage)
* [Union-Find](https://github.com/hollance/swift-algorithm-club/tree/master/Union-Find)

### License

    The code in this repository is licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

**NOTE**: This software depends on other packages that may be licensed under different open source licenses.
