//
//  TaskAgreeViewController.swift
//  ToolManTogether
//
//  Created by Spoke on 2018/9/30.
//  Copyright © 2018年 Spoke. All rights reserved.
//

import UIKit

class TaskAgreeViewController: UIViewController {
    
    @IBOutlet weak var taskAgreeTableView: UITableView!
    @IBOutlet weak var popUpScoreView: UIView!
    @IBOutlet weak var popUpScoreHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "任務進行中"

        taskAgreeTableView.delegate = self
        taskAgreeTableView.dataSource = self
        
        let taskAgreenib = UINib(nibName: "ProfileCell", bundle: nil)
        self.taskAgreeTableView.register(taskAgreenib, forCellReuseIdentifier: "profileTitle")
        
        let taskInfoNib = UINib(nibName: "TaskAgreeInfoCell", bundle: nil)
        self.taskAgreeTableView.register(taskInfoNib, forCellReuseIdentifier: "taskInfoCell")
        
        let taskMapNib = UINib(nibName: "TaskAgreeMapCell", bundle: nil)
        self.taskAgreeTableView.register(taskMapNib, forCellReuseIdentifier: "taskAgreeMapCell")
        
        let servcedNib = UINib(nibName: "ProfileServcedListCell", bundle: nil)
        self.taskAgreeTableView.register(servcedNib, forCellReuseIdentifier: "servcedList")
        
        
    }

}

extension TaskAgreeViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "profileTitle", for: indexPath) as? ProfileCell {
                return cell
            }
        } else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "taskInfoCell", for: indexPath) as? TaskAgreeInfoCell {
                return cell
            }
        } else if indexPath.section == 2 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "servcedList", for: indexPath) as? ProfileServcedListCell {
                return cell
            }
        } else if indexPath.section == 3 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "taskAgreeMapCell", for: indexPath) as? TaskAgreeMapCell {
                cell.sendScoreBtnTest.addTarget(self, action: #selector(testScoreSend), for: .touchUpInside)
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    @objc func testScoreSend() {
        animateViewUp()
    }

    func animateViewUp() {
        popUpScoreHeight.constant = 280
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func animateViewDown() {
        popUpScoreHeight.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

}