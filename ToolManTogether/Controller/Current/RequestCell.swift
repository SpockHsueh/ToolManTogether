//
//  RequestCell.swift
//  ToolManTogether
//
//  Created by Spoke on 2018/9/28.
//  Copyright © 2018年 Spoke. All rights reserved.
//

import UIKit
import AnimatedCollectionViewLayout
import FirebaseAuth
import FirebaseStorage
import SDWebImage
import FirebaseDatabase

protocol ScrollTask: AnyObject{
    func didScrollTask(_ cell: String)
}

protocol btnPressed: AnyObject {
    func btnPressed(_ send: TaskDetailInfoView)
}

class RequestCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var taskNumTitleLabel: UILabel!
    @IBOutlet weak var toosNumTitleLabel: UILabel!
    
    let layout = AnimatedCollectionViewLayout()
    let screenSize = UIScreen.main.bounds.size
    var myRef: DatabaseReference!
    var addTask: [UserTaskInfo] = []
    var addTaskKey: [String] = []
    private var indexOfCellBeforeDragging = 0
    weak var scrollTaskDelegate: ScrollTask?
    weak var scrollTaskBtnDelegate: btnPressed?
    var checkIndex = 0
    var scrollIndex: Int!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let cellNib = UINib(nibName: "RequestCollectionViewCell", bundle: nil)
        self.collectionView.register(cellNib, forCellWithReuseIdentifier: "requestCollectionView")
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.isPagingEnabled = true
        
        self.collectionView.showsHorizontalScrollIndicator = false
        layout.animator = PageAttributesAnimator()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        
        myRef = Database.database().reference()
        createTaskAdd()
        
        let addTaskNotification = Notification.Name("addTask")
        NotificationCenter.default.addObserver(self, selector: #selector(self.createTaskAdd), name: addTaskNotification, object: nil)
        
        let agreeToolNotification = Notification.Name("agreeToos")
        NotificationCenter.default.addObserver(self, selector: #selector(self.createTaskAdd), name: agreeToolNotification, object: nil)
        
    }
    
    @objc func createTaskAdd () {
        
        self.addTask.removeAll()
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        myRef.child("Task").queryOrdered(byChild: "UserID").queryEqual(toValue: userID).observeSingleEvent(of: .value) { (snapshot) in
            guard let data = snapshot.value as? NSDictionary else { return }
            
            for value in data {
                
                guard let keyValue = value.key as? String else { return }
                guard let dictionary = value.value as? [String: Any] else { return }
                guard let title = dictionary["Title"] as? String else { return }
                guard let content = dictionary["Content"] as? String else { return }
                guard let price = dictionary["Price"] as? String else { return }
                guard let type = dictionary["Type"] as? String else { return }
                guard let userName = dictionary["UserName"] as? String else { return }
                guard let userID = dictionary["UserID"] as? String else { return }
                guard let taskLat = dictionary["lat"] as? Double else { return }
                guard let taskLon = dictionary["lon"] as? Double else { return }
                guard let agree = dictionary["agree"] as? Bool else { return }
                let time = dictionary["Time"] as? Int

                let task = UserTaskInfo(userID: userID,
                                        userName: userName,
                                        title: title,
                                        content: content,
                                        type: type, price: price,
                                        taskLat: taskLat, taskLon: taskLon, checkTask: nil,
                                        distance: nil, time: time,
                                        ownerID: nil, ownAgree: nil,
                                        taskKey: keyValue, agree: agree)
                
                self.addTask.append(task)
                self.addTask.sort(by: { $0.time! > $1.time! })
                
//                self.createTaskChange(taskKey: keyValue)

            }
            self.collectionView.reloadData()
        }
    }
    
//    func createTaskChange(taskKey: String) {
//
//        guard let userID = Auth.auth().currentUser?.uid else { return }
//
//        myRef.child("Task").child(taskKey).observe(.childAdded) { (snapshot) in
//
//            self.myRef.child("Task").queryOrdered(byChild: "UserID").queryEqual(toValue: userID).observeSingleEvent(of: .value) { (snapshot) in
//                guard let data = snapshot.value as? NSDictionary else { return }
//
//                self.addTask.removeAll()
//                for value in data {
//
//                    guard let keyValue = value.key as? String else { return }
//                    guard let dictionary = value.value as? [String: Any] else { return }
//                    guard let title = dictionary["Title"] as? String else { return }
//                    guard let content = dictionary["Content"] as? String else { return }
//                    guard let price = dictionary["Price"] as? String else { return }
//                    guard let type = dictionary["Type"] as? String else { return }
//                    guard let userName = dictionary["UserName"] as? String else { return }
//                    guard let userID = dictionary["UserID"] as? String else { return }
//                    guard let taskLat = dictionary["lat"] as? Double else { return }
//                    guard let taskLon = dictionary["lon"] as? Double else { return }
//                    guard let agree = dictionary["agree"] as? Bool else { return }
//                    let time = dictionary["Time"] as? Int
//
//                    let task = UserTaskInfo(userID: userID,
//                                            userName: userName,
//                                            title: title,
//                                            content: content,
//                                            type: type, price: price,
//                                            taskLat: taskLat, taskLon: taskLon, checkTask: nil,
//                                            distance: nil, time: time,
//                                            ownerID: nil, ownAgree: nil,
//                                            taskKey: keyValue, agree: agree)
//                    self.addTask.append(task)
//                    self.addTask.sort(by: { $0.time! > $1.time! })
//
//                }
//                self.collectionView.reloadData()
//            }
//        }
//    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollIndex = Int(scrollView.contentOffset.x) / Int(scrollView.frame.width)
        if scrollIndex != checkIndex {
            let searchAnnotation = addTask[scrollIndex].taskKey
            scrollTaskDelegate?.didScrollTask(searchAnnotation!)
            checkIndex = scrollIndex
            self.taskNumTitleLabel.text = "第\(checkIndex + 1)/\(addTask.count)筆任務"

        } else {
        }
    }
    
    func downloadUserPhoto(
        userID: String,
        finder: String,
        success: @escaping (URL) -> Void) {
        
        let storageRef = Storage.storage().reference()
        
        storageRef.child(finder).child(userID).downloadURL(completion: { (url, error) in
            
            if let error = error {
                print("User photo download Fail: \(error.localizedDescription)")
            }
            if let url = url {
                print("url \(url)")
                success(url)
            }
        })
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return addTask.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "requestCollectionView", for: indexPath) as? RequestCollectionViewCell {
            let cellData = addTask[indexPath.row]
            cell.taskBtnDelegate = self
            cell.requestCollectionView.taskTitleLabel.text = cellData.title
            cell.requestCollectionView.taskContentTxtView.text = cellData.content
            cell.requestCollectionView.priceLabel.text = cellData.price
            cell.requestCollectionView.typeLabel.text = cellData.type
            cell.requestCollectionView.userName.text = cellData.userName
            
            if cellData.agree == false {
                cell.requestCollectionView.sendButton.setTitle("取消任務", for: .normal)
            } else if cellData.agree == true {
                cell.requestCollectionView.sendButton.setTitle("存到個人歷史紀錄", for: .normal)
                cell.requestCollectionView.sendButton.backgroundColor = #colorLiteral(red: 0.5294117647, green: 0.6352941176, blue: 0.8509803922, alpha: 1)
            } else {
                cell.requestCollectionView.sendButton.setTitle("取消任務", for: .normal)
            }
           
            downloadUserPhoto(userID: cellData.userID, finder: "UserPhoto") { (url) in
                if url == url {
                    cell.requestCollectionView.userPhoto.sd_setImage(with: url, completed: nil)
                } else {
                    cell.requestCollectionView.userPhoto.image = UIImage(named: "profile_sticker_placeholder02")
                }
            }

            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 298)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

extension RequestCell: ScrollTaskBtn{
    
    func didPressed(_ scrollView: TaskDetailInfoView) {
        scrollTaskBtnDelegate?.btnPressed(scrollView)
    }
}
