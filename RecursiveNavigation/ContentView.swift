//
//  ContentView.swift
//  RecursiveNavigation
//
//  Created by Ryan Carver on 10/16/21.
//

import ComposableArchitecture
import ComposablePresentation
import Foundation
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            OperatorsView(
                store: .init(
                    initialState: .init(
                        value: 1,
                        presentation: nil
                    ),
                    reducer: operatorsReducer,
                    environment: .init()
                )
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
