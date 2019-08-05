//
//  ViewController.swift
//  Tips
//
//  Created by Home on 8/5/19.
//  Copyright © 2019 Danylo Chantsev. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireImage
import Kanna
import CoreData
import SwiftyJSON

class ViewController: UIViewController , UITableViewDelegate , UITableViewDataSource {
	
//	struct Repository {
//		var name: String
//		var link: String
//		var imageURL: String
//	}
	
	var repo: [NSManagedObject] = []
	var json: JSON?
	
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var tableView: UITableView! {
		didSet {
			tableView.delegate = self
			tableView.dataSource = self
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		tableView.autoresizesSubviews = true
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let managedContext = appDelegate.persistentContainer.viewContext
		let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Repository")
		
		do {
			repo = try managedContext.fetch(fetchRequest)
		} catch let error as NSError {
			print("Could not fetch. \(error), \(error.userInfo)")
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return repo.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let thisRepo = repo[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "repCell", for: indexPath) as! RepoTableViewCell
		cell.nameLabel?.text = thisRepo.value(forKeyPath: "name") as? String
		cell.linkLabel?.text = thisRepo.value(forKeyPath: "link") as? String
//		cell.myImage?.text = thisRepo.value(forKeyPath: "image") as? String
		Alamofire.request(thisRepo.value(forKeyPath: "image") as? String ?? "", method: .get).responseImage { response in
			guard let image = response.result.value else { return }
			cell.myImage.image = image
		}
		return cell
	}
	
	@IBAction func searchPressed(_ sender: Any) {
		removeAllItemsFromCoreData()
		repo.removeAll()
		getDataFromGitHub(textField.text!)
	}
	
	func removeAllItemsFromCoreData() {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let managedContext = appDelegate.persistentContainer.viewContext
		for myRepo in repo {
			managedContext.delete(myRepo)
		}
	}
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let indexPath = tableView.indexPathForSelectedRow
		let currentCell = tableView.cellForRow(at: indexPath!) as! RepoTableViewCell
		guard let url = URL(string: currentCell.linkLabel.text!) else { return }
		UIApplication.shared.open(url)
	}
	func getDataFromGitHub(_ string: String) {
		Alamofire.request("https://api.github.com/search/repositories?q=" + string, method: .get).responseJSON { response in
			print("\(response.result.isSuccess)")
			switch response.result {
			case .success:
				self.json = JSON(response.value!)
				if self.json!.isEmpty { return }
				self.parseJSON(self.json!)
				break
			case .failure:
				break
			}
		}
	}
	
	func parseJSON(_ json: JSON) -> Void {
		var i = 0
		for item in json["items"] {
			save("\(item.1["full_name"])", "\(item.1["html_url"])", "\(item.1["owner"]["avatar_url"])")
			tableView.reloadData()
			i += 1
			if i == 30 { break }
		}
		print(repo)
	}
	
	func save(_ name: String, _ link: String, _ imageURL: String) {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let managedContext = appDelegate.persistentContainer.viewContext
		let entity = NSEntityDescription.entity(forEntityName: "Repository", in: managedContext)!
		let thisRepo = NSManagedObject(entity: entity, insertInto: managedContext)
		thisRepo.setValue(name, forKeyPath: "name")
		thisRepo.setValue(link, forKeyPath: "link")
		thisRepo.setValue(imageURL, forKeyPath: "image")
		do {
			try managedContext.save()
			repo.append(thisRepo)
		} catch let error as NSError {
			print("Could not save. \(error), \(error.userInfo)")
		}
		
	}
}

