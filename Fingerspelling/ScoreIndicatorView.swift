
import SwiftUI

struct ScoreIndicatorView: View {
  var textContent: String
  var isHighlighted: Bool = false

  var body: some View {
    HStack {
      Image(systemName: "checkmark")
        .foregroundColor(self.isHighlighted ? Color.green : .secondary)
      Text(self.textContent)
        .fontWeight(self.isHighlighted ? .bold : .regular)
        .modifier(IndicatorStyle())
    }
  }
}

struct ScoreIndicatorView_Previews: PreviewProvider {
  static var previews: some View {
    HStack(spacing: 20) {
      ScoreIndicatorView(textContent: "42", isHighlighted: true)
      ScoreIndicatorView(textContent: "24", isHighlighted: false)
    }
  }
}
