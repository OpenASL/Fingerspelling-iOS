import SwiftUI

struct StatItemView<Content: View>: View {
  var label: String
  var content: () -> Content

  var body: some View {
    HStack {
      Text(self.label).padding(.leading, 30)
      Spacer()
      self.content()
    }
  }
}

struct StatItemWithIconView<Content: View>: View {
  var iconName: String
  var label: String
  var content: () -> Content

  var body: some View {
    HStack {
      Image(systemName: self.iconName).frame(width: 20)
      Text(self.label)
      Spacer()
      self.content()
    }
  }
}

struct StatItemView_Previews: PreviewProvider {
  static var previews: some View {
    List {
      StatItemWithIconView(iconName: "checkmark", label: "Words completed") {
        Text("42")
      }
      StatItemView(label: "Average speed") {
        Text("4.2")
      }
      StatItemView(label: "Longest word") {
        Text("FINGERSPELLING").font(.system(size: 18, design: .monospaced))
      }
    }.padding()
  }
}
