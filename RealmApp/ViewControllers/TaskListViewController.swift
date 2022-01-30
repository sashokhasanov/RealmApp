//
//  TaskListsViewController.swift
//  RealmApp
//
//  Created by Alexey Efimov on 02.07.2018.
//  Copyright © 2018 Alexey Efimov. All rights reserved.
//  Contributed by Aleksandr Khasanov
//

import UIKit
import RealmSwift

class TaskListViewController: UITableViewController {

    var taskLists: Results<TaskList>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        taskLists = StorageManager.shared.realm.objects(TaskList.self)
        
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addButtonPressed)
        )
        
        navigationItem.rightBarButtonItem = addButton
        navigationItem.leftBarButtonItem = editButtonItem
        
        createTempData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        taskLists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskListCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        let taskList = taskLists[indexPath.row]
        content.text = taskList.name
        content.secondaryText = getTaskListDetails(taskList)
        cell.contentConfiguration = content
        return cell
    }
    
    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let taskList = taskLists[indexPath.row]
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
            StorageManager.shared.delete(taskList)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        let editAction = UIContextualAction(style: .normal, title: "Edit") { _, _, isDone in
            self.showAlert(with: taskList) {
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            isDone(true)
        }
        
        let isCompleteList = isTaskListComplete(taskList)
        let doneAction = UIContextualAction(style: .normal,
                                            title: !isCompleteList ? "Done" : "Undone") { _, _, isDone in
            StorageManager.shared.done(taskList, isComplete: !isCompleteList)
            tableView.reloadRows(at: [indexPath], with: .automatic)
            isDone(true)
        }
        
        editAction.backgroundColor = .orange
        doneAction.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        
        return UISwipeActionsConfiguration(actions: [doneAction, editAction, deleteAction])
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        guard let tasksVC = segue.destination as? TasksViewController else { return }
        let taskList = taskLists[indexPath.row]
        tasksVC.taskList = taskList
    }

    @IBAction func sortingList(_ sender: UISegmentedControl) {
        var keyPath = ""
        switch sender.selectedSegmentIndex {
        case 0:
            keyPath = "date"
        default:
            keyPath = "name"
        }
        
        taskLists = taskLists.sorted(byKeyPath: keyPath)
        tableView.reloadData()
    }
    
    @objc private func  addButtonPressed() {
        showAlert()
    }
    
    private func createTempData() {
        DataManager.shared.createTempDataV2 {
            self.tableView.reloadData()
        }
    }
    
    private func getTaskListDetails(_ taskList: TaskList) -> String {
        let isComplete = isTaskListComplete(taskList)
        return isComplete ? "✅" : String(getUnfinishedTasksCount(taskList))
    }

    private func isTaskListComplete(_ taskList: TaskList) -> Bool {
        guard !taskList.tasks.isEmpty else { return false }
        return getUnfinishedTasksCount(taskList) == 0
    }
    
    private func getUnfinishedTasksCount(_ taskList: TaskList) -> Int {
        return taskList.tasks.filter("isComplete = false").count
    }
}

extension TaskListViewController {
    
    private func showAlert(with taskList: TaskList? = nil, completion: (() -> Void)? = nil) {
        let title = taskList != nil ? "Edit List" : "New List"
        let alert = UIAlertController.createAlert(withTitle: title, andMessage: "Please set title for new task list")
        
        alert.action(with: taskList) { newValue in
            if let taskList = taskList, let completion = completion {
                StorageManager.shared.edit(taskList, newValue: newValue)
                completion()
            } else {
                self.save(taskList: newValue)
            }
        }
        
        present(alert, animated: true)
    }
    
    private func save(taskList: String) {
        let taskList = TaskList(value: [taskList])
        StorageManager.shared.save(taskList)
        
        let rowIndex = IndexPath(row: taskLists.index(of: taskList) ?? 0, section: 0)
        tableView.insertRows(at: [rowIndex], with: .automatic)
    }
}
