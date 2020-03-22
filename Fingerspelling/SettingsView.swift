import SwiftUI

struct SettingsView: View {
  @State var isShowingFeedbackAlert = false
  @EnvironmentObject private var settings: UserSettings
  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService

  static let wordLengths = Array(3 ... 6) + [Int.max]
  static let feedbackEmail = "sloria1+Fingerspelling@gmail.com"
  static let appId = "id1503242863"

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
          Button(action: { self.isShowingFeedbackAlert.toggle() }) {
            Text("Send Feedback").foregroundColor(.primary).fontWeight(.semibold)
          }
          Button(action: self.handleRate) {
            Text("Rate Fingerspelling").foregroundColor(.primary)
          }
          NavigationLink(destination: AboutView()) { Text("About") }
        }
      }
      .navigationBarTitle("Settings")
      .navigationBarItems(trailing: Button(action: self.handleToggleSettings) { Text("Done") })
    }
    .alert(isPresented: self.$isShowingFeedbackAlert) {
      Alert(
        title: Text("Send Feedback"),
        message: Text("Send your feedback, questions, and ideas to \(Self.feedbackEmail)"),
        primaryButton: .default(Text("Open Mail").fontWeight(.bold), action: self.handleSendFeedback),
        secondaryButton: .default(Text("Not Now"))
      )
    }
  }

  private func handleSendFeedback() {
    if let url = URL(string: "mailto:\(Self.feedbackEmail)") {
      UIApplication.shared.open(url)
    }
  }

  private func handleRate() {
    if let url = URL(string: "https://itunes.apple.com/us/app/appName/\(Self.appId)?mt=8&action=write-review"),
      UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  private func handleToggleSettings() {
    self.game.toggleSheet(.settings)
    self.playback.stop()
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView().modifier(SystemServices())
  }
}
