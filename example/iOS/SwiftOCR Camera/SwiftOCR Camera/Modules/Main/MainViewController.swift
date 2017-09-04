//
//  ViewController.swift
//  SwiftOCR Camera
//
//  Created by Nicolas Camenisch on 04.05.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import UIKit

extension UIImage {
    func detectOrientationDegree () -> CGFloat {
        switch imageOrientation {
        case .right, .rightMirrored:    return 90
        case .left, .leftMirrored:      return -90
        case .up, .upMirrored:          return 180
        case .down, .downMirrored:      return 0
        }
    }
}

class MainViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var viewFinder: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var topLabel: UILabel!
    var arLabel: UILabel!
    
    var presenter: MainPresenter?
    
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        arLabel = UILabel()
        arLabel.sizeToFit()
        self.viewFinder.addSubview(arLabel)
        arLabel.isHidden = true
        // start camera init
        self.presenter?.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.arLabel.isHidden = SettingsManager.shared.arOn
        self.arLabel.text = nil
        self.arLabel.sizeToFit()
        self.topLabel.isHidden = !SettingsManager.shared.arOn
        self.topLabel.text = nil
        self.topLabel.sizeToFit()
        
        self.view.layoutIfNeeded()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.presenter?.viewWillDisappear(animated)
    }
    // MARK: - IBActions
    @IBAction func takePhotoButtonPressed (_ sender: UIButton) {
        self.presenter?.takePhoto()
    }
    
    @IBAction func settingsButtonPressed (_ sender: UIButton) {
        self.presenter?.openSettings()
    }
    
    @IBAction func sliderValueDidChange(_ sender: UISlider) {
        self.presenter?.sliderValueDidChange(CGFloat(slider.value * 10.0))
    }
    
    func updateLabelWithResult(_ recognizedString: String,  result: Double, rect: CGRect) {
        if SettingsManager.shared.arOn == true {
            self.arLabel.isHidden = false
            self.topLabel.isHidden = true
            self.arLabel.font = UIFont(name: "HelveticaNeue", size: rect.size.height)
            self.arLabel.text = String(format: " = %g", result)
            self.arLabel.sizeToFit()
            self.arLabel.frame = CGRect(x: rect.origin.x + rect.width, y: rect.origin.y, width: self.arLabel.frame.size.width, height: self.arLabel.frame.size.height)
        } else {
            self.arLabel.isHidden = true
            self.topLabel.isHidden = false
            self.arLabel.sizeToFit()
            self.topLabel.text = "\(recognizedString) = \(result)"
        }
    }
    
    
    func updateLabelWithError(_ error: String) {
        if SettingsManager.shared.arOn == true {
            self.arLabel.isHidden = false
            self.topLabel.isHidden = true
            self.arLabel.text = "\(error)"
        } else {
            self.arLabel.isHidden = true
            self.topLabel.isHidden = false
            self.topLabel.text = "\(error)"
        }
    }
    
    func takeSnapshotOfView(view: UIView) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: view.frame.size.width, height: view.frame.size.height))
        view.drawHierarchy(in: CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    func saveSnapshotImage() {
        let window = UIApplication.shared.windows.first
        UIImageWriteToSavedPhotosAlbum(self.takeSnapshotOfView(view: window!)!, nil, nil, nil);
    }
}
