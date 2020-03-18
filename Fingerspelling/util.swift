import Combine
import Foundation
import SwiftUI

/// Get a random word from the Words list
func getRandomWord() -> String {
  #if DEBUG
    if isUITesting() {
      let word = __testWords[__wordIndexForTesting % __testWords.count]
      __wordIndexForTesting += 1
      return word
    }
  #endif
  let word = Words.randomElement()!
  print("current word: " + word)
  return word
}

#if DEBUG
  private var __wordIndexForTesting = 0
  private var __testWords = ["turkey", "fly", "heavy"]

  func isUITesting() -> Bool {
    ProcessInfo.processInfo.arguments.contains("testing")
  }
#endif

class LoadingTimer {
  var publisher: Timer.TimerPublisher
  private var timerCancellable: Cancellable?

  init(every: Double) {
    self.publisher = Timer.publish(every: every, on: .main, in: .default)
    self.timerCancellable = nil
  }

  func start() {
    self.timerCancellable = self.publisher.connect()
  }

  func cancel() {
    self.timerCancellable?.cancel()
  }
}

@discardableResult
func delayFor(_ seconds: Double, onComplete: @escaping () -> Void) -> Timer {
  Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
    onComplete()
  }
}

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

// https://stackoverflow.com/questions/56491881/move-textfield-up-when-thekeyboard-has-appeared-by-using-swiftui-ios
final class KeyboardResponder: ObservableObject {
  private var notificationCenter: NotificationCenter
  @Published private(set) var currentHeight: CGFloat = 0

  init(center: NotificationCenter = .default) {
    self.notificationCenter = center
    self.notificationCenter.addObserver(self, selector: #selector(self.keyBoardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    self.notificationCenter.addObserver(self, selector: #selector(self.keyBoardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
  }

  deinit {
    notificationCenter.removeObserver(self)
  }

  @objc func keyBoardWillShow(notification: Notification) {
    if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      self.currentHeight = keyboardSize.height
    }
  }

  @objc func keyBoardWillHide(notification _: Notification) {
    self.currentHeight = 0
  }
}

// adapted from https://stackoverflow.com/a/56508132/1157536
struct FocusableTextField: UIViewRepresentable {
  class Coordinator: NSObject, UITextFieldDelegate {
    @Binding var text: String
    var didBecomeFirstResponder = false
    var _textFieldShouldReturn: (_ textField: UITextField) -> Bool

    init(text: Binding<String>, textFieldShouldReturn: @escaping (_ textField: UITextField) -> Bool) {
      self._text = text
      self._textFieldShouldReturn = textFieldShouldReturn
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
      DispatchQueue.main.async {
        self.text = textField.text ?? ""
      }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      self._textFieldShouldReturn(textField)
    }
  }

  @Binding var text: String
  var isFirstResponder: Bool = false
  var placeholder: String = ""
  var textFieldShouldReturn: (_ textField: UITextField) -> Bool = { _ in true }
  var modifyTextField: (_ textField: UITextField) -> UITextField = { (_ textField) in textField }
  var onUpdate: (_ textField: UITextField) -> Void = { _ in }

  func makeUIView(context: UIViewRepresentableContext<FocusableTextField>) -> UITextField {
    let textField = UITextField(frame: .zero)
    textField.delegate = context.coordinator
    textField.placeholder = self.placeholder
    return self.modifyTextField(textField)
  }

  func makeCoordinator() -> FocusableTextField.Coordinator {
    Coordinator(text: $text, textFieldShouldReturn: self.textFieldShouldReturn)
  }

  func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<FocusableTextField>) {
    if self.isFirstResponder, !context.coordinator.didBecomeFirstResponder {
      uiView.becomeFirstResponder()
      context.coordinator.didBecomeFirstResponder = true
    }
    self.onUpdate(uiView)
  }
}
