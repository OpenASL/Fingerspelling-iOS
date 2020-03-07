//
//  ContentView.swift
//  Fingerspelling
//
//  Created by Steven Loria on 3/7/20.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject private var keyboard = KeyboardResponder()
  @State var alertIsVisible: Bool = false
  @State var speed = 5.0
  @State private var answer: String = ""
  @State var isAnswerValid: Bool = true
  @State var hasBeenValidated: Bool = false
  let minSpeed = 0.0
  let maxSpeed = 10.0
  
  func validateAnswer(answer: String) {
    let trimmedString = answer.trimmingCharacters(in: .whitespaces).lowercased()
    self.isAnswerValid = trimmedString == "test"
    self.hasBeenValidated = true
    return
  }

  var body: some View {
    VStack {
      Spacer()
      HStack {
        Image("B").resizable().aspectRatio(contentMode: .fit)
      }.padding(.horizontal, 100)

      HStack {
        if self.hasBeenValidated {
          if self.isAnswerValid {
            TextField("Answer", text: $answer).border(Color.green)
          } else {
            TextField("Answer", text: $answer).border(Color.red)
          }
        } else {
          TextField("Answer", text: $answer)
        }
        Spacer()
        Button(action: {
          self.validateAnswer(answer: self.answer)
        }) {
          Text("Check")
        }
      }.padding(.top, 20)
      
      VStack {
        HStack {
          Text("Slow")
          Slider(value: self.$speed, in: self.minSpeed...self.maxSpeed)
          Text("Fast")
        }
        Button(action: {
          self.speed = (self.maxSpeed - self.minSpeed) / 2
        }) {
          Text("Reset speed")
        }
      }.padding(.vertical, 30)
      
      HStack {
        Button(action: {
          self.alertIsVisible = true
          self.hasBeenValidated = false
          self.answer = ""
        }) {
          Text("Next word")
        }
        .alert(isPresented: $alertIsVisible) { () -> Alert in
          return Alert(
            title: Text("TODO"),
            message: Text("show next word")
          )
        }
      }
    }.padding(.vertical, 20).padding(.horizontal, 40)
    .padding(.bottom, keyboard.currentHeight)
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
