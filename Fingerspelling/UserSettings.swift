import Combine
import Foundation

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

final class UserSettings: ObservableObject {
  let objectWillChange = PassthroughSubject<Void, Never>()

  // Settings go here

  @UserDefault("speed", defaultValue: 3.0)
  var speed: Double {
    willSet {
      self.objectWillChange.send()
    }
  }
}
