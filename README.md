QRCodeReader
===

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-4BC51D.svg?style=flat-square)](https://github.com/apple/swift-package-manager)


## Demo

<img src="/screenshot/minimum.gif" alt="minimum" width="200"> <img src="/screenshot/noise.gif" alt="noise" width="200">

You can see flicker reduction on the `Detail` screenshot.

- `Message`: stable
- `Raw Message`: flickered

Flicker reduction is implemented by a simple majority vote algorithm. see [Vote.swift](/Sources/Internal/Vote.swift)


## Technical Detail

Please see my [blog post](https://blog.dnpp.org/ios_qrcode_reader) (written in Japanese).


## How to use

see [`ExampleApp/MinimumSampleViewController.swift`](/ExampleApp/MinimumSampleViewController.swift) and [`ExampleApp/DetailSampleViewController.swift`](/ExampleApp/DetailSampleViewController.swift)

(I'm sorry for the comments in the source code in Japanese.)


## Build Example App

Please use Carthage. I feel SPM so buggy...

 maybe [`./bin/carthage.sh`](/bin/carthage.sh) will helps you that includes Xcode 12 workaround code.


## Carthage

write your `Cartfile` and run `carthage update --platform iOS --cache-builds --no-use-binaries`

```
github "dnpp73/QRCodeReader"
```


## License

[MIT](/LICENSE)
