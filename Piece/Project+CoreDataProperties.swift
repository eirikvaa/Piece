//
//  Project+CoreDataProperties.swift
//  Piece
//
//  Created by Eirik Vale Aase on 10.08.2016.
//  Copyright © 2016 Eirik Vale Aase. All rights reserved.
//

import Foundation
import CoreData

extension Project: FileSystemObject {
	var fileSystemURL: URL {
		let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
		return documentDirectory
			.appendingPathComponent(FileSystemDirectories.userProjects.rawValue)
			.appendingPathComponent(title)
	}
}

extension Project {
	@NSManaged var title: String
	@NSManaged var sections: NSOrderedSet
	@NSManaged var recordings: NSOrderedSet
}
