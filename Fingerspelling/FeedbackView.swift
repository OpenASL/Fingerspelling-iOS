
import SwiftUI

struct FeedbackView: View {
  @Environment(\.colorScheme) var colorScheme

  static let feedbackEmail = "sloria1+fingerspelling@gmail.com"

  var content: NSAttributedString {
    let attributedString = makeContentString(
      "Please send all feedback, questions, and ideas to:\n\n\(Self.feedbackEmail)\n\nAll feedback is welcome.",
      colorScheme: self.colorScheme
    )
    let feedbackUrl = "mailto:\(Self.feedbackEmail)"
    attributedString.addAttribute(
      .link,
      value: feedbackUrl,
      range: NSRange(location: 52, length: Self.feedbackEmail.count)
    )
    return attributedString
  }

  var body: some View {
    VStack {
      AttributedText(self.content)
      Spacer()
    }
    .padding()
    .navigationBarTitle("Send Feedback")
  }
}

struct FeedbackView_Previews: PreviewProvider {
  static var previews: some View {
    FeedbackView().modifier(RootStyle())
  }
}
