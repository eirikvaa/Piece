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
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isShowingNewProjectView = false
    @State private var isShowingEditProjectView = false
    @State private var currentSection = Section()

    var body: some View {
        NavigationView {
            VStack {
                switch (viewModel.currentProject, viewModel.currentSection) {
                case let (project?, .some):
                    VStack {
                        SectionsPager(sections: Array(project.sections), currentSection: $currentSection)
                        Spacer()
                        RecordButton(isRecording: $audioRecorder.isRecording) {
                            if audioRecorder.isRecording {
                                let url = audioRecorder.stopRecording()
                                let recording = Recording(
                                    title: url.lastPathComponent,
                                    section: currentSection,
                                    url: url.absoluteString
                                )
                                viewModel.save(recording: recording)
                            } else {
                                audioRecorder.startRecording()
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) {
                            Button(action: {
                                isShowingEditProjectView = true
                            }, label: {
                                Text("Edit Project")
                            })
                        }
                    }
                    .sheet(isPresented: $isShowingEditProjectView) {
                        EditProjectView(project: Binding<Project>(
                                            get: { project },
                                            set: { _ in })
                        ) { _ in
                            viewModel.loadData()
                        }
                    }
                case (let project?, nil):
                    Button(action: {
                        isShowingEditProjectView = true
                    }, label: {
                        Text("Edit \(project.title)")
                    })
                        .sheet(isPresented: $isShowingEditProjectView) {
                            EditProjectView(project: Binding<Project>(
                                                get: { project },
                                                set: { _ in })
                            ) { _ in
                                viewModel.loadData()
                            }
                        }
                case (nil, nil):
                    Button(action: {
                        isShowingNewProjectView = true
                    }, label: {
                        Text("Add project")
                    })
                    .sheet(isPresented: $isShowingNewProjectView) {
                        NewProjectView()
                    }
                case (nil, .some):
                    fatalError("Impossible ot have a section without a project.")
                }
            }
            .navigationBarTitle("Composify", displayMode: .inline)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
