//
//  ProjectView.swift
//  Composify
//
//  Created by Eirik Vale Aase on 01/05/2021.
//  Copyright © 2021 Eirik Vale Aase. All rights reserved.
//

import CoreData
import SwiftUI

struct ProjectView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(
        entity: Recording.entity(),
        sortDescriptors: []
    ) private var recordings: FetchedResults<Recording>

    @State private var projectTitle = ""

    let project: Project

    init(project: Project) {
        self.project = project
        self._projectTitle = .init(initialValue: project.title ?? "")
    }

    var createdAt: String {
        let createdAtDate = project.createdAt ?? Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: createdAtDate)
    }

    var body: some View {
        List {
            Section(header: Text("Title")) {
                TextField("Project title", text: $projectTitle) { _ in
                    project.title = projectTitle
                } onCommit: {
                    try! moc.save()
                }
            }
            Section(header: Text("Recordings")) {
                ForEach(recordings.filter { $0.project == project }, id: \.index) { recording in
                    Text(recording.title ?? "")
                }
                .onDelete(perform: removeRecordings)
            }
            Section(header: Text("Created At")) {
                Text(createdAt)
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(project.title ?? "")
        .onDisappear {
            try! moc.save()
        }
    }

    func removeRecordings(at indexes: IndexSet) {
        for index in indexes {
            let recording = recordings[index]
            moc.delete(recording)
        }

        try! moc.save()
    }
}

struct ProjectView_Previews: PreviewProvider {
    static var previews: some View {
        let controller = PersistenceController.preview
        let project = controller
            .container
            .viewContext
            .registeredObjects
            .first(where: { $0 is Project }) as! Project

        NavigationView {
            ProjectView(project: project)
        }
    }
}