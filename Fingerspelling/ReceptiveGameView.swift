import SwiftUI

struct ReceptiveGameView: View {
  /// Timer used to delay playing the next word
  @State private var delayTimer: Timer? = nil

  @EnvironmentObject private var game: GameState
  @EnvironmentObject private var playback: PlaybackService
  @EnvironmentObject private var feedback: FeedbackService
  @EnvironmentObject private var settings: UserSettings

  private static let postSubmitDelay = 2.0 // seconds
  private static let nextWordDelay = 1.0 // seconds
  private static let minSpeed = 1.0
  private static let maxSpeed = 11.0

  private var answerIsCorrect: Bool {
    self.answerClean == self.currentWordClean
  }

  private var answerIsAlmostCorrect: Bool {
    (
      !self.answerIsCorrect &&
        self.answerClean.levenshteinDistance(to: self.currentWordClean) < 3
    )
  }

  private var answerClean: String {
    self.feedback.answerTrimmed.lowercased()
  }

  private var currentWordClean: String {
    self.playback.currentWord.lowercased()
  }

  var body: some View {
    VStack {
      NavbarView {
        HStack {
          Button(action: self.handleToggleStats) {
            ScoreIndicatorView(
              textContent: String(self.game.receptiveScore),
              isHighlighted: self.feedback.hasCorrectAnswer
            )
            .padding(.horizontal, 5)
            HStack {
              Image(systemName: "metronome")
              Text(self.settings.speedDisplay)
                .modifier(IndicatorStyle())
            }
            .padding(.horizontal, 5)
          }
        }
      }.modifier(SystemServices())

      if self.feedback.hasCorrectAnswer || self.feedback.isRevealed {
        CurrentWordDisplayView()
      }

      HStack {
        if !self.game.isMenuOpen {
          AnswerInput(
            value: self.$feedback.answer,
            onSubmit: self.handleSubmit,
            isCorrect: self.answerIsCorrect,
            isAlmostCorrect: self.answerIsAlmostCorrect
          ).modifier(SystemServices())
        }
        if !self.feedback.shouldDisableControls {
          Spacer()
          Button(action: self.handleReveal) {
            Text("Reveal")
              .font(.system(size: 14))
              .foregroundColor(self.playback.isPlaying ? .gray : .primary)
              .frame(height: 30)
          }.disabled(self.playback.isPlaying)
        }
      }
      Spacer()

      MainDisplay(onPlay: self.handlePlay).frame(width: 100, height: 150)

      Spacer()
      SpeedControlView(
        value: self.$settings.speed,
        minSpeed: Self.minSpeed,
        maxSpeed: Self.maxSpeed,
        disabled: self.playback.isPlaying
      )
      .padding(.bottom, 10)
      PlaybackControlView(onPlay: self.handlePlay, onStop: self.handleStop).padding(.bottom, 10)
    }
  }

  private func playWord() {
    self.playback.play()
    self.feedback.hide()
  }

  // MARK: Handlers

  private func handlePlay() {
    self.playWord()
  }

  private func handleNextWord() {
    self.playback.setNextWordPending()
    self.feedback.reset()

    self.delayTimer = delayFor(Self.nextWordDelay) {
      self.playWord()
    }
  }

  private func handleStop() {
    self.delayTimer?.invalidate()
    self.playback.stop()
    self.feedback.hide()
  }

  private func handleReveal() {
    self.playback.stop()
    self.feedback.reveal()
    delayFor(Self.postSubmitDelay) {
      self.feedback.hide()
      self.handleNextWord()
    }
  }

  private func handleSubmit() {
    // Prevent multiple submissions when pressing "return" key
    if self.feedback.hasCorrectAnswer {
      return
    }
    self.feedback.show()
    if self.answerIsCorrect {
      self.handleStop()
      self.feedback.markCorrect()
      self.game.receptiveCompletedWords.append(
        CompletedWord(
          self.playback.currentWord,
          speed: self.settings.speed
        )
      )
      delayFor(Self.postSubmitDelay) {
        self.handleNextWord()
      }
    } else {
      self.feedback.markIncorrect()
      delayFor(0.5) {
        self.feedback.hide()
      }
    }
  }

  private func handleToggleStats() {
    self.game.toggleSheet(.receptiveStats)
    self.playback.stop()
  }
}

// MARK: Supporting views

private struct PlaybackControlView: View {
  var onPlay: () -> Void
  var onStop: () -> Void

  @EnvironmentObject var playback: PlaybackService
  @EnvironmentObject var feedback: FeedbackService

  var body: some View {
    Group {
      if !self.playback.isActive && !self.feedback.shouldDisableControls {
        Button(action: self.onPlay) {
          Image(systemName: "play.fill")
            .font(.system(size: 18))
            .modifier(FullWidthButtonContent())
        }
      } else {
        Button(action: self.onStop) {
          Image(systemName: "stop.fill")
            .font(.system(size: 18))
            .modifier(FullWidthGhostButtonContent())
        }.disabled(self.feedback.shouldDisableControls)
      }
    }
  }
}

private struct MainDisplay: View {
  var onPlay: () -> Void

  @EnvironmentObject var playback: PlaybackService
  @EnvironmentObject var feedback: FeedbackService

  var onboarding: some View {
    Group {
      if !self.playback.hasPlayed {
        Button(action: self.onPlay) {
          HStack {
            Text("Press ").foregroundColor(Color.primary)
            Image(systemName: "play").foregroundColor(Color.accentColor)
            Text(" to begin.").foregroundColor(Color.primary)
          }.frame(width: 200, height: 150)
        }
      } else {
        Text("Enter the word you saw.").frame(width: 200, height: 150)
      }
    }
  }

  var body: some View {
    VStack {
      if !self.playback.isPlaying {
        if !self.feedback.hasSubmitted {
          self.onboarding
        }
        if self.feedback.isShown || self.feedback.hasCorrectAnswer {
          FeedbackDisplayView(isCorrect: self.feedback.hasCorrectAnswer)
        }
      } else {
        // Need to pass SystemServices due to a bug in SwiftUI
        //   re: environment not getting passed to children
        WordPlayerView().modifier(SystemServices())
      }
    }
  }
}

private struct WordPlayerView: View {
  @EnvironmentObject var playback: PlaybackService
  @State private var letterOffset: CGFloat = 0

  static let repeatOffset: CGFloat = -20

  var body: some View {
    // XXX: Complicated implementation of an animated image
    //   since there doesn't seem to be a better way to do this in
    //   SwiftUI yet: https://stackoverflow.com/a/57749621/1157536
    Image(uiImage: self.playback.currentLetterImage)
      .resizable()
      .frame(width: 225, height: 225)
      .scaledToFit()
      .offset(CGSize(width: self.letterOffset, height: 0))
      .onReceive(
        self.playback.playTimer!.publisher,
        perform: { _ in
          self.playback.setNextLetter()
          if self.playback.currentLetterIsRepeat {
            self.letterOffset += Self.repeatOffset
          } else {
            self.letterOffset = 0
          }
        }
      )
      .onAppear {
        self.playback.resetTimer()
        self.playback.startTimer()
      }
      .onDisappear {
        self.playback.resetTimer()
      }
  }
}

private struct FeedbackDisplayView: View {
  var isCorrect: Bool

  var body: some View {
    Group {
      if self.isCorrect {
        CheckmarkAnimationView(startX: -120, startY: -370)
      }
    }
  }
}

private struct CheckmarkAnimationView: View {
  @State private var displayBorder = false
  @State private var displayCheckmark = false

  var startX: CGFloat
  var startY: CGFloat

  var body: some View {
    ZStack {
      Circle()
        .strokeBorder(style: StrokeStyle(lineWidth: displayBorder ? 5 : 64))
        .frame(width: 128, height: 128)
        .foregroundColor(.green)
        .animation(Animation.easeOut(duration: 0.6).speed(3.0))
        .onAppear {
          self.displayBorder.toggle()
        }
      Path { path in
        path.move(to: CGPoint(x: self.startX, y: self.startY))
        path.addLine(to: CGPoint(x: self.startX, y: self.startY))
        path.addLine(to: CGPoint(x: self.startX + 20, y: self.startY + 20))
        path.addLine(to: CGPoint(x: self.startX + 60, y: self.startY - 20))
      }.trim(from: 0, to: displayCheckmark ? 1 : 0)
        .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
        .foregroundColor(displayCheckmark ? .green : .white)
        .offset(x: 155, y: 450)
        .animation(Animation.interpolatingSpring(stiffness: 160, damping: 20).delay(0.3))
        .onAppear {
          self.displayCheckmark.toggle()
        }
    }
  }
}

private struct SpeedControlView: View {
  @Binding var value: Double

  var minSpeed: Double
  var maxSpeed: Double
  var disabled: Bool

  var body: some View {
    HStack {
      Image(systemName: "tortoise").foregroundColor(.gray)
      Slider(value: self.$value, in: self.minSpeed ... self.maxSpeed, step: 1)
        .disabled(self.disabled)
      Image(systemName: "hare").foregroundColor(.gray)
    }
  }
}

private struct AnswerInput: View {
  @Binding var value: String
  var onSubmit: () -> Void
  var isCorrect: Bool = true
  var isAlmostCorrect: Bool = true
  var disabled: Bool = false

  @EnvironmentObject var feedback: FeedbackService

  var body: some View {
    FocusableTextField(
      text: self.$value,
      isFirstResponder: true,
      placeholder: "WORD",
      textFieldShouldReturn: { _ in
        self.onSubmit()
        return true
      },
      modifyTextField: { textField in
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.keyboardType = .asciiCapable
        textField.font = .monospacedSystemFont(ofSize: 18.0, weight: .regular)
        textField.clearButtonMode = .whileEditing
        return textField
      },
      onUpdate: { textField in
        // Uppercase all input
        textField.text = self.value.uppercased()

        if self.feedback.isShown, !self.isCorrect {
          if self.isAlmostCorrect {
            // Highlight
            textField.layer.cornerRadius = 4.0
            textField.layer.borderColor = UIColor.systemYellow.withAlphaComponent(0.4).cgColor
            textField.layer.borderWidth = 2.0
          }

          // Shake input if incorrect
          let shake = CABasicAnimation(keyPath: "position")
          shake.duration = 0.05
          shake.repeatCount = self.isAlmostCorrect ? 1 : 2
          shake.autoreverses = true
          let displacement: CGFloat = 7
          shake.fromValue = NSValue(cgPoint: CGPoint(x: textField.center.x - displacement, y: textField.center.y))
          shake.toValue = NSValue(cgPoint: CGPoint(x: textField.center.x + displacement, y: textField.center.y))
          textField.layer.add(shake, forKey: "position")

        } else {
          // Remove highlight
          textField.layer.borderColor = nil
          textField.layer.borderWidth = 0
        }
      }
    )
    // Hide input after success.
    // Note: we use opacity to hide because the text field needs to be present for the keyboard
    //   to remain on the screen and we set the frame to 0 to make room for the correct word display.
    .frame(width: self.feedback.shouldDisableControls ? 0 : 280, height: self.feedback.hasCorrectAnswer ? 0 : 30)
    .opacity(self.feedback.shouldDisableControls ? 0 : 1)
  }
}

struct ReceptiveGameView_Previews: PreviewProvider {
  static var previews: some View {
    let playback = SystemServices.playback
    let feedback = SystemServices.feedback

    // Modify these during development to update the preview
    playback.isPlaying = false
    playback.currentWord = "foo"
    feedback.isShown = false

    return ReceptiveGameView().modifier(RootStyle()).modifier(SystemServices())
  }
}
