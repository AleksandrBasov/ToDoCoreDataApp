//
//  CategoryViewControllers.swift
//  ToDoCoreData
//
//  Created by Александр Басов on 06/10/2021.
//  Copyright © 2021 Александр Басов. All rights reserved.
//

import UIKit
import CoreData

class CategoryViewControllers: UITableViewController {
    
    var categories = [Category]()
    // или вот так var categories: [Category] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    override func viewDidLoad() {
        super.viewDidLoad()
        loadCategories()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return categories.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryCell", for: indexPath)
        cell.textLabel?.text = categories[indexPath.row].name
        return cell
    }
    

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            // To delete from core data we need to fetch the object we are looking for
            //
            if let name = categories[indexPath.row].name {
                let request: NSFetchRequest<Category> = Category.fetchRequest()
                request.predicate = NSPredicate(format: "name MATCHES %@", name)
                //request.predicate = NSPredicate(format: "name==\(category)")

                if let categories = try? context.fetch(request) {
                    for category in categories {
                        context.delete(category)
                    }
                    // Save the context so our changes persist and We also have to delete the local copy of the data
                    //
                    self.categories.remove(at: indexPath.row)
                    saveCategories()
                    tableView.reloadData()
                }
            }
        }
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToItems", sender: nil)
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? ToDoListViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                destinationVC.selectedCategory = categories[indexPath.row]
            }
        }
    }


    
    @IBAction func addBarButonPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Add New Category", message: "", preferredStyle: .alert)

              alert.addTextField { textField in
                  textField.placeholder = "Category placeholder"
              }

              let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
              let action = UIAlertAction(title: "Add Category", style: .default) { _ in
                  if let textField = alert.textFields?.first {
                      if textField.text != "", let text = textField.text {
                          let newCategory = Category(context: self.context)
                          newCategory.name = text

                          self.categories.append(newCategory)
                          self.saveCategories()
                          self.tableView.reloadData()
                      }
                  }
              }

              alert.addAction(action)
              alert.addAction(cancel)

              self.present(alert, animated: true)
    }
    
    
    private func loadCategories(with request: NSFetchRequest<Category> = Category.fetchRequest()) {
        do {
            categories = try context.fetch(request)
        } catch {
            print("Error fetching data from context: \(error)")
        }
        tableView.reloadData()
    }
    
    private func saveCategories() {
           do {
               try context.save()
           } catch {
               print("Error saving context: \(error)")
           }
       }
}
