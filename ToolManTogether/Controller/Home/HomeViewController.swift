//
//  HomeViewController.swift
//  ToolManTogether
//
//  Created by Spoke on 2018/9/20.
//  Copyright © 2018年 Spoke. All rights reserved.
//

import UIKit
import FirebaseDatabase
import MapKit
import CoreLocation
import FirebaseAuth
import FirebaseStorage
import SDWebImage

class HomeViewController: UIViewController {
    
    @IBOutlet weak var typeCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pullUpDetailView: TaskDetailInfoView!
    
    var myRef: DatabaseReference!
    var typeDic: [String: String] = [:]
    var typeTxtArray: [String] = []
    var typeColorArray: [String] = []
    var locationManager = CLLocationManager()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    var regionRadious: Double = 1000
    var allUserTask: [UserTaskInfo] = []
    let screenSize = UIScreen.main.bounds.size
    let loginVC = LoginViewController()
    var techAnnotationArray: [MKAnnotation] = []
    var bugAnnotationArray: [MKAnnotation] = []
    var carryAnnotationArray: [MKAnnotation] = []
    var houseAnnotationArray: [MKAnnotation] = []
    var foodAnnotationArray: [MKAnnotation] = []
    var otherAnnotationArray: [MKAnnotation] = []
    var trafficAnnotationArray: [MKAnnotation] = []
    var allAnnotationArray: [MKAnnotation] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()

        layout.scrollDirection = .horizontal        
        typeCollectionView.collectionViewLayout = layout
        typeCollectionView.showsHorizontalScrollIndicator = false
        
        typeCollectionView.delegate = self
        typeCollectionView.dataSource = self
        
        let cellNib = UINib(nibName: "TypeCollectionViewCell", bundle: nil)
        self.typeCollectionView.register(cellNib, forCellWithReuseIdentifier: "typeCell")
        
        myRef = Database.database().reference()
        
        collectionViewConstraint.constant = 0

        dataBaseTypeAdd()
        dataBaseTaskAdd()
        
        locationButton.layer.cornerRadius = locationButton.frame.width / 2
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        mapView.showsUserLocation = true
        mapView.tintColor = #colorLiteral(red: 0.3450980392, green: 0.768627451, blue: 0.6156862745, alpha: 1)

        configureLocationServices()
        
    }
    

    func dataBaseTypeAdd() {
        myRef.child("TaskType").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: String] else { return }
            let sortValue = value.sorted(by: { (firstDictionary, secondDictionary) -> Bool in
                return firstDictionary.0 > secondDictionary.0
            })
            for (keys, value) in sortValue {
                self.typeTxtArray.append(keys)
                self.typeColorArray.append(value)
            }
            if self.typeTxtArray.count == snapshot.key.count - 1 {
                self.typeCollectionView.reloadData()
                UIView.animate(withDuration: 0.3) {
                    self.collectionViewConstraint.constant = 40
                }
            }
        }
    }
    
    func dataBaseTaskAdd() {
        myRef.child("Task").observe(.childAdded) { (snapshot) in
            guard let value = snapshot.value as? NSDictionary else { return }
            guard let title = value["Title"] as? String else { return }
            guard let content = value["Content"] as? String else { return }
            guard let price = value["Price"] as? String else { return }
            guard let type = value["Type"] as? String else { return }
            guard let taskLat = value["lat"] as? Double else { return }
            guard let taskLon = value["lon"] as? Double else { return }
            guard let userID = value["UserID"] as? String else { return }
            guard let userName = value["UserName"] as? String else { return }

            let userTaskInfo = UserTaskInfo(userID: userID, userName: userName, title: title, content: content, type: type, price: price, taskLat: taskLat, taskLon: taskLon)
            
            self.allUserTask.append(userTaskInfo)
            
            self.mapTaskPoint(taskLat: taskLat, taskLon: taskLon, type: type)
            
        }
        updataTaskInfoDetail()
    }
    
    func updataTaskInfoDetail() {
        
        let storageRef = Storage.storage().reference()
        
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        storageRef.child("UserPhoto").child(userId).downloadURL(completion: { (url, error) in
            
            if let error = error {
                print("User photo download Fail: \(error.localizedDescription)")
            }
            
            if let url = url {
                print("url \(url)")
                self.pullUpDetailView.userPhoto.sd_setImage(with: url, completed: nil)
            }
        })
    }
    
    func mapTaskPoint(taskLat: Double, taskLon: Double, type: String) {
        let taskCoordinate = CLLocationCoordinate2D(latitude: taskLat, longitude: taskLon)
        
        let annotation = TaskPin(coordinate: taskCoordinate, identifier: "taskPin")
        
        annotation.title = type
        
        mapView.addAnnotation(annotation)
        
    }
    
    func filterPoint() {
        print(mapView.annotations)
    }
    
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        print(authorizationStatus)
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    func addTap(taskCoordinate: CLLocationCoordinate2D) {
        let mapTap = UITapGestureRecognizer(target: self, action: #selector(animateViewDown))
        mapView.addGestureRecognizer(mapTap)
        let coordinateRegion = MKCoordinateRegion(
            center: taskCoordinate,
            latitudinalMeters: regionRadious * 0.2,
            longitudinalMeters: regionRadious * 0.2)
        
        searchFireBase(child: "Task", byChild: "searchAnnotation", toValue: "\(taskCoordinate.latitude)_\(taskCoordinate.longitude)") { (data) in
            for value in data.allValues{
                
                guard let dictionary = value as? [String: Any] else { return }
                guard let title = dictionary["Title"] as? String else { return }
                guard let content = dictionary["Content"] as? String else { return }
                guard let price = dictionary["Price"] as? String else { return }
                guard let type = dictionary["Type"] as? String else { return }
                guard let userName = dictionary["UserName"] as? String else { return }
                
                self.pullUpDetailView.taskTitleLabel.text = title
                self.pullUpDetailView.taskContentTxtView.text = content
                self.pullUpDetailView.distanceLabel.text = "5.0m"
                self.pullUpDetailView.priceLabel.text = price
                self.pullUpDetailView.userName.text = userName
                self.pullUpDetailView.typeLabel.text = type
            }
        }
        
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func searchFireBase(
        child: String,
        byChild: String,
        toValue: String,
        success: @escaping (NSDictionary) -> Void) {
    
        myRef.child(child)
            .queryOrdered(byChild: byChild).queryEqual(toValue: toValue)
            .observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let data = snapshot.value as? NSDictionary else { return }
                success(data)
            }) { (error) in
                print(error.localizedDescription)
        }
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(animateViewDown))
        swipe.direction = .down
        pullUpDetailView.addGestureRecognizer(swipe)
    }

    func animateViewUp() {
        filterPoint()
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func animateViewDown() {
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return typeTxtArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "typeCell", for: indexPath) as? TypeCollectionViewCell {

            if typeTxtArray.count != 0 {
                cell.typeLabel.text = typeTxtArray[indexPath.row]
                cell.typeView.backgroundColor = typeColorArray[indexPath.row].color()
            }
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        mapView.removeAnnotations(allAnnotationArray)
        
        switch indexPath.row {
        // 科技維修
        case 0:
            mapView.addAnnotations(techAnnotationArray)
            
        // 清除害蟲
        case 1:
            mapView.addAnnotations(bugAnnotationArray)

        // 搬運重物
        case 2:
            mapView.addAnnotations(carryAnnotationArray)
        // 居家維修
        case 3:
            mapView.addAnnotations(houseAnnotationArray)

        // 外送食物
        case 4:
            mapView.addAnnotations(foodAnnotationArray)

        // 其他任務
        case 5:
            mapView.addAnnotations(otherAnnotationArray)

        // 交通接送
        case 6:
            mapView.addAnnotations(trafficAnnotationArray)
        default:
            return
        }

    }
}

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 103 , height: 40)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 5
    }
    
}

extension HomeViewController: MKMapViewDelegate {
    
    // To Change the maker view

    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "taskPin")
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "taskPin")
        }
        
        if annotation is MKUserLocation {
            return nil
        }
        
        allAnnotationArray.append(annotation)
        
        switch annotation.title {
        case "搬運重物":
            annotationView?.image = #imageLiteral(resourceName: "yellowPoint")
            carryAnnotationArray.append(annotation)
        case "科技維修":
            annotationView?.image = #imageLiteral(resourceName: "bluePoint")
            techAnnotationArray.append(annotation)
        case "清除害蟲":
            bugAnnotationArray.append(annotation)
            annotationView?.image = #imageLiteral(resourceName: "redPoint")
        case "外送食物":
            foodAnnotationArray.append(annotation)
            annotationView?.image = #imageLiteral(resourceName: "purplePoint")
        case "其他任務":
            otherAnnotationArray.append(annotation)
            annotationView?.image = #imageLiteral(resourceName: "brownPoint")
        case "居家維修":
            houseAnnotationArray.append(annotation)
            annotationView?.image = #imageLiteral(resourceName: "orangePoint")
        case "交通接送":
            trafficAnnotationArray.append(annotation)
            annotationView?.image = #imageLiteral(resourceName: "greenPoint")
        default:
            annotationView?.image = #imageLiteral(resourceName: "yellowPoint")
        }
        
        annotationView?.canShowCallout = true
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        guard let coordinate = view.annotation?.coordinate else {
            return
        }
        addTap(taskCoordinate: coordinate)
        
        animateViewUp()
        addSwipe()
    }
    
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else {
            return
        }
        let coordinateRegion = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: regionRadious * 0.3,
            longitudinalMeters: regionRadious * 0.3)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationManager.startUpdatingLocation()
        centerMapOnUserLocation()
    }

}

extension HomeViewController: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
}

extension String {
    func color() -> UIColor? {
        switch(self){
        case "green":
            return #colorLiteral(red: 0.4274509804, green: 0.8078431373, blue: 0.7568627451, alpha: 1)
        case "brown":
            return #colorLiteral(red: 0.7450980392, green: 0.6588235294, blue: 0.6274509804, alpha: 1)
        case "purple":
            return #colorLiteral(red: 0.7843137255, green: 0.6078431373, blue: 0.8, alpha: 1)
        case "orange":
            return #colorLiteral(red: 0.968627451, green: 0.537254902, blue: 0.2156862745, alpha: 1)
        case "yellow":
            return #colorLiteral(red: 0.9568627451, green: 0.7215686275, blue: 0, alpha: 1)
        case "red":
            return #colorLiteral(red: 0.9411764706, green: 0.4078431373, blue: 0.3019607843, alpha: 1)
        case "blue":
            return #colorLiteral(red: 0.5294117647, green: 0.6352941176, blue: 0.8509803922, alpha: 1)
        default:
            return nil
        }
    }
}


