import UIKit
import SimpleCamera
import AVFoundation
import GPUCIImageView
import CoreImage
import LocusView

final class ViewController: UIViewController {

    @IBOutlet fileprivate var imageView: GLCIImageView!
    @IBOutlet fileprivate var locusView: LocusView!

    fileprivate var detector: CIDetector?

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
        SimpleCamera.shared.add(videoOutputObserver: self)

        let options: [String: Any] = [
//            CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorAccuracy: CIDetectorAccuracyLow,
            CIDetectorMaxFeatureCount: 1,
            CIDetectorTracking: true
        ]
        detector = CIDetector(ofType: CIDetectorTypeQRCode, context: imageView.ciContext, options: options)

        updateQRBoundsLabels()
        resetLocusView()
    }

    @IBAction private func touchUpInsideStartButton(_ sender: UIButton) {
        if SimpleCamera.shared.mode != .movie {
            SimpleCamera.shared.setMovieMode()
        }
        SimpleCamera.shared.startRunning()
    }

    @IBAction private func touchUpInsideStopButton(_ sender: UIButton) {
        SimpleCamera.shared.stopRunning()
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

    fileprivate func updateQRBoundsLabels(bounds: CGRect = .zero, bottomLeft: CGPoint = .zero, bottomRight: CGPoint = .zero, topLeft: CGPoint = .zero, topRight: CGPoint = .zero) {
        qrBoundsLabel.text = String(format: "x: %06.2f, y: %06.2f, w: %06.2f, h: %06.2f", bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height)
        qrBottomLeftLabel.text = String(format: "x: %06.2f, y: %06.2f", bottomLeft.x, bottomLeft.y)
        qrBottomRightLabel.text = String(format: "x: %06.2f, y: %06.2f", bottomRight.x, bottomRight.y)
        qrTopLeftLabel.text = String(format: "x: %06.2f, y: %06.2f", topLeft.x, topLeft.y)
        qrTopRightLabel.text = String(format: "x: %06.2f, y: %06.2f", topRight.x, topRight.y)
    }

    @IBAction private func valueChangedDetectionAreaSlider(_ sender: UISlider) {
        detectionAreaLabel.text = String(format: "%.2f", sender.value)
    }

    @IBAction private func valueChangedDetectionScaleSlider(_ sender: UISlider) {
        detectionScaleLabel.text = String(format: "%.2f", sender.value)
    }

    fileprivate var dropCount: UInt64 = 0

}

extension ViewController: SimpleCameraVideoOutputObservable {

    func simpleCameraVideoOutputObserve(captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard CMSampleBufferIsValid(sampleBuffer) else {
            return
        }
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        DispatchQueue.main.async {
            // let image = CIImage(cvImageBuffer: imageBuffer, options: nil)
            let rawImage = CIImage(cvPixelBuffer: imageBuffer)

            let screenScale: CGFloat = self.imageView.window?.screen.scale ?? 1.0
            let limitSize = self.imageView.bounds.size.applying(CGAffineTransform(scaleX: screenScale, y: screenScale))
            let limitWidth = limitSize.width
            let limitHeight = limitSize.height
            let rawImageWidth = rawImage.extent.width
            let rawImageHeight = rawImage.extent.height
            let scaleWidth = limitWidth / rawImageWidth
            let scaleHeight = limitHeight / rawImageHeight
            let image: CIImage
            if true {
                let scale = max(scaleWidth, scaleHeight)
                let imageScale = min(1.0, scale)
                let scaledImage = rawImage.transformed(by: CGAffineTransform(scaleX: imageScale, y: imageScale))
                #warning("センタリングする")
                image = scaledImage.cropped(to: CGRect(origin: .zero, size: limitSize))
            } else {
                let scale = min(scaleWidth, scaleHeight)
                let imageScale = min(1.0, scale)
                image = rawImage.transformed(by: CGAffineTransform(scaleX: imageScale, y: imageScale))
            }
//            self.imageView.image = image
            let maskColor = CIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8)
            guard let maskImage = CIFilter(name: "CIConstantColorGenerator", parameters: ["inputColor": maskColor])?.outputImage?.cropped(to: image.extent) else {
                return
            }

            let insetFactor = max(0.0, min(1.0, 1.0 - CGFloat(self.detectionAreaSlider.value)))
            let insetX = image.extent.width * 0.5 * insetFactor
            let insetY = image.extent.height * 0.5 * insetFactor
            let rect = image.extent.insetBy(dx: insetX, dy: insetY)
            let sourceOutMaskColor = CIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
            guard let sourceOutMaskImage = CIFilter(name: "CIConstantColorGenerator", parameters: ["inputColor": sourceOutMaskColor])?.outputImage?.cropped(to: rect) else {
                return
            }
            guard let sourceOutedImage = CIFilter(name: "CISourceOutCompositing", parameters: [
                kCIInputImageKey: maskImage,
                "inputBackgroundImage": sourceOutMaskImage
            ])?.outputImage else {
                return
            }

            guard let sourceOveredImage = CIFilter(name: "CISourceOverCompositing", parameters: [
                kCIInputImageKey: sourceOutedImage,
                "inputBackgroundImage": image
            ])?.outputImage else {
                return
            }

            self.imageView.image = sourceOveredImage
            /*
             if let mask = ConstantColorGenerator.image(inputColor: CIColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 0.5)) {
             if let m = SourceOverCompositing.filter(inputBackgroundImage: maskedImage)(mask.cropped(to: feature.bounds)) {
             maskedImage = m.cropped(to: scaledCIImage.extent)
             }
             }
             */

            let detectorScale = CGFloat(self.detectionScaleSlider.value)
            let detectorImage = image.cropped(to: rect).transformed(by: CGAffineTransform(scaleX: detectorScale, y: detectorScale))
            let features = self.detector?.features(in: detectorImage) ?? []
            self.featuresCountLabel.text = "\(features.count)"

            if features.count != 1 {
                self.qrMessageLabel.text = "-"
                self.updateQRBoundsLabels()
                return
            }
            guard let feature = features.last as? CIQRCodeFeature else {
                self.qrMessageLabel.text = "-"
                self.updateQRBoundsLabels()
                return
            }

            if let message = feature.messageString {
                self.qrMessageLabel.text = message
            } else {
                self.qrMessageLabel.text = "-"
            }
            self.updateQRBoundsLabels(bounds: feature.bounds, bottomLeft: feature.bottomLeft, bottomRight: feature.bottomRight, topLeft: feature.topLeft, topRight: feature.topRight)

            let p = CGPoint(x: feature.bounds.midX / detectorImage.extent.width, y: 1.0 - feature.bounds.midY / detectorImage.extent.height)
            // print(p)
            self.locusView.move(to: p)
        }
    }

    func simpleCameraVideoOutputObserve(captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        dropCount += 1
        print(dropCount)
    }

}
