//
//  ToDoListViewController.swift
//  ToDoCoreData
//
//  Created by Александр Басов on 06/10/2021.
//  Copyright © 2021 Александр Басов. All rights reserved.
//

import UIKit
import CoreData

class ToDoListViewController: UITableViewController {
    
    var selectedCategory: Category? {
           didSet {
               self.title = selectedCategory?.name
           }
       }
       
       let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
       
       var itemArray = [Item]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
         loadItems()
    }

    // MARK: - Table view data source

  

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TodoItemCell", for: indexPath)
        cell.textLabel?.text = itemArray[indexPath.row].title
        cell.accessoryType = itemArray[indexPath.row].done ? .checkmark : .none
        return cell
    }
    
       override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            // deselect
            tableView.deselectRow(at: indexPath, animated: true)
    //        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
            itemArray[indexPath.row].done.toggle()
            self.saveItems()
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            // To delete from core data we need to fetch the object we are looking for
            //
            if let categoryName = selectedCategory?.name, let itemName = itemArray[indexPath.row].title {
                let request: NSFetchRequest<Item> = Item.fetchRequest()
                let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", categoryName)
                let itemPredicate = NSPredicate(format: "title MATCHES %@", itemName)
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, itemPredicate])

                if let results = try? context.fetch(request) {
                    for object in results {
                        context.delete(object)
                    }
                    // Save the context and delete the data locally
                    //
                    itemArray.remove(at: indexPath.row)
                    saveItems()
                    tableView.reloadData()
                }
            }
        }
    }
   

    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func addItemPressed(_ sender: Any) {
        let alert = UIAlertController(title: "Add New Item", message: "", preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Your task"
        }

        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        let action = UIAlertAction(title: "Add Item", style: .default) { _ in
            if let textField = alert.textFields?.first {
                if textField.text != "", let title = textField.text {
                    let newItem = Item(context: self.context)
                    newItem.title = title
                    newItem.done = false
                    newItem.parentCategory = self.selectedCategory

                    self.itemArray.append(newItem)
                    self.tableView.reloadData()
                    self.saveItems()
                }
            }
        }

        alert.addAction(action)
        alert.addAction(cancel)

        self.present(alert, animated: true)
    }
    

    private func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
           if let name = selectedCategory?.name {
               let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)

               if let additionalPredicate = predicate {
                   request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
               } else {
                   request.predicate = categoryPredicate
               }

               do {
                   itemArray = try context.fetch(request)
               } catch {
                   print("Error fetching data from context: \(error)")
               }
               tableView.reloadData()
           }
       }
    
        // Универсальная ф-я со входным предикатом
        
//        private func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
//            if let name = selectedCategory?.name {
//                let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", name)
//
//                if let additionalPredicate = predicate {
//                    request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
//                } else {
//                    request.predicate = categoryPredicate
//                }
//
//                do {
//                    itemArray = try context.fetch(request)
//                } catch {
//                    print("Error fetching data from context: \(error)")
//                }
//                tableView.reloadData()
//            }
//        }
        
        private func saveItems() {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
}

extension ToDoListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.isEmpty == true {
            // User just cleared the search bar reload everything so their previous search is gone
            //
            loadItems()
            searchBar.resignFirstResponder() // останавливаем и выходим из searchBar
        } else {
            let request: NSFetchRequest<Item> = Item.fetchRequest()
            // [cd] makes the search case and diacritic insensitive http://nshipster.com/nspredicate/
            //
            let searchPredicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
            request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
            loadItems(with: request, predicate: searchPredicate)
            
            tableView.reloadData()
        }
    }
}
