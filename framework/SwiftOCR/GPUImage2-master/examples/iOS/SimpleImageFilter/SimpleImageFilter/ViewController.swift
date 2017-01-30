import UIKit
import GPUImage

class ViewController: UIViewController {
    
    @IBOutlet weak var renderView: RenderView!

    var picture:PictureInput!
    var filter:SaturationAdjustment!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Filtering image for saving
        var input1 = UIImage(named:"WID-small.jpg")
        var input2 = UIImage(named:"Lambeau.jpg")
        
        //let input1 = PictureInput(imageName:"WID-small.jpg")
        //let input2 = PictureInput(imageName:"Lambeau.jpg")
        
        let alphaBlend = AlphaBlend()
        
        //input1.addTarget(alphaBlend)
        //input2.addTarget(alphaBlend)
        //alphaBlend.addTarget(input1)
        //alphaBlend.addTarget(input2)
        alphaBlend.mix = 0.5;
        
        //input1.processImage(synchronously: true)
        //input2.processImage(synchronously: true)
        
        
        input1 = input1?.filterWithOperation(alphaBlend)
        input2 = input2?.filterWithOperation(alphaBlend)
        
        //let output = PictureOutput();
        //output.encodedImageFormat = PictureFileFormat.png
        
        //output.imageAvailableCallback = {image in
            // Do something with the image
            //UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        //    print("Ret2")
       //}
        
        //input1 -->  alphaBlend
        //input2 --> alphaBlend --> output
        
        //input1.processImage(synchronously: true)
        //input2.processImage(synchronously: true)
        
        // Filtering image for display
        ///picture = PictureInput(image:UIImage(named:"WID-small.jpg")!)
        //filter = SaturationAdjustment()
        //picture --> filter --> renderView
        //picture.processImage()
        
        print("Ret1", input2)
    }
}

