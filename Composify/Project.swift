//
//  Project.swift
//  Composify
//
//  Created by Eirik Vale Aase on 10.08.2016.
//  Copyright © 2016 Eirik Vale Aase. All rights reserved.
//

import Foundation
import RealmSwift

final class Project: Object, ComposifyObject {
    @objc dynamic var id = UUID().uuidString
    @objc dynamic var dateCreated = Date()
    @objc dynamic var title = ""
    let sections = List<Section>()

    override static func primaryKey() -> String? {
        R.DatabaseKeys.id
    }
}

extension UserDefaults {
    
    func lastProject() -> Project? {
        guard let realm = try? Realm() else { return nil }
        guard let id = UserDefaults.standard.string(forKey: R.UserDefaults.lastProjectID) else { return nil }
        return realm.object(ofType: Project.self, forPrimaryKey: id)
    }
}

extension Project {
    static func projects() -> Results<Project> {
        guard let realm = try? Realm() else { fatalError("Unable to instantiate Realm!") }
        return realm.objects(Project.self)
    }
    
    /// Get the section that corresponds to the passed-in index
    /// - parameter index: An index that won't necessarily correspond to the
    /// order that sections were created.
    func getSection(at index: Int) -> Section? {
        for section in sections {
            if section.index == index {
                return section
            }
        }

        return nil
    }

    static func createProject(withTitle title: String) -> Project {
        let project = Project()
        project.title = title

        let databaseService = DatabaseServiceFactory.defaultService
        databaseService.save(project)

        return project
    }

    var nextSectionIndex: Int {
        let _section = sections.last
        let lastSectionIndex = _section?.index ?? 0
        return sections.hasElements ? lastSectionIndex + 1 : lastSectionIndex
    }

    func deleteSection(at index: Int) {
        guard let section = getSection(at: index) else {
            return
        }

        normalizeIndices(from: index)
        DatabaseServiceFactory.defaultService.delete(section)
    }
}

extension Project: Comparable {
    static func < (lhs: Project, rhs: Project) -> Bool {
        lhs.dateCreated < rhs.dateCreated
    }
}

private extension Project {
    /// This will normalize the section indices such as when one is deleted, any
    /// holes in the counting is filled.
    /// If we delete a section, it will create a whole unless we delete the last one.
    /// Say we have indices 0 - 1 - 2 and delete the middle, then we have 0 - 2 and the
    /// application will crash, because it only goes from 0 - 1. Solve this by getting all sections with an
    /// index greater than the passed in index and subtract one to close the gap.
    /// - parameter index: The index that is off by one. We don't need to normalize section indices before this point.
    func normalizeIndices(from index: Int) {
        for i in (index + 1) ..< sections.count {
            let section = getSection(at: i)
            DatabaseServiceFactory.defaultService.performOperation {
                section?.index -= 1
            }
        }
    }
}
