import UIKit
import QRCodeReader
import CoreImage

final class ViewController: UIViewController {

    @IBOutlet fileprivate var readerView: QRCodeReaderView!

    @IBOutlet fileprivate var qrMessageLabel: UILabel!

    @IBOutlet fileprivate var featuresCountLabel: UILabel!
    @IBOutlet fileprivate var qrRawMessageLabel: UILabel!
    @IBOutlet private var qrBoundsLabel: UILabel!
    @IBOutlet private var qrBottomLeftLabel: UILabel!
    @IBOutlet private var qrBottomRightLabel: UILabel!
    @IBOutlet private var qrTopLeftLabel: UILabel!
    @IBOutlet private var qrTopRightLabel: UILabel!

    @IBOutlet private var detectionAreaSlider: UISlider!
    @IBOutlet private var detectionAreaLabel: UILabel!
    @IBOutlet private var detectionScaleSlider: UISlider!
    @IBOutlet private var detectionScaleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        readerView?.delegate = self
        readerView?.detectionAreaMaskColor = .grayTransparent

        let area = Float(readerView?.detectionInsetX ?? 0.0)
        detectionAreaLabel.text = String(format: "%.2f", area)
        detectionAreaSlider.value = area

        let scale = Float(readerView?.detectionScale ?? 0.0)
        detectionScaleLabel.text = String(format: "%.2f", scale)
        detectionScaleSlider.value = scale

        updateQRBoundsLabels() // Optional
    }

    @IBAction private func touchUpInsideStartButton(_ sender: UIButton) {
        readerView?.startReading()
    }

    @IBAction private func touchUpInsideStopButton(_ sender: UIButton) {
        readerView?.stopReading()
    }

    @IBAction private func valueChangedDetectionAreaSlider(_ sender: UISlider) {
        detectionAreaLabel.text = String(format: "%.2f", sender.value)
        let inset = CGFloat(sender.value)
        readerView?.detectionInsetX = inset
        readerView?.detectionInsetY = inset
    }

    @IBAction private func valueChangedDetectionScaleSlider(_ sender: UISlider) {
        detectionScaleLabel.text = String(format: "%.2f", sender.value)
        let scale = CGFloat(sender.value)
        readerView?.detectionScale = scale
    }

    // Optional
    fileprivate func updateQRBoundsLabels(features: [CIFeature] = []) {
        featuresCountLabel.text = "\(features.count)"

        let feature: CIQRCodeFeature?
        if features.count != 1 {
            qrRawMessageLabel.text = "-"
            feature = nil
        } else {
            if let f = features.last as? CIQRCodeFeature {
                if let message = f.messageString {
                    self.qrRawMessageLabel.text = message
                } else {
                    self.qrRawMessageLabel.text = "-"
                }
                feature = f
            } else {
                qrRawMessageLabel.text = "-"
                feature = nil
            }
        }

        let bounds: CGRect
        let bottomLeft: CGPoint
        let bottomRight: CGPoint
        let topLeft: CGPoint
        let topRight: CGPoint
        if let feature = feature {
            bounds = feature.bounds
            bottomLeft = feature.bottomLeft
            bottomRight = feature.bottomRight
            topLeft = feature.topLeft
            topRight = feature.topRight
        } else {
            bounds = .zero
            bottomLeft = .zero
            bottomRight = .zero
            topLeft = .zero
            topRight = .zero
            qrRawMessageLabel.text = "-"
        }

        qrBoundsLabel.text = String(format: "x: %06.2f, y: %06.2f, w: %06.2f, h: %06.2f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height)
        qrBottomLeftLabel.text = String(format: "x: %06.2f, y: %06.2f", bottomLeft.x, bottomLeft.y)
        qrBottomRightLabel.text = String(format: "x: %06.2f, y: %06.2f", bottomRight.x, bottomRight.y)
        qrTopLeftLabel.text = String(format: "x: %06.2f, y: %06.2f", topLeft.x, topLeft.y)
        qrTopRightLabel.text = String(format: "x: %06.2f, y: %06.2f", topRight.x, topRight.y)
    }

}

extension ViewController: QRCodeReaderViewDelegate {

    func qrCodeReaderViewDidUpdateMessageString(_ sender: QRCodeReaderView) {
        qrMessageLabel.text = sender.messageString
        if let _ = sender.messageString {
            sender.detectionAreaMaskColor = .random
        } else {
            sender.detectionAreaMaskColor = .grayTransparent
        }
    }

    // Optional
    func qrCodeReaderViewDidUpdateRawInformation(_ sender: QRCodeReaderView) {
        updateQRBoundsLabels(features: sender.features)
    }

}

extension UIColor {
    fileprivate static var random: UIColor {
        let hue: CGFloat = CGFloat(arc4random() % 256) / 256
        let saturation: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 0.5)
    }
    fileprivate static var grayTransparent: UIColor {
        return UIColor(white: 0.2, alpha: 0.5)
    }
}
