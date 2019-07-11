import UIKit
import QRCodeReader
import CoreImage
import LocusView

final class ViewController: UIViewController {

    @IBOutlet fileprivate var readerView: QRCodeReaderView!

    @IBOutlet fileprivate var locusView: LocusView!

    @IBOutlet fileprivate var featuresCountLabel: UILabel!
    @IBOutlet fileprivate var qrMessageLabel: UILabel!
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
        updateQRBoundsLabels()
        resetLocusView()
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

    fileprivate func resetLocusView() {
        let diameter = LocusView.defaultCircleDiameter
        // diameterSlider.value     = Float(diameter)
        // diameterLabel.text       = String(format: "%.2f", arguments: [diameter])
        locusView.circleDiameter = CGFloat(diameter)

        // let animationDuration = LocusView.defaultAnimationDuration
        let animationDuration = 0.2
        // animationDurationSlider.value = Float(animationDuration)
        // animationDurationLabel.text   = String(format: "%.2f", arguments: [animationDuration])
        locusView.animationDuration = TimeInterval(animationDuration)

        // let tailHistorySeconds = LocusView.defaultTailHistorySeconds
        let tailHistorySeconds = 0.0
        // tailHistorySecondsSlider.value = Float(tailHistorySeconds)
        // tailHistorySecondsLabel.text   = String(format: "%.2f", arguments: [tailHistorySeconds])
        locusView.tailHistorySeconds = TimeInterval(tailHistorySeconds)

        // locusView.circleColor = LocusView.defaultCircleColor
        locusView.circleColor = UIColor(white: 1.0, alpha: 0.4)
        // locusView.tailColor = LocusView.defaultTailColor
        locusView.tailColor = UIColor(white: 1.0, alpha: 0.2)

    }

    fileprivate func updateQRBoundsLabels(features: [CIFeature] = []) {
        featuresCountLabel.text = "\(features.count)"

        let feature: CIQRCodeFeature?
        if features.count != 1 {
            qrMessageLabel.text = "-"
            feature = nil
        } else {
            if let f = features.last as? CIQRCodeFeature {
                if let message = f.messageString {
                    self.qrMessageLabel.text = message
                } else {
                    self.qrMessageLabel.text = "-"
                }
                feature = f
            } else {
                qrMessageLabel.text = "-"
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
            qrMessageLabel.text = "-"
        }

        qrBoundsLabel.text = String(format: "x: %06.2f, y: %06.2f, w: %06.2f, h: %06.2f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height)
        qrBottomLeftLabel.text = String(format: "x: %06.2f, y: %06.2f", bottomLeft.x, bottomLeft.y)
        qrBottomRightLabel.text = String(format: "x: %06.2f, y: %06.2f", bottomRight.x, bottomRight.y)
        qrTopLeftLabel.text = String(format: "x: %06.2f, y: %06.2f", topLeft.x, topLeft.y)
        qrTopRightLabel.text = String(format: "x: %06.2f, y: %06.2f", topRight.x, topRight.y)
    }

}

extension ViewController: QRCodeReaderViewDelegate {
    func qrCodeReaderViewDidUpdateRawInformation(_ sender: QRCodeReaderView) {
        updateQRBoundsLabels(features: sender.features)
    }
}
