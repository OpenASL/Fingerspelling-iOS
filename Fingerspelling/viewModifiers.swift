import SwiftUI

struct RootStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(.top, 10)
      .padding(.horizontal, 20)
  }
}

struct IndicatorStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      .font(.system(.callout, design: .monospaced))
  }
}

struct FullWidthButtonContent: ViewModifier {
  var background: Color = Color.accentColor
  var foregroundColor: Color = Color.white
  var disabled: Bool = false

  func body(content: Content) -> some View {
    content
      .frame(minWidth: 0, maxWidth: .infinity)
      .padding()
      .background(self.background)
      .foregroundColor(self.foregroundColor)
      .cornerRadius(40)
      .opacity(self.disabled ? 0.5 : 1)
  }
}

struct FullWidthGhostButtonContent: ViewModifier {
  var color: Color = Color.accentColor

  func body(content: Content) -> some View {
    content
      .frame(minWidth: 0, maxWidth: .infinity)
      .padding()
      .overlay(
        RoundedRectangle(cornerRadius: 40)
          .stroke(self.color, lineWidth: 1)
      )
      .foregroundColor(self.color)
  }
}
