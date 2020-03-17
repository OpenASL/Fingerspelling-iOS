import SwiftUI

struct GameModeIconView: View {
  var mode: GameMode

  private let gameModeIcons = [
    GameMode.receptive: "eyeglasses",
    GameMode.expressive: "hand.raised",
  ]

  var body: some View {
    Image(systemName: self.gameModeIcons[self.mode]!)
  }
}

struct GameModeIconView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(alignment: .leading) {
      HStack {
        GameModeIconView(mode: .receptive).frame(minWidth: 35)
        Text(GameMode.receptive.rawValue)
      }
      HStack {
        GameModeIconView(mode: .expressive).frame(minWidth: 35)
        Text(GameMode.expressive.rawValue)
      }
    }
  }
}
