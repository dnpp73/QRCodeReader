import UIKit
import QRCodeReader

final class SampleViewController: UIViewController {

    @IBOutlet fileprivate var readerView: QRCodeReaderView!
    @IBOutlet fileprivate var qrMessageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        readerView?.delegate = self

        // 最近の iPhone のカメラから取れる画像のサイズは無駄にデカいため 0.8 くらいに縮小すると処理が軽くなります。
        // 全画面というかカメラのアス比のままで使うならともかく、横長にトリミングして使うこの様なレイアウトの場合は正直 1.0 でも全く問題はないです。
        // 当然小さい値にすればするほど検出し辛くなります。
        readerView?.detectionScale = 0.8

        // readerView のアス比によります。
        // このサンプル画面では横が 2 で縦が 1 なので、 x が 0.25 残るように 0.75 の指定、
        // y が 0.25 * 2 の 0.5 残るように 0.5 の指定をすると、検出エリアの見た目が正方形になります。
        readerView?.detectionInsetX = 0.75
        readerView?.detectionInsetY = 0.5

        // デバッグというか分かりやすさのために色を付けてるだけですが、本番では何もしなくてもいいと思います。
        // デフォルトでは .clear です。
        readerView?.detectionAreaMaskColor = .grayTransparent
    }

    @IBAction private func touchUpInsideStartButton(_ sender: UIButton) {
        readerView?.startReading()
    }

    @IBAction private func touchUpInsideStopButton(_ sender: UIButton) {
        readerView?.stopReading()
    }

}

extension SampleViewController: QRCodeReaderViewDelegate {
    func qrCodeReaderViewDidUpdateMessageString(_ sender: QRCodeReaderView) {
        qrMessageLabel.text = sender.messageString
        if let messageString = sender.messageString {
            sender.detectionAreaMaskColor = .random
            UIPasteboard.general.setValue(messageString, forPasteboardType: "public.text")
        } else {
            sender.detectionAreaMaskColor = .grayTransparent
        }
    }
}
