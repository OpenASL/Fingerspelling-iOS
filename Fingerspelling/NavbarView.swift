import SwiftUI

struct NavbarView<Content: View>: View {
  var fontSize: CGFloat = 14
  var content: () -> Content

  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var settings: UserSettings

  var body: some View {
    VStack {
      ZStack {
        HStack {
          Button(action: self.handleOpenMenu) {
            Image(systemName: "line.horizontal.3").padding(.trailing, 5)
            GameModeIconView(mode: self.game.mode).padding(.trailing)
          }
          Spacer()
          Button(action: self.handleToggleSettings) {
            Image(systemName: "gear").font(Font.body.weight(.bold)).padding(.leading, 5)
          }
        }
        self.content()
      }
      Divider().padding(.bottom, 10)
    }
    .foregroundColor(.primary)
  }

  func handleToggleSettings() {
    self.game.toggleSheet(.settings)
    self.playback.stop()
  }

  func handleOpenMenu() {
    self.game.isMenuOpen.toggle()
    self.playback.stop()
  }
}

struct NavbarView_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      NavbarView {
        ScoreIndicatorView(
          textContent: "42",
          isHighlighted: false
        )
      }
      Spacer()
    }
    .modifier(RootStyle())
    .modifier(SystemServices())
  }
}
