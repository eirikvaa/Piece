//
//  ProjectsTableViewController.swift
//  Piece
//
//  Created by Eirik Vale Aase on 17.07.2016.
//  Copyright © 2016 Eirik Vale Aase. All rights reserved.
//

import UIKit
import CoreData

/**
`ProjectsTableViewController` shows and managed projects.
*/
class ProjectsTableViewController: UITableViewController {

	// MARK: Properties
	private var fetchedResultsController: NSFetchedResultsController<Project>!
	fileprivate var coreDataStack = CoreDataStack.sharedInstance
	fileprivate let pieFileManager = PIEFileManager()

	// MARK: View controller life cycle
	override func viewDidLoad() {
		super.viewDidLoad()

		let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest() as! NSFetchRequest<Project>
		let sortDescriptor = NSSortDescriptor(key: #keyPath(Project.title), ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		
		fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,managedObjectContext: self.coreDataStack.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		fetchedResultsController.delegate = self
		
		do {
			try fetchedResultsController.performFetch()
		} catch {
			print(error.localizedDescription)
		}
		
		navigationItem.rightBarButtonItem = self.editButtonItem
		navigationItem.title = "Projects".localized
	}
	
	// MARK: UITableView
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		if editing {
			let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addProject))
			navigationItem.leftBarButtonItem = addButton
		} else {
			navigationItem.leftBarButtonItem = nil
		}
	}

	// MARK: UITableViewDataSource
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let sectionInfo = fetchedResultsController.sections?[section] else { return 0 }
		
		return sectionInfo.numberOfObjects
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath)
		
		let project = fetchedResultsController.object(at: indexPath)
						
		cell.textLabel?.text = project.title
		cell.textLabel?.adjustsFontSizeToFitWidth = true
		
		let sectionsWord = project.sections.count == 1 ? "section".localized : "sections".localized
		let recordingsWord = project.recordings.count == 1 ? "recording".localized : "recordings".localized
		let localizedString = String.localizedStringWithFormat("%d %@ and %d %@".localized, project.sections.count, sectionsWord, project.recordings.count, recordingsWord)
		
		cell.detailTextLabel?.text = localizedString
		
		return cell
	}

	// MARK: UITableViewDelegate
	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		let renameAction = UITableViewRowAction(style: .normal, title: "Rename".localized, handler: { (rowAction, indexPath) in

			let renameAlert = UIAlertController(title: "Rename".localized, message: nil, preferredStyle: .alert)

			renameAlert.addTextField {
				$0.placeholder = self.fetchedResultsController.object(at: indexPath).title
				$0.autocapitalizationType = .words
				$0.clearButtonMode = .whileEditing
				$0.autocorrectionType = .default
			}

			let saveAction = UIAlertAction(title: "Save".localized, style: .default) { alertAction in
				if let title = renameAlert.textFields?.first?.text {
					let projects = self.fetchedResultsController.fetchedObjects!
					
					if projects.contains(where: { $0.title == title }) {
						return
					}
					
					let project = self.fetchedResultsController.object(at: indexPath)
					self.pieFileManager.rename(project, from: project.title, to: title, section: nil, project: nil)
					project.title = title
					self.coreDataStack.saveContext()
				}
			}

			let cancelAction = UIAlertAction(title: "Cancel".localized, style: .destructive, handler: nil)

			renameAlert.addAction(saveAction)
			renameAlert.addAction(cancelAction)

			self.present(renameAlert, animated: true, completion: nil)
		})

		let deleteAction = UITableViewRowAction(style: .normal, title: "Delete".localized) { (rowAction, indexPath) in
			let project = self.fetchedResultsController.object(at: indexPath)
			self.pieFileManager.delete(project)
			self.coreDataStack.viewContext.delete(project)
			self.coreDataStack.saveContext()
		}

		renameAction.backgroundColor = UIColor(red: 68.0 / 255.0, green: 108.0 / 255.0, blue: 179.0 / 255.0, alpha: 1.0)
		deleteAction.backgroundColor = UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)

		return [renameAction, deleteAction]
	}
	
	// MARK: Navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "showSections" {
			if let destinationViewController = segue.destination as? SectionsTableViewController,
				let indexPath = tableView.indexPathForSelectedRow {
				destinationViewController.chosenProject = fetchedResultsController.object(at: indexPath)
			}
		}
	}
	
}

extension String {
	var localized: String {
		return NSLocalizedString(self, comment: "")
	}
}

// MARK: Helper Methods
private extension ProjectsTableViewController {
	@objc func addProject() {
		let alert = UIAlertController(title: "New Project".localized, message: nil, preferredStyle: .alert)
		
		alert.addTextField {
			$0.placeholder = "Project Title".localized
			$0.autocapitalizationType = .words
			$0.clearButtonMode = .whileEditing
		}
		
		let save = UIAlertAction(title: "Save".localized, style: .default) { alertAction in
			if let projectTitle = alert.textFields?.first?.text, let project = NSEntityDescription.insertNewObject(forEntityName: "Project", into: self.coreDataStack.viewContext) as? Project {
				project.title = projectTitle
				self.pieFileManager.save(project)
				self.coreDataStack.saveContext()
			}
		}
		
		let cancel = UIAlertAction(title: "Cancel".localized, style: .destructive, handler: nil)
		
		alert.addAction(save)
		alert.addAction(cancel)
		
		present(alert, animated: true, completion: nil)
	}
}

// MARK: NSFetchedResultsController
extension ProjectsTableViewController: NSFetchedResultsControllerDelegate {
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.beginUpdates()
	}
	
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
		switch type {
		case .insert:
			if let newIndexPath = newIndexPath {
				tableView.insertRows(at: [newIndexPath], with: .fade)
			}
		case .update:
			if let indexPath = indexPath {
				tableView.reloadRows(at: [indexPath], with: .fade)
			}
		case .delete:
			if let indexPath = indexPath {
				tableView.deleteRows(at: [indexPath], with: .fade)
			}
		case .move:
			if let indexPath = indexPath, let newIndexPath = newIndexPath {
				tableView.deleteRows(at: [indexPath], with: .fade)
				tableView.insertRows(at: [newIndexPath], with: .fade)
			}
		}
	}
	
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		tableView.endUpdates()
	}
}
