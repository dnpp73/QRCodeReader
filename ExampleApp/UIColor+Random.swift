import UIKit

extension UIColor {
    static var random: UIColor {
        let hue: CGFloat = CGFloat(arc4random() % 256) / 256
        let saturation: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness: CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 0.5)
    }
    static var grayTransparent: UIColor {
        return UIColor(white: 0.2, alpha: 0.5)
    }
}
