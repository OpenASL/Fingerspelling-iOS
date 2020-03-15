import SwiftUI

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
    uiView.text = self.text.uppercased() // autocapitalize input
    if self.isFirstResponder, !context.coordinator.didBecomeFirstResponder {
      uiView.becomeFirstResponder()
      context.coordinator.didBecomeFirstResponder = true
    }
  }
}
