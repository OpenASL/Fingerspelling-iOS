import SwiftUI

struct SideMenuView: View {
  let width: CGFloat
  let isOpen: Bool
  let onClose: () -> Void

  @Environment(\.colorScheme) var colorScheme

  struct MenuContentView: View {
    @EnvironmentObject var game: GameState
    @EnvironmentObject var feedback: FeedbackService
    @EnvironmentObject var playback: PlaybackService

    struct ItemButtonView<Content: View>: View {
      var action: () -> Void
      var content: () -> Content

      var body: some View {
        Button(action: self.action) {
          HStack {
            self.content()
            Spacer()
          }.frame(minWidth: 0, maxWidth: .infinity)
        }
        .padding(.vertical, 20)
      }
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        Text("Mode")
          .font(.title)
          .fontWeight(.bold)
          .padding(.bottom, 15)

        ForEach(GameMode.allCases, id: \.self) { mode in
          ItemButtonView(action: {
            self.changeGameMode(mode)
          }) {
            Group {
              GameModeIconView(mode: mode)
                .imageScale(.large).frame(minWidth: 35)
              Text(mode.rawValue)
                .fontWeight(self.game.mode == mode ? .bold : .regular)
            }
          }
        }
        Spacer()
      }
      .font(.system(size: 18))
      .foregroundColor(.primary)
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .edgesIgnoringSafeArea(.all)
    }

    func changeGameMode(_ gameMode: GameMode) {
      self.game.mode = gameMode
      self.game.isMenuOpen.toggle()
      self.playback.reset()
      self.feedback.reset()
      self.feedback.hasSubmitted = false
    }
  }

  var body: some View {
    ZStack {
      GeometryReader { _ in
        EmptyView()
      }
      .background(self.colorScheme == .dark ? Color.black.opacity(0.5) : Color.gray.opacity(0.3))
      .opacity(self.isOpen ? 1.0 : 0.0)
      .animation(.easeIn(duration: 0.2))
      .onTapGesture {
        self.onClose()
      }

      HStack {
        MenuContentView()
          .frame(width: self.width)
          .padding(.top, 50)
          .background(self.colorScheme == .dark ? Color.darkGrey : Color.white)
          .offset(x: self.isOpen ? 0 : -self.width)
          .animation(.easeOut(duration: 0.2))
        Spacer()
      }
    }
  }
}

struct SideMenuView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      SideMenuView(width: 280, isOpen: true, onClose: {})
        .modifier(SystemServices())
      SideMenuView(width: 280, isOpen: true, onClose: {})
        .background(Color.black)
        .environment(\.colorScheme, .dark)
        .modifier(SystemServices())
    }
    .edgesIgnoringSafeArea(.all)
    .statusBar(hidden: true)
  }
}
