import Foundation
import UIKit
import AVFoundation
import CoreImage
import SimpleCamera
import GPUCIImageView

public protocol QRCodeReaderViewDelegate: class {
    func qrCodeReaderViewDidUpdateMessageString(_ sender: QRCodeReaderView)
    func qrCodeReaderViewDidUpdateRawInformation(_ sender: QRCodeReaderView)
}

public class QRCodeReaderView: UIView {

    public weak var delegate: QRCodeReaderViewDelegate?

    // 負荷の調整をするためのパラメタ群
    public var detectionScale: CGFloat = 0.5
    public var detectionInsetX: CGFloat = 0.5
    public var detectionInsetY: CGFloat = 0.5

    public var messageString: String? {
        didSet {
            if oldValue != messageString {
                delegate?.qrCodeReaderViewDidUpdateMessageString(self)
            }
        }
    }

    // 探索すべき画像はカメラから連続的に得られるので、多数決によって高周波成分を除去する。
    // アルゴリズム的な英単語の語彙がないので不安だけど、とりあえず投票箱という名前にした。
    private var ballotBox = BallotBox<String>()

    // 単純に CIDetector が見付けた生の情報も取れるようにしておいた方が便利だと思われるのでリードオンリーで見られるようにしてあるだけ。
    public fileprivate(set) var features: [CIFeature] = [] {
        didSet {
            delegate?.qrCodeReaderViewDidUpdateRawInformation(self)
        }
    }

    fileprivate var imageView: GLCIImageView?
    fileprivate var detector: CIDetector?
    fileprivate var dropCount: UInt64 = 0

    // MARK: - Initializer

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    private func commonInit() {
        let imageView = GLCIImageView()

        // AutoLayout を弄るのは addSubview 以降
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        imageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        self.imageView = imageView

        let options: [String: Any] = [
            // CIDetectorAccuracy: CIDetectorAccuracyHigh,
            CIDetectorAccuracy: CIDetectorAccuracyLow,
            CIDetectorMaxFeatureCount: 1,
            CIDetectorTracking: true
        ]
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: imageView.ciContext, options: options)
        self.detector = detector
    }

    // MARK: - UIView

    override public func didMoveToWindow() {
        super.didMoveToWindow()
        if let _ = window {
            SimpleCamera.shared.add(videoOutputObserver: self)
        } else {
            stopReading()
            SimpleCamera.shared.remove(videoOutputObserver: self)
        }
    }

    // MARK: - Custom Methods

    public private(set) var isReading: Bool = false

    public func startReading() {
        isReading = true
        if SimpleCamera.shared.mode != .movie {
            SimpleCamera.shared.setMovieMode()
        }
        SimpleCamera.shared.startRunning()
    }

    public func stopReading() {
        SimpleCamera.shared.stopRunning()
        isReading = false
    }

}

fileprivate extension CIImage {

    func masked(color: CIColor, rect: CGRect) -> CIImage {
        guard let maskImage = CIFilter(name: "CIConstantColorGenerator", parameters: ["inputColor": color])?.outputImage?.cropped(to: extent) else {
            fatalError("Could not generate `maskImage`")
        }
        let sourceOutMaskColor = CIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        guard let sourceOutMaskImage = CIFilter(name: "CIConstantColorGenerator", parameters: ["inputColor": sourceOutMaskColor])?.outputImage?.cropped(to: rect) else {
            fatalError("Could not generate `sourceOutMaskImage`")
        }
        guard let sourceOutedImage = CIFilter(name: "CISourceOutCompositing", parameters: [
            kCIInputImageKey: maskImage,
            "inputBackgroundImage": sourceOutMaskImage
        ])?.outputImage else {
            fatalError("Could not generate `sourceOutedImage`")
        }
        guard let sourceOveredImage = CIFilter(name: "CISourceOverCompositing", parameters: [
            kCIInputImageKey: sourceOutedImage,
            "inputBackgroundImage": self
        ])?.outputImage else {
            fatalError("Could not generate `sourceOveredImage`")
        }
        return sourceOveredImage
    }

    func fit(to limitSize: CGSize) -> CIImage {
        let scaleWidth = limitSize.width / extent.width
        let scaleHeight = limitSize.height / extent.height
        let scale = min(scaleWidth, scaleHeight)
        let imageScale = min(1.0, scale)
        return transformed(by: CGAffineTransform(scaleX: imageScale, y: imageScale))
    }

    func fill(to limitSize: CGSize) -> CIImage {
        let scaleWidth = limitSize.width / extent.width
        let scaleHeight = limitSize.height / extent.height
        let scale = max(scaleWidth, scaleHeight)
        let imageScale = min(1.0, scale)
        let scaledImage = transformed(by: CGAffineTransform(scaleX: imageScale, y: imageScale))
        #warning("センタリングする")
        return scaledImage.cropped(to: CGRect(origin: .zero, size: limitSize))
    }
}

extension QRCodeReaderView: SimpleCameraVideoOutputObservable {

    private var screenScale: CGFloat {
        return imageView?.window?.screen.scale ?? 1.0
    }

    private var limitSize: CGSize {
        guard let imageView = imageView else {
            return .zero
        }
        let t = CGAffineTransform(scaleX: screenScale, y: screenScale)
        return imageView.bounds.size.applying(t)
    }

    public func simpleCameraVideoOutputObserve(captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        DispatchQueue.main.async {
            guard CMSampleBufferIsValid(sampleBuffer) else {
                self.vote(.blank)
                return
            }
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                self.vote(.blank)
                return
            }
            guard let imageView = self.imageView else {
                self.vote(.blank)
                return
            }
            let image = CIImage(cvImageBuffer: imageBuffer, options: nil).fill(to: self.limitSize)

            let realInsetX = image.extent.width * 0.5 * self.detectionInsetX
            let realInsetY = image.extent.height * 0.5 * self.detectionInsetY
            let rect = image.extent.insetBy(dx: realInsetX, dy: realInsetY)

            // 表示用のイメージはこれで良い
            imageView.image = image.masked(color: CIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8), rect: rect)

            // 全体の画像を渡すと重いので実際に QRCode があるか判定する画像はクロップ済のものにする。
            let detectionImage = image.cropped(to: rect).transformed(by: CGAffineTransform(scaleX: self.detectionScale, y: self.detectionScale))

            let features = self.detector?.features(in: detectionImage) ?? []
            self.features = features

            if features.count != 1 {
                self.vote(.blank)
                return
            }
            guard let feature = features.last as? CIQRCodeFeature else {
                self.vote(.blank)
                return
            }

            // 多数決のための投票をする。
            guard let messageString = feature.messageString else {
                self.vote(.blank)
                return
            }
            self.vote(.valid(messageString))
        }
    }

    public func simpleCameraVideoOutputObserve(captureOutput: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        dropCount += 1
        print(dropCount)
    }

    private func vote(_ vote: Vote<String>) {
        ballotBox.vote(vote)
        switch ballotBox.winner {
        case .blank:
            messageString = nil
        case .valid(let value):
            messageString = value
        }
    }

}
