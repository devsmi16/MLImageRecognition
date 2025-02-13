import UIKit
import Vision
import CoreML

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var progressIndicator: UIActivityIndicatorView!
    
    var chosenImage = CIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        progressIndicator.isHidden = true
    }

    @IBAction func changeClicked(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        self.dismiss(animated: true, completion: nil)

        if let ciImage = CIImage(image: imageView.image!) {
            chosenImage = ciImage
        }

        recognizeImage(image: chosenImage)
    }

    func recognizeImage(image: CIImage) {
        
        resultLabel.text = "finding..."
        resultLabel.textColor = .gray
        progressIndicator.isHidden = false
        progressIndicator.startAnimating()

        if let model = try? VNCoreMLModel(for: MobileNetV2().model) {
            let request = VNCoreMLRequest(model: model) { (request, error) in
                DispatchQueue.main.async {
                    self.progressIndicator.stopAnimating()
                    self.progressIndicator.isHidden = true
                }
                
                if let results = request.results as? [VNClassificationObservation], results.count > 0 {
                    let topResult = results.first
                    
                    DispatchQueue.main.async {
                        let confidenceLevel = (topResult?.confidence ?? 0) * 100
                        let rounded = Int(confidenceLevel * 100) / 100
                        
                        // Yüksek güvenle sonuçları yeşil, düşük güvenle kırmızı yapalım
                        if rounded > 80 {
                            self.resultLabel.textColor = .green
                        } else {
                            self.resultLabel.textColor = .red
                        }
                        
                        self.resultLabel.text = "\(rounded)% - \(String(describing: topResult?.identifier))"
                    }
                } else {
                    DispatchQueue.main.async {
                        self.resultLabel.textColor = .red
                        self.resultLabel.text = "Sonuç bulunamadı"
                    }
                }
            }

            let handler = VNImageRequestHandler(ciImage: image)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    print("Error performing image recognition")
                }
            }
        }
    }
}
