//
//  InputViewController.swift
//  taskapp
//
//  Created by 濱田龍輝 on 2019/09/05.
//  Copyright © 2019 Ryuuki.hamada. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class InputViewController: UIViewController {

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var categoryTextField: UITextField!
    @IBOutlet weak var contentsTextView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    var task: Task!
    var new_create_true = -1
    var backUp_category = "error"
    var backUp_title = "error"
    var backUp_contents = "error"
    var backUp_date = Date()
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //titleTextField.placeholder = "タイトルを入力"
        //contentsTextView.placeholder
        // 背景をタップしたらdismissKeyboardメソッドを呼ぶように設定する
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target:self, action:#selector(dismissKeyboard))
        self.view.addGestureRecognizer(tapGesture)
        
        categoryTextField.text = task.category
        titleTextField.text = task.title
        contentsTextView.text = task.contents
        datePicker.date = task.date
        backUp_task()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        try! realm.write {
            if (new_create_true != 1 || self.contentsTextView.text != "" || self.titleTextField.text! != ""){
                self.task.category = self.categoryTextField.text!
                self.task.title = self.titleTextField.text!
                self.task.contents = self.contentsTextView.text
                self.task.date = self.datePicker.date
                self.realm.add(self.task, update: true)
                setNotification(task: task)
            }
        }
        new_create_true = -1
        super.viewWillDisappear(animated)
    }
    
    @IBAction func button_cancel(_ sender: Any) {
        allpy_backUp()
        self.navigationController?.popViewController(animated: true)
        //self.dismiss(animated:true)
    }

    @IBAction func button_reset(_ sender: Any) {
        allpy_backUp()
    }
    
    @objc func dismissKeyboard(){
        // キーボードを閉じる
        view.endEditing(true)
    }
    
    func backUp_task(){
        backUp_category = task.category
        backUp_title = task.title
        backUp_contents = task.contents
        backUp_date = task.date
        //print("\(task.date)")
    }
    
    func allpy_backUp(){
        categoryTextField.text = backUp_category
        titleTextField.text = backUp_title
        contentsTextView.text = backUp_contents
        datePicker.date = backUp_date
    }
    // タスクのローカル通知を登録する --- ここから ---
    func setNotification(task: Task) {
        let content = UNMutableNotificationContent()
        // タイトルと内容を設定(中身がない場合メッセージ無しで音だけの通知になるので「(xxなし)」を表示する)
        if task.title == "" {
            content.title = "(タイトルなし)"
        } else {
            content.title = task.title
        }
        if task.contents == "" {
            content.body = "(内容なし)"
        } else {
            content.body = task.contents
        }
        
        
        
        content.sound = UNNotificationSound.default
        
        // ローカル通知が発動するtrigger（日付マッチ）を作成
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: task.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // identifier, content, triggerからローカル通知を作成（identifierが同じだとローカル通知を上書き保存）
        let request = UNNotificationRequest(identifier: String(task.id), content: content, trigger: trigger)
        
        // ローカル通知を登録
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            print(error ?? "ローカル通知登録 OK")  // error が nil ならローカル通知の登録に成功したと表示します。errorが存在すればerrorを表示します。
        }
        
        // 未通知のローカル通知一覧をログ出力
        center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
            for request in requests {
                print("/---------------")
                print(request)
                print("---------------/")
            }
        }
    } // --- ここまで追加 ---
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
