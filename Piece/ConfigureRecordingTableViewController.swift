//
//  ConfigureRecordingTableViewController.swift
//  Piece
//
//  Created by Eirik Vale Aase on 17.07.2016.
//  Copyright © 2016 Eirik Vale Aase. All rights reserved.
//

import UIKit
import CoreData

// MARK: @IBActions
private extension ConfigureRecordingTableViewController {
	@objc @IBAction func playAudio(_ sender: AnyObject) {
		audioPlayer = AudioPlayer(url: recording.url)
		audioPlayer?.player.play()
	}
	
	@objc @IBAction func save(_ sender: AnyObject) {
		guard let project = project, let section = section else { return }
		
		guard let newTitle = recordingTitleTextField.text, !isDuplicate(newTitle) else {
			showOKAlert(NSLocalizedString("Duplicate title!", comment: ""), message: nil)
			return
		}
		
		// The audio file is already created, so just rename it.
		pieFileManager.rename(recording, from: recording.title, to: newTitle, section: section, project: project)
		recording.title = newTitle
		recording.section = section
		recording.project = project
		coreDataStack.saveContext()
		
		// Get the view controller that presented the view controller that presented this view controller.
		presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
	}
	
	@objc @IBAction func cancel(_ sender: AnyObject) {
		// Notify the user if he/she tries to cancel the configuration of the recording.
		let localizedTitle = NSLocalizedString("Recording will be deleted. Proceed?", comment: "")
		let cancelAlert = UIAlertController(title: localizedTitle, message: nil, preferredStyle: .alert)
		let yesAction = UIAlertAction(title: "OK", style: .default) { _ in
			self.pieFileManager.delete(self.recording)
			self.coreDataStack.viewContext.delete(self.recording)
			self.coreDataStack.saveContext()
			
			// Get the view controller that presented the view controller that presented this view controller.
			self.presentingViewController?.presentingViewController?.dismiss(animated: true, completion: nil)
		}
		
		let noAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
		cancelAlert.addAction(yesAction)
		cancelAlert.addAction(noAction)
		
		present(cancelAlert, animated: true, completion: nil)
	}
}

// MARK: Helper Methods
private extension ConfigureRecordingTableViewController {
	/**
	Checks if a recording already has the current title.
	- parameter title: chosen title
	*/
	func isDuplicate(_ title: String) -> Bool {
		return section.recordings.contains { $0.title == title }
	}

	func showOKAlert(_ title: String, message: String?) {
		let alert = UIAlertController(title: title, message: message ?? nil, preferredStyle: .alert)
		let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil)
		alert.addAction(okAction)

		present(alert, animated: true, completion: nil)
	}
	
	func togglePicker(tagged tag: Int) {
		switch tag {
		case 111:
			projectPickerViewHidden = !projectPickerViewHidden
			projectPicker.isHidden = projectPickerViewHidden
		case 222:
			sectionPickerViewHidden = !sectionPickerViewHidden
			sectionPicker.isHidden = sectionPickerViewHidden
		default:
			break
		}
		
		if !projectPicker.isHidden {
			let selectedIndex = projects.index(of: project)!
			projectPicker.selectRow(selectedIndex, inComponent: 0, animated: true)
			projectDetailLabel.text = project.title
		}
		
		if !sectionPicker.isHidden {
			let selectedIndex = project.sections.contains(section) ? project.sections.sorted(by: {$0.title < $1.title}).index(of: section) : 0
			sectionPicker.selectRow(selectedIndex!, inComponent: 0, animated: true)
			sectionDetailLabel.text = section.title
		}
		
		// We need this otherwise the table view won't show the contents of the cell, namely the picker.
		tableView.beginUpdates()
		tableView.endUpdates()
		
		tableView.deselectRow(at: tableView.indexPathForSelectedRow!, animated: true)
	}
}

// MARK: UIPickerViewDelegate
extension ConfigureRecordingTableViewController: UIPickerViewDelegate {
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		switch pickerView.tag {
		case 111:
			guard projects.count > 0 else { return nil }
			return projects[row].title
		case 222:
			guard project.sections.count > 0 else { return nil }
			return project.sections.sorted(by: {$0.title < $1.title})[row].title
		default:
			return nil
		}
	}

	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		
		switch pickerView.tag {
		case 111:
			let selectedProject = projects[row]
			
			guard !selectedProject.sections.isEmpty else {
				showOKAlert(NSLocalizedString("No sections in project", comment: ""), message: nil)
				project = projects.first(where: { $0.sections.count > 0 })
				pickerView.selectRow(projects.index(of: project)!, inComponent: component, animated: true)
				
				return
			}
			
			// We don't want to change section if we bounce back to the same project in the projectPicker.
			guard selectedProject != project else { return }
			
			project = selectedProject
			section = project.sections.sorted(by: {$0.title < $1.title})[0]
		case 222:
			section = project.sections.sorted(by: {$0.title < $1.title})[row]
		default:
			break
		}
		
		projectDetailLabel.text = project.title
		sectionDetailLabel.text = section.title
	}
}

// MARK: UIPickerViewDataSource
extension ConfigureRecordingTableViewController: UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch pickerView.tag {
		case 111:
			return projects.count
		case 222:
			return project.sections.count
		default:
			return 0
		}
	}
}

/**
`ConfigureRecordingTableViewController` manages the configuration of a recording, primarily the title and the associated sectiona and project.
*/
class ConfigureRecordingTableViewController: UITableViewController {

	// MARK: @IBOutlets
	@IBOutlet weak var saveBarButton: UIBarButtonItem!
	@IBOutlet weak var recordingTitleTextField: UITextField! {
		didSet {
			recordingTitleTextField.adjustsFontSizeToFitWidth = true
			recordingTitleTextField.text = recording.title
			recordingTitleTextField.autocapitalizationType = .words
			recordingTitleTextField.autocorrectionType = .default
		}
	}
	@IBOutlet weak var sectionDetailLabel: UILabel! {
		didSet {
			sectionDetailLabel.text = section.title
			sectionDetailLabel.adjustsFontSizeToFitWidth = true
		}
	}
	@IBOutlet weak var projectDetailLabel: UILabel! {
		didSet {
			projectDetailLabel.text = section.project.title
			projectDetailLabel.adjustsFontSizeToFitWidth = true
		}
	}
	@IBOutlet weak var projectPicker: UIPickerView! {
		didSet {
			projectPicker.delegate = self
			projectPicker.dataSource = self
			projectPicker.tag = 111
			projectPicker.isHidden = true
		}
	}
	@IBOutlet weak var sectionPicker: UIPickerView! {
		didSet {
			sectionPicker.delegate = self
			sectionPicker.dataSource = self
			sectionPicker.tag = 222
			sectionPicker.isHidden = true
		}
	}

	// MARK: Properties
	fileprivate var audioPlayer: AudioPlayer? {
		didSet {
			audioPlayer?.player.volume = 1.0
		}
	}
	fileprivate var coreDataStack = CoreDataStack.sharedInstance
	fileprivate var pieFileManager = PIEFileManager()
	fileprivate var projectPickerViewHidden = true
	fileprivate var sectionPickerViewHidden = true
	var projects = [Project]()
	var recording: Recording!
	var section: Section!
	var project: Project!

	// MARK: View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let fetchRequest: NSFetchRequest<Project> = Project.fetchRequest() as! NSFetchRequest<Project>
		let sortDescriptor = NSSortDescriptor(key: #keyPath(Project.title), ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		
		do {
			projects = try self.coreDataStack.viewContext.fetch(fetchRequest)
		} catch {
			print(error.localizedDescription)
		}
		
		let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 40))
		label.text = NSLocalizedString("Configure and Save Recording", comment: "")
		label.adjustsFontSizeToFitWidth = true
		label.textColor = UIColor.white
		label.textAlignment = .center
		label.font = UIFont.boldSystemFont(ofSize: 16)
		navigationItem.titleView = label
		
		tableView.separatorStyle = .none
	}
	
	// MARK: UITableViewDelegate
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		return indexPath.section == 0 && indexPath.row == 0 ? nil : indexPath
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch (indexPath.section, indexPath.row) {
		case (1, 0):
			togglePicker(tagged: 111)
		case (2, 0):
			togglePicker(tagged: 222)
		default:
			break
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if (projectPickerViewHidden && indexPath.section == 1 && indexPath.row == 1) ||
			(sectionPickerViewHidden && indexPath.section == 2 && indexPath.row == 1) {
			return 0
		} else {
			return super.tableView(tableView, heightForRowAt: indexPath)
		}
	}

	// MARK: UIScrollViewDelegate
	override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		recordingTitleTextField.resignFirstResponder()
	}

}
