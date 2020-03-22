import SwiftUI

struct ExpressiveStatsView: View {
  @EnvironmentObject var game: GameState

  init() {
    // Remove extra separators below the list
    UITableView.appearance().tableFooterView = UIView()
  }

  private var longestWord: String {
    self.game.expressiveCompletedWords.max(by: { $0.count < $1.count }) ?? ""
  }

  private var averageWordLength: Double {
    (self.game.expressiveCompletedWords.map { $0.count }).average
  }

  var body: some View {
    NavigationView {
      List {
        StatItemWithIconView(
          iconName: "checkmark",
          label: "Words completed"
        ) {
          Text(String(self.game.expressiveScore))
        }

        if !self.game.expressiveCompletedWords.isEmpty {
          StatItemView(label: "Longest word") {
            Text(self.longestWord.uppercased())
              .font(.system(size: 18, design: .monospaced))
          }
          StatItemView(label: "Average word length") {
            Text(formatNumber(self.averageWordLength))
          }
        }
      }
      .navigationBarTitle("Stats (Expressive)")
      .navigationBarItems(trailing: Button(action: self.handleToggle) { Text("Done") })
    }
  }

  private func handleToggle() {
    self.game.toggleSheet(.expressiveStats)
  }
}

struct ExpressiveStatsView_Previews: PreviewProvider {
  static var previews: some View {
    let game = SystemServices.game
    game.expressiveCompletedWords = [
      "fly",
      "turkey",
      "heavy",
    ]
    return ExpressiveStatsView()
      .modifier(SystemServices())
  }
}
