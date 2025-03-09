import Foundation

class Player: NSObject, ObservableObject {
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "foo" {
            return
        }
    }
}
