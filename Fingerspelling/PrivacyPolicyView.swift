import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
      VStack {
        Text("No data or personal information is collected by this app.")
        Spacer()
      }
      .padding()
      .navigationBarTitle("Privacy Policy")
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
      PrivacyPolicyView().modifier(RootStyle())
    }
}
