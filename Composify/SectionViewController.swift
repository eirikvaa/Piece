//
//  SectionViewController.swift
//  Composify
//
//  Created by Eirik Vale Aase on 20.01.2017.
//  Copyright © 2017 Eirik Vale Aase. All rights reserved.
//

import UIKit

class SectionViewController: UIViewController {
    // MARK: Regular Properties

    var currentlyPlayingRecording: AudioPlayable?
    var audioDefaultService: AudioPlayerService?
    var databaseService = DatabaseServiceFactory.defaultService
    var libraryViewController: LibraryViewController?
    var section: Section?
    var tableView = UITableView(frame: .zero, style: .plain)

    init(section: Section?) {
        self.section = section
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureTableView()
    }
}

private extension SectionViewController {
    func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(RecordingTableViewCell.self, forCellReuseIdentifier: R.Cells.libraryRecordingCell)
        tableView.rowHeight = UIScreen.main.isSmall ? 66 : 55

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
}