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
    var maxLength: Int
    var _textFieldShouldReturn: (_ textField: UITextField) -> Bool

    init(text: Binding<String>, maxLength: Int, textFieldShouldReturn: @escaping (_ textField: UITextField) -> Bool) {
      self._text = text
      self.maxLength = maxLength
      self._textFieldShouldReturn = textFieldShouldReturn
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
      guard let text = textField.text else { return true }
      let newLength = text.count + string.count - range.length
      return newLength <= self.maxLength
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
  var maxLength = 14

  func makeUIView(context: UIViewRepresentableContext<FocusableTextField>) -> UITextField {
    let textField = UITextField(frame: .zero)
    textField.delegate = context.coordinator
    textField.placeholder = self.placeholder
    return self.modifyTextField(textField)
  }

  func makeCoordinator() -> FocusableTextField.Coordinator {
    Coordinator(
      text: self.$text,
      maxLength: self.maxLength,
      textFieldShouldReturn: self.textFieldShouldReturn
    )
  }

  func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<FocusableTextField>) {
    if self.isFirstResponder, !context.coordinator.didBecomeFirstResponder {
      uiView.becomeFirstResponder()
      context.coordinator.didBecomeFirstResponder = true
    }
    self.onUpdate(uiView)
  }
}

struct AttributedText: UIViewRepresentable {
  var attributedText: NSAttributedString

  init(_ attributedText: NSAttributedString) {
    self.attributedText = attributedText
  }

  func makeUIView(context _: UIViewRepresentableContext<AttributedText>) -> UITextView {
    let textView = UITextView()
    textView.isEditable = false
    return textView
  }

  func updateUIView(_ label: UITextView, context _: Context) {
    label.attributedText = self.attributedText
  }
}

func makeContentString(_ text: String, colorScheme: ColorScheme) -> NSMutableAttributedString {
  let attributedString = NSMutableAttributedString(
    string: text,
    attributes: [
      NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
      NSAttributedString.Key.foregroundColor: colorScheme == .dark ? UIColor.white : UIColor.black,
    ]
  )
  let parStyle = NSMutableParagraphStyle()
  parStyle.lineSpacing = 2.0
  parStyle.lineBreakMode = .byWordWrapping
  attributedString.addAttribute(
    .paragraphStyle,
    value: parStyle,
    range: NSRange(location: 0, length: attributedString.length)
  )
  return attributedString
}

func rounded(_ number: Double, places: Int) -> Double {
  let factor = pow(10.0, Double(places))
  return Double(round(factor * number) / factor)
}

/// Return number as a formatted string suitable for display as a statistic.
func formatNumber(_ number: Double, places: Int = 1) -> String {
  let roundedNumber = rounded(number, places: places)
  return roundedNumber == number ? String(Int(number)) : String(roundedNumber)
}

// MARK: Extensions

extension String {
  // https://stackoverflow.com/a/44102415/1157536
  func levenshteinDistance(to: String) -> Int {
    let empty = [Int](repeating: 0, count: to.count)
    var last = [Int](0 ... to.count)

    for (i, char1) in self.enumerated() {
      var cur = [i + 1] + empty
      for (j, char2) in to.enumerated() {
        cur[j + 1] = char1 == char2 ? last[j] : Swift.min(last[j], last[j + 1], cur[j]) + 1
      }
      last = cur
    }
    return last.last!
  }
}

extension Color {
  static let darkGrey = Color(red: 40 / 255, green: 40 / 255, blue: 40 / 255)
}

extension Collection where Element: Numeric {
  /// Returns the total sum of all elements in the array
  var total: Element { reduce(0, +) }
}

extension Collection where Element: BinaryInteger {
  /// Returns the average of all elements in the array
  var average: Double { isEmpty ? 0 : Double(self.total) / Double(count) }
}

extension Collection where Element: BinaryFloatingPoint {
  /// Returns the average of all elements in the array
  var average: Element { isEmpty ? 0 : self.total / Element(count) }
}
