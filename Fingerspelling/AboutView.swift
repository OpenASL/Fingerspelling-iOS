
import SwiftUI

struct AboutView: View {
  @Environment(\.colorScheme) var colorScheme

  var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
  }

  var bundleVersion: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
  }

  var about: NSAttributedString {
    let attributedString = makeContentString(
      "This app was inspired by the website http://asl.ms/ created by Dr. Bill Vicars. If you find this app useful, check out ASLU and consider making a donation.",
      colorScheme: self.colorScheme
    )
    let aslMsUrl = "http://asl.ms/"
    attributedString.addAttribute(
      .link,
      value: aslMsUrl,
      range: NSRange(location: 37, length: aslMsUrl.count)
    )
    attributedString.addAttribute(
      .link,
      value: "https://www.lifeprint.com/",
      range: NSRange(location: 119, length: 4)
    )
    return attributedString
  }

  var privacyPolicy: NSAttributedString {
    makeContentString(
      "No data or personal information is collected by this app.",
      colorScheme: self.colorScheme
    )
  }

  private struct Header: ViewModifier {
    let font = Font.system(size: 18).weight(.heavy)
    func body(content: Content) -> some View {
      content
        .font(self.font)
        .padding(.bottom, 5)
    }
  }

  var body: some View {
    VStack {
      Text("ASL Fingerspelling Practice").modifier(Header())
      Text("Version \(self.appVersion) (\(self.bundleVersion))")
        .font(.system(size: 12, design: .monospaced))
      AttributedText(self.about)
        .padding(.top, 5)
        .frame(maxWidth: .infinity, maxHeight: 130, alignment: .leading)
      Button(action: self.handleDonate) {
        Text("Donate to ASLU").modifier(FullWidthGhostButtonContent())
      }
      Divider().padding(.vertical)
      Text("Privacy Policy").modifier(Header())
      AttributedText(self.privacyPolicy)
      Spacer()
    }
    .padding()
    .navigationBarTitle("About", displayMode: .inline)
  }

  private func handleDonate() {
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
