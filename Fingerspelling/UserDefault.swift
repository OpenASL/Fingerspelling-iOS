import Combine
import Foundation
import SwiftUI

// https://stackoverflow.com/a/57029469/1157536
@propertyWrapper
struct UserDefault<T> {
  let key: String
  let defaultValue: T

  init(_ key: String, defaultValue: T) {
    self.key = key
    self.defaultValue = defaultValue
  }

  var wrappedValue: T {
    get {
      UserDefaults.standard.object(forKey: self.key) as? T ?? self.defaultValue
    }
    set {
      UserDefaults.standard.set(newValue, forKey: self.key)
    }
  }
}
