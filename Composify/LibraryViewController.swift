//
//  LibraryViewController.swift
//  Composify
//
//  Created by Eirik Vale Aase on 13.01.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import Parchment
import UIKit

/// The view controller for almost all of the functionality; shows projects, sections and recordings.

final class LibraryViewController: UIViewController {
    @IBOutlet private var administerBarButton: UIBarButtonItem!
    @IBOutlet private var recordAudioButton: RecordAudioButton!
    @IBOutlet private var recordAudioView: UIView!
    @IBOutlet private var containerView: UIView!
    @IBOutlet private var pageControl: LibraryPageControl!

    // Properties
    var currentProject: Project?
    var currentSection: Section?

    private var errorViewController: ErrorViewController?
    private var state: LibraryViewController.State = .noSections
    private let pagingViewController = PagingViewController()
    private var audioRecorderDefaultService: AudioRecorderService?
    private var recording: Recording?
    private var grantedPermissionsToUseMicrophone = false

    override func viewDidLoad() {
        super.viewDidLoad()

        currentProject = UserDefaults.standard.lastProject() ?? RealmRepository().getAll().first
        currentSection = UserDefaults.standard.lastSection() ?? currentProject?.sections.first

        showOnboardingIfNeeded()

        configurePagingViewController()
        setupUI()
        registerObservers()
        updateUI()
        applyAccessibility()
        askForRecordingPermissions()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        pagingViewController.pageViewController.selectedViewController?.setEditing(editing, animated: animated)
    }
}

// MARK: @IBActions

extension LibraryViewController {
    @IBAction private func administrateProject(_: UIBarButtonItem) {
        var administrate: UIAlertAction?

        let alert = UIAlertController(title: R.Loc.menu, message: nil, preferredStyle: .actionSheet)

        // Be able to administrate project if there is one
        if let currentProject = currentProject {
            administrate = UIAlertAction(title: R.Loc.administrateProject, style: .default) { _ in
                self.presentAdministrateViewController(
                    viewController: EditExistingProjectViewController(project: currentProject)
                )
            }
        }

        // Can alway add a project
        let addProject = UIAlertAction(title: R.Loc.addProject, style: .default) { _ in
            self.showCreateNewProjectFlow()
        }

        // Showing other projects
        RealmRepository<Project>().getAll().forEach { project in
            if project != currentProject {
                let projectAction = UIAlertAction(
                    title: R.Loc.showProject(named: project.title),
                    style: .default
                ) { action in
                    self.applyAccessibility(for: action)
                    self.setCurrentProject(project)
                    self.rememberProjectChosen(project)
                }
                alert.addAction(projectAction)
            }
        }

        let cancel = UIAlertAction(title: R.Loc.cancel, style: .cancel)

        if let administrate = administrate {
            alert.addAction(administrate)
        }

        alert.addAction(addProject)
        alert.addAction(cancel)

        present(alert, animated: true)
    }

    @IBAction private func recordAudio(_: UIButton) {
        if recording == nil {
            startRecordingSession()
        } else {
            stopRecordingSession()
        }
    }
}

extension LibraryViewController {
    /// Start a recording session.
    /// Overwrite the currently initialized recording.
    func startRecordingSession() {
        let recording = Recording()
        recording.title = R.Loc.recording
        recording.section = currentSection
        recording.project = currentSection?.project
        recording.fileExtension = "caf"

        self.recording = recording

        do {
            audioRecorderDefaultService = try AudioRecorderServiceFactory.defaultService(withURL: recording.url)
        } catch AudioRecorderServiceError.unableToConfigureRecordingSession {
            let title = R.Loc.unableToConfigureRecordingSessionTitle
            let message = R.Loc.unableToConfigureRecordingSessionMessage
            let alert = UIAlertController.createErrorAlert(title: title, message: message)
            present(alert, animated: true)
            return
        } catch {
            print(error.localizedDescription)
            return
        }

        audioRecorderDefaultService?.record()

        recordAudioButton.setTitle(R.Loc.stopRecording, for: .normal)
        updateUI()
    }

    /// Stop the recording session.
    /// Only save the recording if it was successfully created.
    func stopRecordingSession() {
        audioRecorderDefaultService?.stop()

        if let recording = recording, let currentSection = currentSection {
            RealmRepository().save(recording: recording, to: currentSection)
        }

        recordAudioButton.setTitle(R.Loc.startRecording, for: .normal)
        updateUI()
    }

    func askForRecordingPermissions() {
        AudioRecorderPermissions.askForMicrophonePermissions { [weak self] granted in
            self?.grantedPermissionsToUseMicrophone = granted
        }
    }

    func showCreateNewProjectFlow() {
        presentAdministrateViewController(viewController: CreateNewProjectViewController())
    }

    /// Persist the project to userdefaults so it can be picked the next time
    /// the user launches the app.
    /// - parameter project: The project to be persisted
    func rememberProjectChosen(_: Project) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(currentProject?.id, forKey: R.UserDefaults.lastProjectID)
    }

    func registerObservers() {
        let notificationCenter = NotificationCenter.default

        let sizeChangeNotification = UIContentSizeCategory.didChangeNotification
        notificationCenter.addObserver(
            self,
            selector: #selector(adaptToDynamicSizeChange),
            name: sizeChangeNotification,
            object: nil
        )
    }

    @objc
    func adaptToDynamicSizeChange(_: Notification) {}

    /// Set the new current project
    /// - parameter project: The project that should now be shown
    func setCurrentProject(_ project: Project) {
        currentProject = project
        currentSection = currentProject?.sections.first

        updateUI()
    }

    func setupUI() {
        navigationItem.leftBarButtonItem?.title = R.Loc.menu
    }

    func setEditButton() {
        navigationItem.rightBarButtonItem = currentSection?.recordings.hasElements ?? false ? editButtonItem : nil
    }

    /// Update the user interface, mainly concerned with updating the state
    func updateUI() {
        switch (currentProject, currentSection) {
        case (.some, .some):
            state = .notEmpty
        case (.some, .none):
            state = .noSections
        case (.none, _):
            state = .noProjects
        }

        setState(state)

        pagingViewController.reloadData()

        setEditButton()

        configurePageControl()

        // We do this in `viewDidLoad`, but since the view controller state dictates if the
        // record audio button should be read in voice over mode, apply the accessibility
        // again here.
        applyAccessibility()
    }

    /// Set the state of the user interface
    /// - parameter state: The state that should be set
    func setState(_ state: State) {
        errorViewController?.remove()

        switch state {
        case .notEmpty:
            break
        case .noProjects:
            errorViewController = ErrorViewController(
                message: R.Loc.noProjects,
                actionMessage: R.Loc.addProject,
                action: {
                    self.showCreateNewProjectFlow()
                }
            )
            if let errorViewController = errorViewController {
                add(errorViewController)
            }
        case .noSections:
            errorViewController = ErrorViewController(
                message: R.Loc.noSections,
                actionMessage: R.Loc.addSection,
                action: {
                    guard let currentProject = self.currentProject else {
                        return
                    }

                    let viewController = EditExistingProjectViewController(project: currentProject)
                    self.presentAdministrateViewController(viewController: viewController)
                }
            )
            if let errorVieController = errorViewController {
                add(errorVieController)
            }
        }

        navigationItem.title = currentProject?.title ?? R.Loc.composify
    }

    /// State enum for the user interface
    enum State {
        case noProjects
        case noSections
        case notEmpty
    }

    /// Present the view controller for administrating a given project
    /// - parameter project: The project that should be administrated
    func presentAdministrateViewController(viewController: AdministrateProjectViewController) {
        viewController.administrateProjectDelegate = self
        let navigationController = UINavigationController(rootViewController: viewController)
        present(navigationController, animated: true)
    }

    func configurePageControl() {
        pageControl.numberOfPages = currentProject?.sections.count ?? 0
        pageControl.currentPage = currentSection?.index ?? 0
    }

    /// Configure the paging view controller
    func configurePagingViewController() {
        pagingViewController.register(LibraryCollectionViewCell.self, for: SectionPageItem.self)
        pagingViewController.indicatorColor = R.Colors.cardinalRed
        pagingViewController.menuHorizontalAlignment = .center
        pagingViewController.dataSource = self
        pagingViewController.delegate = self

        // Set the size for page items
        // 65 is a bit tall for the smallest font sizes, but it doesn't break,
        // so it's fine for now.
        pagingViewController.menuItemSize = .sizeToFit(minWidth: 150, height: 65)

        add(pagingViewController)
        pagingViewController.view.translatesAutoresizingMaskIntoConstraints = false

        pagingViewController.view.pinToEdges(of: containerView)
    }

    /// Possibly show onboarding
    func showOnboardingIfNeeded() {
        let userDefaults = UserDefaults.standard
        let hasSeenOnboarding = userDefaults.bool(forKey: R.UserDefaults.hasSeenOnboarding)

        if !hasSeenOnboarding {
            let onboardingRootViewController = UIViewController.onboardingRootViewController()
            present(onboardingRootViewController, animated: true)
        }
    }
}

extension LibraryViewController: AdministrateProjectDelegate {
    func userDidAddSectionToProject(_ section: Section) {
        currentSection = section

        updateUI()
    }

    func userDidDeleteSectionFromProject() {
        currentSection = currentProject?.sections.first

        updateUI()
    }

    func userDidEditTitleOfObjects() {
        updateUI()
    }

    func userDidDeleteProject() {
        currentProject = RealmRepository().getAll().first
        currentSection = currentProject?.sections.first

        updateUI()
    }

    func userDidReorderSections() {
        updateUI()
    }

    func userDidCreateProject(_ project: Project) {
        currentProject = project
        currentSection = project.sections.first

        updateUI()
    }
}

extension LibraryViewController {
    func applyAccessibility() {
        let startRecording = recording == nil
        if let menuBarButton = navigationItem.leftBarButtonItem {
            menuBarButton.isAccessibilityElement = true
            menuBarButton.accessibilityTraits = .button
            menuBarButton.accessibilityHint = R.Loc.menuBarButtonAccHint
        }

        navigationItem.accessibilityTraits = .staticText
        navigationItem.accessibilityLabel = R.Loc.libraryNavigationItemAccLabel

        let recordAudioButtonIsVisible = state == .notEmpty
        recordAudioButton.isAccessibilityElement = recordAudioButtonIsVisible == true
        recordAudioButton.titleLabel?.isAccessibilityElement = recordAudioButtonIsVisible == true
        recordAudioButton.accessibilityTraits = [.button, .startsMediaSession]
        recordAudioButton.accessibilityLabel = R.Loc.libraryRecordAudioButtonAccLabel
        recordAudioButton.accessibilityHint = startRecording ? R.Loc.libraryRecordAudioButtonAccStartRecordingHint :
            R.Loc.libraryRecordAudioButtonAccStopRecordingHint
    }

    func applyAccessibility(for action: UIAlertAction) {
        action.isAccessibilityElement = true
        action.accessibilityTraits = .button
        action.accessibilityValue = action.title
        action.accessibilityHint = R.Loc.menuChooseProjectAccHint
        action.accessibilityLabel = R.Loc.menuChooseProjectAccLabel
    }
}
