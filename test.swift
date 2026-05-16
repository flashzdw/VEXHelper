import UIKit
func test(scene: UIWindowScene) {
    if #available(iOS 16.0, *) {
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
    }
}
