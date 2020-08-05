//
//  Recording.swift
//  Composify
//
//  Created by Eirik Vale Aase on 10.08.2016.
//  Copyright © 2016 Eirik Vale Aase. All rights reserved.
//

import Foundation
import RealmSwift

final class Recording: Object, ComposifyObject {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var title = ""
    @objc dynamic var project: Project?
    @objc dynamic var section: Section?
    @objc dynamic var dateCreated = Date()
    @objc dynamic var fileExtension = ""

    override static func primaryKey() -> String? {
        R.DatabaseKeys.id
    }
}

extension Recording {
    static func createRecording(title: String, section: Section, fileExtension: String = "caf") -> Recording {
        let recording = Recording()
        recording.title = title
        recording.section = section
        recording.project = section.project
        recording.fileExtension = fileExtension
        
        DatabaseServiceFactory.defaultService.performOperation {
            section.recordings.append(recording)
        }

        DatabaseServiceFactory.defaultService.save(recording)

        return recording
    }
}

extension Recording: AudioPlayable {
    var url: URL {
        R.URLs.recordingsDirectory
            .appendingPathComponent(id)
            .appendingPathExtension(fileExtension)
    }
}

extension Recording: Comparable {
    static func < (lhs: Recording, rhs: Recording) -> Bool {
        lhs.title < rhs.title
    }
}

extension FileManager {
    func deleteRecording(_ recording: Recording) {
        let url = recording.url
        guard fileExists(atPath: url.path) else {
            return
        }

        do {
            try removeItem(atPath: url.path)
        } catch {
            print(error.localizedDescription)
        }
    }
}
