//
//  CalendarViewController.swift
//  LCKforYou
//
//  Created by Seungyeon Lee on 25/11/2018.
//  Copyright © 2018 Seungyeon Lee. All rights reserved.
//

import Foundation
import JTAppleCalendar
import Realm
import RealmSwift
import Alamofire
import UserNotifications

class CalendarViewController: UIViewController {
    
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet weak var monthLabel: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var topConstraints: NSLayoutConstraint!
    
    let formatter = DateFormatter()
    
    // 경기 정보 담을 객체
    public var matchList = [Matches]()
    
    // 테이블뷰 정보 didset?
    public var detailList = [Matches]()
    
    // 경기 일정 알림 할 때 사용할 플래그
    private var matchListFlag: Int?
    
    // 설정되어 있는 알림 확인
    var notifications: [String] = []
    
    // 움직이는 테이블 셀 만들자
    // MARK: Helpers
    // 달력에 보이는 날짜 중에 지금 보이는 달에 해당하지 않는 날짜의 개수가 7 이하인가요? 이하면 구냥 보여주고 넘으면 더 줄여버림.
    var numOfRowIsSix: Bool {
        get {
            return calendarView.visibleDates().outdates.count < 7
        }
    }
    
    // 스크롤시에 그 달의 1번째로
    var iii: Date?
    
    let numOfRowsInCalendar = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 알림 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 설정된 알림 리스트
        checkNotifications()
        
        // 테이블 뷰 설정
        let nibName = UINib(nibName: "DetailTableViewCell", bundle: nil)
        tableView.register(nibName, forCellReuseIdentifier: "detailCell")
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 55
        
        // 현재 날짜로 스크롤
        calendarView.scrollToDate(Date(), triggerScrollToDateDelegate: false, animateScroll: false, preferredScrollPosition: nil, extraAddedOffset: 0, completionHandler: nil)
        
        setupCalendarView()
//        self.adjustCalendarViewHeight()
        if self.matchList.count == 0 {
            spinner.startAnimating()
            requestMatches()
            
        }
        
        
    }
    
    func setupCalendarView() {
        // Set up labels
        calendarView.visibleDates { (visibleDates) in
            self.setupViewsOfCalendar(from: visibleDates)
        }
        // 오늘 날짜 선택하고 테이블뷰에도 보여주기
        self.calendarView.selectDates([Date()])
        
        // 달력 높이 설정
        self.adjustCalendarViewHeight()
        calendarView.minimumLineSpacing = 1
        calendarView.minimumInteritemSpacing = 0
        calendarView.cellSize = calendarView.frame.size.width / 7
        
    }
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first?.date
        
        self.formatter.dateFormat = "MMMM"
        self.monthLabel.text = self.formatter.string(from: date!)
    }
    
    func configureCell(cell: JTAppleCell?, cellState: CellState) {
        guard let myCell = cell as? CellView else { return }
        
        handleCellTextColor(cell: myCell, cellState: cellState)
        handleCellVisiblity(cell: myCell, cellState: cellState)
        handleCellSelection(cell: myCell, cellState: cellState)
        
    }
    
    func handleCellTextColor(cell: CellView, cellState: CellState) {
        let todaysDate = Date()

        formatter.dateFormat = "yyyy MM dd"

        let todaysDateString = formatter.string(from: todaysDate)
        let monthsDateString = formatter.string(from: cellState.date)
        
        // 오늘 날짜에 색깔 넣기
        if todaysDateString == monthsDateString {
            cell.dayLabel.textColor = UIColor.red
        } else {
            cell.dayLabel.textColor = UIColor.black
        }
    }
    
    func handleCellVisiblity(cell: CellView, cellState: CellState) {
        // 이번달 날짜가 아니면 안보이게 한다.
        let cellHidden = cellState.dateBelongsTo != .thisMonth
        cell.isHidden = cellHidden
    }
    
    func handleCellSelection(cell: CellView, cellState: CellState) {
        cell.selectedView.isHidden = cellState.isSelected ? false : true
    }
    
    func requestMatches() {
        Requests().getMatchInfo() { (matches)  in
            guard let matches = matches else {
                let alert = UIAlertController(title: "네트워크 오류", message: "네트워크 연결상태를 확인해주세요.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alert, animated: true)
                return
            }
            self.matchList = matches
            // 시간 정렬
            self.matchList.sort { $0.mDate < $1.mDate }
            
            // 오늘 날짜에 데이터 넣어주기
            self.addDetailData(selectedDate: Date())
            
            // update UI
            DispatchQueue.main.async {
                self.calendarView.reloadData()
                self.tableView.reloadData()
            }
            self.spinner.stopAnimating()
        }
    }
    
    func checkNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            for request in requests {
                self.notifications.append(request.identifier)
            }
        }
    }
}

extension CalendarViewController: JTAppleCalendarViewDataSource {

    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Locale(identifier: "en_US")
        
        let startDate = formatter.date(from: "2019 01 01")! // You can use date generated from a formatter
        let endDate = formatter.date(from: "2020 12 30")!
        // You can also use dates created from this function
        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate,
                                                 numberOfRows: 6, // Only 1, 2, 3, & 6 are allowed
            calendar: Calendar.current,
            generateInDates: .forAllMonths,
            generateOutDates: .tillEndOfGrid,
            firstDayOfWeek: .monday)
        
        return parameters
    }
    
}

extension CalendarViewController: JTAppleCalendarViewDelegate {
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        configureCell(cell: cell, cellState: cellState)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let dateCell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "cell", for: indexPath) as! CellView
        configureCell(cell: dateCell, cellState: cellState)
        
        // 스택 뷰 라벨 간격
        dateCell.listStackView.spacing = 0.5
        
        dateCell.dayLabel.text = cellState.text
        
        for (_, element) in self.matchList.enumerated() {
            // 몽고디비 때문에 9시간 더해준다.
            let eDate = element.mDate.addingTimeInterval(60.0 * 60 * 9)
            if Calendar.current.isDate(eDate, inSameDayAs: date) == true {
                let textLabel = UILabel()
                textLabel.adjustsFontSizeToFitWidth = true
                textLabel.backgroundColor = UIColor.lightGray
                textLabel.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
                textLabel.text = "\(element.blue) : \(element.red)"
                textLabel.font = textLabel.font.withSize(9)
                textLabel.textColor = UIColor.black
                textLabel.textAlignment = .center
                textLabel.clipsToBounds = true
                textLabel.layer.cornerRadius = 3
                dateCell.listStackView.addArrangedSubview(textLabel)
            }
        }
        return dateCell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setupCalendarView()
        
        // 스크롤 하면 다음달 1일을 선택한 셀로 만들기
        if let firstDate = visibleDates.monthDates.first?.date {
            self.calendarView.selectDates([firstDate])
        }
        
        view.layoutIfNeeded()
        adjustCalendarViewHeight()
        UIView.animate(withDuration: 0.5) { [unowned self] in
            self.view.layoutIfNeeded()
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CellView else { return }
        
        validCell.selectedView.isHidden = false
        self.tableView.isHidden = false
        
        let selectedDate = cellState.date
        
        // 새로 넣기 전에 기존 데이터 모두 지우기
        self.detailList.removeAll()
        
        addDetailData(selectedDate: selectedDate)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CellView else { return }
        
        validCell.selectedView.isHidden = true
        self.tableView.isHidden = true
        
    }
    
    func setBtnImage(_ timeInfo: Date, _ cell: DetailTableViewCell) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            for request in requests {
                self.formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
                let date = self.formatter.string(from: timeInfo)
                if request.identifier == date {
                    DispatchQueue.main.async {
                        cell.alarmButton.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
                    }
                } else {
                    DispatchQueue.main.async {
                        cell.alarmButton.setImage(UIImage(named: "alarm_nonactivate"), for: UIControlState.normal)
                    }
                }
            }
        }
    }
}

extension CalendarViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.adjustCalendarViewHeight()
        if self.detailList.count == 0 {
            let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            let messageLabel = UILabel(frame: rect)
            messageLabel.text = "이 날은 열리는 경기가 없어요 🏆"
            messageLabel.textColor = UIColor.black
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = .center;
            messageLabel.font = UIFont(name: "TrebuchetMS", size: 15)
            messageLabel.sizeToFit()
            
            tableView.backgroundView = messageLabel;
            tableView.separatorStyle = .none;
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
        return self.detailList.count
    }
    
    // 알람 버튼 클릭시
    @objc func alarmTapped(sender: UIButton) {
        // sender.tag는 인덱스로 사용하면 됨.
        showInputDialog(sender.tag, sender, "match")
    }
    
    func showInputDialog(_ tag: Int, _ sender: UIButton, _ usage: String) {
        //Creating UIAlertController and
        //Setting title and message for the alert dialog
        let alertController = UIAlertController()
        
        //the confirm action taking the inputs
        let oclockAction = UIAlertAction(title: "정시", style: .default) { (_) in
            let time = self.transformTime("정시")
            self.setAlarm(time, tag, usage)
            
            if let selectedIndexPath = self.tableView.indexPathForSelectedRow, let selected = self.tableView.cellForRow(at: selectedIndexPath) as? DetailTableViewCell {
                DispatchQueue.main.async {
                    print("정시 변경함ㅎㅎ")
                    selected.alarmButton.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        }
        let fiveAction = UIAlertAction(title: "5분 전", style: .default) { (_) in
            let time = self.transformTime("5분")
            self.setAlarm(time, tag, usage)
            DispatchQueue.main.async {
                sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
            }
//            sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
//            sender.isHighlighted = true
        }
        let tenAction = UIAlertAction(title: "10분 전", style: .default) { (_) in
            let time = self.transformTime("10분")
            self.setAlarm(time, tag, usage)
            DispatchQueue.main.async {
                sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
            }
//            sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
//            sender.isHighlighted = true
            
        }
        let twentyAction = UIAlertAction(title: "20분 전", style: .default) { (_) in
            let time = self.transformTime("20분")
            self.setAlarm(time, tag, usage)
            DispatchQueue.main.async {
                sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
            }
//            sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
        }
        let thirtyAction = UIAlertAction(title: "30분 전", style: .default) { (_) in
            let time = self.transformTime("30분")
            self.setAlarm(time, tag, usage)
            DispatchQueue.main.async {
                sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
            }
//            sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
        }
        let oneHourAction = UIAlertAction(title: "1시간 전", style: .default) { (_) in
            let time = self.transformTime("1시간")
            self.setAlarm(time, tag, usage)
            DispatchQueue.main.async {
                sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
            }
//            sender.setImage(UIImage(named: "alarm_activate"), for: UIControlState.normal)
        }
        // 알람이 설정되어 있는 경우 삭제하기
        let deleteAlarmAction = UIAlertAction(title: "삭제", style: .destructive) { (_) in
            let center = UNUserNotificationCenter.current()
            let info = self.matchList[tag].mDate

            let changeLocal = info.addingTimeInterval(60.0 * 60.0 * 9)
            self.formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
            let id = self.formatter.string(from: changeLocal)
            center.removePendingNotificationRequests(withIdentifiers: ["\(id)"])
            DispatchQueue.main.async {
                sender.setImage(UIImage(named: "alarm_nonactivate"), for: UIControlState.normal)
            }
//            sender.setImage(UIImage(named: "alarm_nonactivate"), for: UIControlState.normal)
        }
        
        //the cancel action doing nothing
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        // 알람 설정 여부에 따라 actionsheet을 다르게 보여줌.
        let selectedCellDate = self.matchList[tag].mDate
        let changeLocal = selectedCellDate.addingTimeInterval(60.0 * 60.0 * 9)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
        let hour = formatter.string(from: changeLocal)

        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            var nextTriggerDates: [String] = []
            for request in requests {
                nextTriggerDates.append(request.identifier)
            }
            if nextTriggerDates.contains(hour) {
                alertController.title = "알림 삭제"
                alertController.message = "알림을 삭제하시겠습니까?"
                
                alertController.addAction(deleteAlarmAction)
            } else {
                alertController.title = "알림 설정"
                alertController.message = "언제 푸시알림을 드릴까요?"
                
                alertController.addAction(oclockAction)
                alertController.addAction(fiveAction)
                alertController.addAction(tenAction)
//                alertController.addAction(fifteenAction)
                alertController.addAction(twentyAction)
                alertController.addAction(thirtyAction)
                alertController.addAction(oneHourAction)
            }
        }
        alertController.addAction(cancelAction)
        
        //finally presenting the dialog box
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func transformTime(_ choice: String) -> Double {
        var result: Double = 0.0
        switch choice {
        case "5분":
            result += -1 * 60.0 * 5
        case "10분":
            result += -1 * 60.0 * 10
        case "15분":
            result += -1 * 60.0 * 15
        case "20분":
            result += -1 * 60.0 * 20
        case "30분":
            result += -1 * 60.0 * 30
        case "1시간":
            result += -1 * 60.0 * 60
        default:
            result += 0.0
        }
        return result
    }
    
    func setAlarm(_ time: Double, _ tag: Int, _ usage: String) {
        let data = self.matchList[tag]
        
        formatter.dateFormat = "a h:mm"
        
        // 몽고디비 시간대 변경
        let changeLocal = data.mDate.addingTimeInterval(60.0 * 60.0 * 9)
        let hour = formatter.string(from: changeLocal)
        
        //Setting content of the notification
        let content = UNMutableNotificationContent()
        content.title = "\(data.blue) vs \(data.red)"
        content.body = "오늘 \(hour)에 \(data.blue) vs \(data.red)의 경기가 있습니다."
        
        // 사용자가 설정한 시간으로 변경
        let settingTime = changeLocal.addingTimeInterval(time)
        
        // ----------------------------------------------------
        // 시간 확인
        print(changeLocal)
        print(settingTime)
        let interval = settingTime.timeIntervalSince(Date())
        print("\(interval)만큼 차이납니다.")
        
        // 실전
        let date = Date(timeIntervalSinceNow: interval)
        let dateCompenents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let calendartrigger = UNCalendarNotificationTrigger(dateMatching: dateCompenents, repeats: false)

        // 테스트용
//        let calendartrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(1), repeats: false)
        
        //Adding Request
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
        let idDate = formatter.string(from: changeLocal)
        print("날 짜 \(idDate)")
        let request = UNNotificationRequest(identifier: "\(idDate)", content: content, trigger: calendartrigger)
        
        
//        // 지금 설정되어있는 알람들 알아보기ㅎㅎ
//        DispatchQueue.main.async {
//            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
//                print("총 개수는 \(requests.count)")
//                for request in requests {
//                    print("id \(request.identifier)")
//                    print("시간 \(String(describing: request.trigger))")
//
//                }
//            }
//        }
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailCell", for: indexPath) as! DetailTableViewCell
        
        let data = self.detailList[indexPath.row]
        cell.blueLogoImageView.image = UIImage(named: "\(data.blue)")
        cell.redLogoImageView.image = UIImage(named: "\(data.red)")
        
        cell.blueLabel.text = data.blue
        cell.redLabel.text = data.red
        
        // 몽고디비의 타임존이 UTC로 고정되어 있기 때문에 9시간을 더해줌.
        let timeInfo = data.mDate.addingTimeInterval(60.0 * 60.0 * 9.0)
        
        formatter.dateFormat = "ha" // am pm
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = Calendar.current.timeZone

        let startTime: String = formatter.string(from: timeInfo)
        cell.timeLabel.text = startTime
        
        // 경기 날짜가 현재 시간보다 이전이면 버튼 안보이게 테스트 중이라 잠시 주석 처리
//        guard self.matchList[self.matchListFlag ?? 0 + indexPath.row].mDate >= Date() else {
//            cell.alarmButton.isHidden = true
//            return cell
//        }
        
        setBtnImage(timeInfo, cell)
        cell.alarmButton.tag = self.matchListFlag! + indexPath.row
        cell.alarmButton.addTarget(self, action: #selector(alarmTapped), for: .touchUpInside)
        
        return cell
    }
    
    // 시간 계산
    func calculateTimeInterval(startDate: Date, endDate: Date) -> TimeInterval {
        let interval = endDate.timeIntervalSince(startDate)
        return interval
    }
}

extension CalendarViewController {
    func adjustCalendarViewHeight() {
        adjustCalendarViewHeight(higher: self.numOfRowIsSix)
    }
    
    func adjustCalendarViewHeight(higher: Bool) {
        topConstraints.constant =
            higher ?
                0 :
            -calendarView.frame.height / CGFloat(numOfRowsInCalendar)
    }
}

extension CalendarViewController {
    func addDetailData(selectedDate: Date) {
        // 셀에 해당하는 데이터 넣기
        var checker = 0
        var stopper = 0
        
        for i in self.matchList {
            checker += 1
            if Calendar.current.isDate(i.mDate, inSameDayAs: selectedDate) == true {
                self.detailList.append(i)
                if stopper == 0 {
                    stopper += 1
                    self.matchListFlag = checker - 1
                }
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension CalendarViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let data = self.detailList[indexPath.row]

        let storyboard: UIStoryboard = UIStoryboard(name: "DetailView", bundle: nil)
        let nextView = storyboard.instantiateInitialViewController()
        let vc = nextView as? DetailViewController
        vc?.info = data
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}

extension CalendarViewController: UNUserNotificationCenterDelegate {
    // foreground에 있을 때에도 알림이 오게 함
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    // 처음에 알림 권한 허락 받을 때
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        let settingsViewController = UIViewController()
        settingsViewController.view.backgroundColor = .gray
        self.present(settingsViewController, animated: true, completion: nil)
        
    }
    
}

