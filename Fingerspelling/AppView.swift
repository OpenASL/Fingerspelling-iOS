import Combine
import SwiftUI

struct AppView: View {
  @ObservedObject private var keyboard = KeyboardResponder()

  @EnvironmentObject private var settings: UserSettings
  @EnvironmentObject private var game: GameState

  private var currentView: AnyView {
    switch self.game.mode {
    case .receptive: return AnyView(ReceptiveGameView())
    case .expressive: return AnyView(ExpressiveGameView())
    }
  }

  private var currentSheet: AnyView {
    switch self.game.currentSheet {
    case .settings: return AnyView(SettingsView())
    case .receptiveStats: return AnyView(ReceptiveStatsView())
    case .expressiveStats: return AnyView(ExpressiveStatsView())
    }
  }

  var body: some View {
    ZStack {
      self.currentView
        .modifier(RootStyle())
        // Move the current UI up when the keyboard is active
        .padding(.bottom, self.keyboard.currentHeight)
        .sheet(isPresented: self.$game.isShowingSheet) {
          self.currentSheet.modifier(SystemServices())
        }
      SideMenuView(
        width: 280,
        isOpen: self.game.isMenuOpen,
        onClose: { self.game.isMenuOpen.toggle() }
      )
      .edgesIgnoringSafeArea(.all)
    }
    .statusBar(hidden: self.game.isMenuOpen)
  }
}

struct AppView_Previews: PreviewProvider {
  static var previews: some View {
    let playback = SystemServices.playback
    let feedback = SystemServices.feedback

    // Modify these during development to update the preview
    playback.isPlaying = false
    playback.currentWord = "foo"
    feedback.isShown = false

    return AppView().modifier(SystemServices())
  }
}
