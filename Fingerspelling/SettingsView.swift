import SwiftUI

struct SettingsView: View {
  @EnvironmentObject private var settings: UserSettings
  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService

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
          NavigationLink(destination: AboutView()) { Text("About") }
        }
      }
      .navigationBarTitle("Settings")
      .navigationBarItems(trailing: Button(action: self.handleToggleSettings) { Text("Done") })
    }
  }

  func handleToggleSettings() {
    self.game.toggleSheet(.settings)
    self.playback.stop()
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView().modifier(SystemServices())
  }
}
