import SwiftUI

struct ExpressiveGameView: View {
  @State var isHighlightingScore = false

  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var feedback: FeedbackService

  private var controls: some View {
    VStack {
      if self.feedback.hasRevealed {
        Button(action: self.handleContinue) {
          Text("Next word").modifier(FullWidthButtonContent()).padding(.bottom)
        }
      }
      if self.feedback.isRevealed {
        Button(action: self.handleHideSpelling) {
          Text("Hide").modifier(FullWidthGhostButtonContent())
        }
      } else {
        Button(action: self.handleRevealSpelling) {
          Text("Reveal").modifier(FullWidthGhostButtonContent())
        }
      }
    }
  }

  var body: some View {
    VStack {
      NavbarView {
        Button(action: self.handleToggleStats) {
          ScoreIndicatorView(
            textContent: String(self.game.expressiveScore),
            isHighlighted: self.isHighlightingScore
          )
        }
      }.modifier(SystemServices())

      CurrentWordDisplayView()
      Spacer()
      if self.feedback.isRevealed {
        SpellingDisplayView()
      } else if !self.feedback.hasRevealed {
        Text("Fingerspell the word above.").font(.system(size: 24))
      }
      Spacer()
      self.controls.padding(.bottom)
    }
  }

  // MARK: Handlers

  private func handleRevealSpelling() {
    self.feedback.reveal()
  }

  private func handleHideSpelling() {
    self.feedback.hide()
  }

  private func handleContinue() {
    self.playback.setNextWord()
    self.feedback.reset()
    self.game.expressiveCompletedWords.append(self.playback.currentWord)
    self.isHighlightingScore = true
    delayFor(1.0) {
      self.isHighlightingScore = false
    }
  }

  private func handleToggleStats() {
    self.game.toggleSheet(.expressiveStats)
    self.playback.stop()
  }
}

private struct SpellingDisplayView: View {
  @EnvironmentObject var playback: PlaybackService

  static let scaledSize: CGFloat = 165
  static let width: CGFloat = 100

  var body: some View {
    ScrollView(.horizontal) {
      HStack(alignment: .top, spacing: 0) {
        ForEach(self.playback.imageNames, id: \.self) { (_ imageName) in
          Image(imageName)
            .resizable()
            .frame(width: Self.scaledSize, height: Self.scaledSize)
            // Crop horizontal space around images
            .clipped()
            .frame(width: Self.width)
        }
      }
    }
    .frame(height: 185)
  }
}

struct ExpressiveGameView_Previews: PreviewProvider {
  static var previews: some View {
    let playback = SystemServices.playback
    let feedback = SystemServices.feedback

    // Modify these during development to update the preview
    playback.currentWord = "foo"
    feedback.reveal()

    return ExpressiveGameView().modifier(RootStyle()).modifier(SystemServices())
  }
}
