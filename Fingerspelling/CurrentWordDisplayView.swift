import SwiftUI

struct CurrentWordDisplayView: View {
  @EnvironmentObject var playback: PlaybackService

  var body: some View {
    Text(self.playback.currentWord.uppercased())
      .font(.system(.title, design: .monospaced))
      .minimumScaleFactor(0.8)
      .scaledToFill()
  }
}

struct CurrentWordDisplayView_Previews: PreviewProvider {
  static var previews: some View {
    let playback = SystemServices.playback

    playback.currentWord = "fingerspelling"

    return CurrentWordDisplayView().modifier(RootStyle()).modifier(SystemServices())
  }
}
