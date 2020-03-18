import SwiftUI

struct SettingsView: View {
  var onClose: () -> Void

  @EnvironmentObject private var settings: UserSettings

  static let wordLengths = Array(3 ... 6) + [Int.max]

  struct LabeledPicker<SelectionValue: Hashable, Content: View>: View {
    var selection: Binding<SelectionValue>
    var label: String
    var content: () -> Content

    var body: some View {
      Section(header: Text(self.label.uppercased())) {
        Picker(selection: self.selection, label: Text(self.label)) {
          self.content()
        }.pickerStyle(SegmentedPickerStyle())
      }
    }
  }

  var body: some View {
    NavigationView {
      Form {
        LabeledPicker(selection: self.$settings.maxWordLength, label: "Max word length") {
          ForEach(Self.wordLengths, id: \.self) {
            Text($0 == Int.max ? "Any" : "\($0) letters").tag($0)
          }
        }
        
        Section {
          NavigationLink(destination: PrivacyPolicyView()) {
            Text("Privacy Policy")
          }
          NavigationLink(destination: AboutView()) { Text("About") }
        }
      }
      .navigationBarTitle("Settings")
      .navigationBarItems(trailing: Button(action: self.onClose) { Text("Done") })
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView(onClose: {}).modifier(SystemServices())
  }
}
