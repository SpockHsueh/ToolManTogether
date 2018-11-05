![image](https://github.com/SpockHsueh/ToolManTogether/blob/master/ToolManTogether/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60%402x.png)
# Toolgather App

>### Main concept 
工聚人是款當遇到困擾的事情卻無能為力時，讓你可以透過發出任務來使用他人的生活技能，同時也分享自己的專長來回饋，就此形成一個工具人社群網路。

# The Key function
## 點擊地圖上的任務圖標，秀出任務細節 view 的動畫效果
>### MapKit Annotation add Tap gesture and annotation popup information detail when the user tapped.
![image](https://github.com/SpockHsueh/ToolManTogether/blob/master/IMG_01.PNG) ![image](https://github.com/SpockHsueh/ToolManTogether/blob/master/IMG_02.PNG)
>### Three steps:
>1. 我們可以透過 MapKit 本身提供的方法來拿到使用者點擊了哪個 Annotation，同時拿到該點的經緯度資料，進行後續動作。
```javascript
func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
  
        guard let coordinate = view.annotation?.coordinate else {
            return
        }
        
        animateViewUp()
        ...
        ...
    }
```

>2. 將手勢加到地圖上，讓使用者點擊其他地方可以將任務詳細頁面縮回。
```javascript
  func addTap(taskCoordinate: CLLocationCoordinate2D) {
        let mapTap = UITapGestureRecognizer(target: self, action: #selector(animateViewDown))
        mapView.addGestureRecognizer(mapTap)
  }
```
>3. 任務細節 view 的動畫效果，可以透過動態調整該 view 的高來達到彈出又隱藏的動畫效果。



## Remote Push Notification
>### 當使用者申請的任務狀態被拒絕或同意，或是任務聊天室新訊息，使用者會收到訊息，點擊通知後會直接進入該資訊的頁面。

>### 必須執行的三個前置任務:
>1. 必須正確配置應用程序並向 Apple 推送通知服務（APNS）註冊才能在每次啟動時接收推送通知。
>2. 服務器必須向指向一個或多個特定設備的APNS發送推送通知。
>3. 該應用程式必須收到推送通知後，它可以進一步使用應用程序中的function 來執行任務或處理操作。

>### 配置推送:
> 1. 在 Xcode 中啟用推播通知權利 （需要同時登錄 Apple 開發人員中心創建App ID，並添加通知選項），
![](https://i.imgur.com/HB3cud7.png)
![](https://i.imgur.com/L6vbhUf.png)

> 2. 在 Appdelegate.swift 添加以下代碼：

```javascript
func registerForPushNotifications() {
  UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
    (granted, error) in
    print("Permission granted: \(granted)")
  }
}
```
* .badge 允許在 icon 的角落顯示一個數字。
* .sound 允許該播放聲音。
* .alert 允許該顯示文字。


>### 註冊推送:

>1. 驗證使用者是否已授權註冊
```javascript
func getNotificationSettings() {
  UNUserNotificationCenter.current().getNotificationSettings { (settings) in
    print("Notification settings: \(settings)")
    guard settings.authorizationStatus == .authorized else { return }
    UIApplication.shared.registerForRemoteNotifications()
  }
}
```

接著




# Libraries
* Crashlytics
* Firebase SDK
* Facebook SDK
* IQKeyboardManagerSwift
* KeychainSwift
* Kingfisher
* Lottie
* SwiftLint

# Requirement
* iOS 11.4 +
* XCode 10.0


# Version
* 2.0 - 2018/10/31
  * 新增任務聊天室
  * 新增地圖縮放顯示任務圖標功能

* 1.0 - 2018/10/20
  * 第一版上架 

# Contacts
Spock Hsueh spock.hsu@gmail.com




 

