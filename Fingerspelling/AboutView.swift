
import SwiftUI

struct AboutView: View {

  var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
  }
  var bundleVersion: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
  }
  
    var body: some View {
      Group {
        VStack {
          Text("App version: \(self.appVersion)")
          Text("Bundle version: \(self.bundleVersion)")
        }
        VStack(alignment: .leading) {
                  Text("Fingerspelling is run by volunteers.")
        }

        Spacer()
      }
      .padding()
      .navigationBarTitle("About")
  }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
      AboutView().modifier(RootStyle())
    }
}
