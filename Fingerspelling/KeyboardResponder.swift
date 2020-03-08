//
//  KeyboardResponder.swift
//  Fingerspelling
//
//  Created by Lauren Barker on 3/7/20.
//

import SwiftUI

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
