
import SwiftUI

struct AboutView: View {
  var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
  }

  var bundleVersion: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
  }

  var text: NSAttributedString {
    let attributedString = NSMutableAttributedString(
      string: "This app was inspired by the website http://asl.ms/ created by Dr. Bill Vicars. If you find this app useful, check out ASLU and consider making a donation.",
      attributes: [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18),
      ]
    )
    let parStyle = NSMutableParagraphStyle()
    parStyle.lineSpacing = 1.5
    parStyle.lineBreakMode = .byWordWrapping
    attributedString.addAttribute(
      .paragraphStyle,
      value: parStyle,
      range: NSRange(location: 0, length: attributedString.length)
    )
    attributedString.addAttribute(
      .link,
      value: "http://asl.ms/",
      range: NSRange(location: 37, length: 14)
    )
    attributedString.addAttribute(
      .link,
      value: "https://www.lifeprint.com/",
      range: NSRange(location: 119, length: 4)
    )
    attributedString.endEditing()
    return attributedString
  }

  var body: some View {
    VStack {
      Text("ASL Fingerspelling Practice").font(.system(size: 18))
        .padding(.bottom, 5)
      Text("Version \(self.appVersion) (\(self.bundleVersion))")
        .font(.system(size: 12, design: .monospaced))
      AttributedText(self.text)
        .padding(.top, 5)
        .frame(maxWidth: .infinity, maxHeight: 130, alignment: .leading)
      Button(action: self.handleDonate) {
        Text("Donate to ASLU").modifier(FullWidthGhostButtonContent())
      }
      Spacer()
    }
    .padding()
    .navigationBarTitle("About")
  }

  func handleDonate() {
    if let url = URL(string: "https://www.lifeprint.com/donate.htm") {
      UIApplication.shared.open(url)
    }
  }
}

struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    AboutView().modifier(RootStyle())
  }
}
