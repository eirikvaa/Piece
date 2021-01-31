//
//  HomeView.swift
//  Composify
//
//  Created by Eirik Vale Aase on 14/11/2020.
//  Copyright © 2020 Eirik Vale Aase. All rights reserved.
//

import SwiftUI
import SwiftUIPager

struct HomeView: View {
    @State private var page = 0
    private var items = Array(0..<5)
    private var recordings = Array(0..<5)
    private var sections = ["Intro", "Verse", "Solo", "Chorus", "Outro"]
    
    var body: some View {
        NavigationView {
            VStack {
                Pager(page: $page, data: items, id: \.self) { index in
                    VStack(alignment: .leading) {
                        HStack {
                            Text(sections[index])
                                .font(.title)
                                .bold()
                                .padding()
                            Spacer()
                        }
                        ForEach(recordings, id: \.self) { i in
                            HStack {
                                Button(action: {
                                    
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                        .padding()
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(PlainButtonStyle())
                                Text("Recording \(i)")
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 4.0)
                                    .stroke()
                            )
                        }
                        .padding(.horizontal)
                        Spacer()
                    }
                }
                
                Button(action: {
                    print("Hei")
                }) {
                    Text("Record")
                        .padding()
                        .foregroundColor(.white)
                }
                .frame(width: 200)
                .background(Color.red)
                .cornerRadius(4.0)
                
                Spacer()
            }
            .navigationBarTitle("Composify", displayMode: .inline)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .previewDevice("iPhone 7 Plus")
    }
}
