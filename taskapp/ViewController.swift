//
//  ViewController.swift
//  taskapp
//
//  Created by 濱田龍輝 on 2019/09/05.
//  Copyright © 2019 Ryuuki.hamada. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var filterTextField: UITextField!
    @IBOutlet weak var title_category: UISegmentedControl!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()  // ←追加
    
    // DB内のタスクが格納されるリスト。
    // 日付近い順\順でソート：降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)  // ←追加
    var check_taskArray : Task!
    var search_id_number : Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        title_category.selectedSegmentIndex = 0
        filterTextField.text = ""
        filterTextField.placeholder = "タイトル検索"
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    // segue で画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
            inputViewController.new_create_true = -1
            check_taskArray = taskArray[indexPath!.row]
            search_id_number = taskArray[indexPath!.row].id
            //print("\(search_id_number)")
        } else {
            let task = Task()
            task.date = Date()
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0 {
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            inputViewController.task = task
            inputViewController.new_create_true = 1
            search_id_number = -1
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        check_empty_db()
        taskArray_setup()
        tableView.reloadData()
    }
    
    @IBAction func filterTextField_dissmiss(_ sender: Any) {
        //print("filterTextField_dissmiss")
        view.endEditing(true)
        taskArray_setup()
    }
    
    @IBAction func title_category_func(_ sender: Any) {
        if (title_category.selectedSegmentIndex == 0){
            filterTextField.placeholder = "タイトル検索"
        }else{
            filterTextField.placeholder = "カテゴリー検索"
        }
        filterTextField.text = ""
        taskArray_setup()
        
    }
    
    func check_empty_db(){
        if (search_id_number == -1){
        }else if (check_taskArray.title == "" && check_taskArray.contents == ""){
            delete_filtered_db()
            search_id_number = -1
        }
    }
    
    func taskArray_setup(){
        if (filterTextField.text! == ""){
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
        }else if (title_category.selectedSegmentIndex == 0) {
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false).filter("title == '\(filterTextField.text!)'")
        }else{
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false).filter("category == '\(filterTextField.text!)'")
        }
        tableView.reloadData()
    }
    
    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count  // ←修正する
    }
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
    
        // Cellに値を設定する.  --- ここから ---
        let task = taskArray[indexPath.row]
        if (task.title == ""){
            cell.textLabel?.text = "タイトルなし"
        }else{
            cell.textLabel?.text = task.title
        }
        
        if (title_category.selectedSegmentIndex == 0){
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            let dateString:String = formatter.string(from: task.date)
            cell.detailTextLabel?.text = dateString
        }else if (task.category == ""){
            cell.detailTextLabel?.text = "カテゴリー:なし"
        }else{
            cell.detailTextLabel?.text = "カテゴリー:\(task.category)"
        }
        //print("id:\(task.id) indexPath:\(indexPath) indexPath.row:\(indexPath.row) taskArray.count:\(taskArray.count)")
        // --- ここまで追加 ---
        
        //内容を編集したCellのデータを返す
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド（セル設定でスライドしたらdelete領域が現れる設定）
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            delete_db(row_number : indexPath.row)
            try! realm.write {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        } // --- ここまで変更 ---
    }
    
    func delete_db(row_number : Int){
        //print("called delete_method")
        // ローカル通知をキャンセルする
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [String(self.taskArray[row_number].id)])
        
        // データベースから削除する
        try! realm.write {
            self.realm.delete(self.taskArray[row_number])
        }
        
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    }
    
    func delete_filtered_db(){
        //print("called delete_filtered_db_method")
        // ローカル通知をキャンセルする
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [String(self.check_taskArray.id)])
        
        // データベースから削除する
        try! realm.write {
            self.realm.delete(self.check_taskArray)
        }
        
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    }
    
}
