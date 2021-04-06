//
//  ContentView.swift
//  Shared
//
//  Created by Lai Wei on 2021-04-05.
//

import SwiftUI
import CoreData

struct ContentView: View {

    let currentWeather = CurrentWeather.shared
    var body: some View {
        Button("print") {
            currentWeather.getCurrentWeather()
        }
    }

    }



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
