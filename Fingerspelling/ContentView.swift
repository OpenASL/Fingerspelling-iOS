//
//  ContentView.swift
//  Fingerspelling
//
//  Created by Steven Loria on 3/7/20.
//

import SwiftUI

struct ContentView: View {
  @State private var alertIsVisible: Bool = false
  @State private var speed = 5.0
  @State private var answer: String = ""
  @State private var showValidation: Bool = false
  @ObservedObject private var keyboard = KeyboardResponder()
  
  private let minSpeed = 0.0
  private let maxSpeed = 10.0
  
  private var isAnswerValid: Bool {
    let trimmedString = self.answer.trimmingCharacters(in: .whitespaces).lowercased()
    return trimmedString == "test"
  }

  var body: some View {
    VStack {
      Spacer()
      HStack {
        Image("B").resizable().aspectRatio(contentMode: .fit)
      }.padding(.horizontal, 100)

      HStack {
        if self.showValidation {
          TextField("Answer", text: $answer).border(self.isAnswerValid ? Color.green : Color.red)
        } else {
          TextField("Answer", text: $answer)
        }
        Spacer()
        Button(action: {
          self.showValidation = true
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
          self.showValidation = false
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
    }
    .padding(.vertical, 20)
    .padding(.horizontal, 40)
    // Move the current UI up when the keyboard is active
    .padding(.bottom, keyboard.currentHeight)
    .animation(.easeIn(duration: 0.16))
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
