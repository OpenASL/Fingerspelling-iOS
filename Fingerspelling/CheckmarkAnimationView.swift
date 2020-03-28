import SwiftUI

struct CheckmarkAnimationView: View {
  @State private var displayBorder = false
  @State private var displayCheckmark = false

  var size: CGFloat = 100

  var body: some View {
    Image(systemName: "checkmark.circle")
      .font(Font.system(size: self.size).weight(.light))
      .foregroundColor(.green)
      .scaleEffect(displayCheckmark ? 1.5 : 1)
      .animation(.spring())
      .onAppear {
        self.displayCheckmark.toggle()
      }
  }
}

struct CheckmarkAnimationView_Previews: PreviewProvider {
  static var previews: some View {
    CheckmarkAnimationView()
  }
}
