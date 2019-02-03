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

class CalendarViewController: UIViewController {
//    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    let testLabel = UILabel()
    
    let formatter = DateFormatter()
    
    // 경기 정보 담을 객체
    public static var matchList = [Matches]()
    
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCalendarView()
        
        Requests().getMatchInfo() { (isSuccess, matches)  in
            if isSuccess {
                // update UI
                DispatchQueue.main.async {
                    self.calendarView.reloadData()
                }
                
                print(CalendarViewController.matchList.count)
                print("개")
            } else {
                print("틀려먹음")
            }
            
        }
        
//        print("몇개")
//        print(CalendarViewController.matchList.count)
    }
    
    func setupCalendarView() {
        // Set up labels
        calendarView.visibleDates { (visibleDates) in
            self.setupViewsOfCalendar(from: visibleDates)
        }
        calendarView.minimumLineSpacing = 1
        calendarView.minimumInteritemSpacing = 0
        calendarView.cellSize = calendarView.frame.size.width / 7
        
    }
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first?.date
        
        self.formatter.dateFormat = "MMMM"
        self.monthLabel.text = self.formatter.string(from: date!)
        
        self.formatter.dateFormat = "yyyy"
        self.yearLabel.text = self.formatter.string(from: date!)
    }
}

extension CalendarViewController: JTAppleCalendarViewDataSource {

    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let startDate = formatter.date(from: "2019 01 01")! // You can use date generated from a formatter
        let endDate = formatter.date(from: "2030 12 30")!
        // You can also use dates created from this function
        let parameters = ConfigurationParameters(startDate: startDate,
                                                 endDate: endDate,
                                                 numberOfRows: 6, // Only 1, 2, 3, & 6 are allowed
            calendar: Calendar.current,
            generateInDates: .forAllMonths,
            generateOutDates: .tillEndOfGrid,
            firstDayOfWeek: .sunday)
        
        return parameters
    }
}

extension CalendarViewController: JTAppleCalendarViewDelegate {
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let dateCell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "cell", for: indexPath) as! CellView
        
        dateCell.dayLabel.text = cellState.text
        
        
        if cellState.dateBelongsTo == .thisMonth {
            dateCell.dayLabel.textColor = UIColor.black
        } else {
            dateCell.dayLabel.textColor = UIColor.gray
        }
        
        for i in CalendarViewController.matchList {
            // 이거 제대로 안됨.
            if Calendar.current.compare(i.mDate, to: date, toGranularity: .day) == .orderedSame {
                print("경기날이닷")
                print(date)

                let textLabel = UILabel()
                textLabel.backgroundColor = UIColor.brown
                textLabel.widthAnchor.constraint(equalToConstant: self.view.frame.width).isActive = true
                textLabel.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
                textLabel.text = "\(i.blue) : \(i.red)"
                textLabel.font = textLabel.font.withSize(10)

                textLabel.textAlignment = .center
                
                textLabel.clipsToBounds = true
                textLabel.layer.cornerRadius = 5
                dateCell.listStackView.addArrangedSubview(textLabel)

            }
        }
        return dateCell
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setupCalendarView()
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CellView else { return }
        
        validCell.selectedView.isHidden = false
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        guard let validCell = cell as? CellView else { return }
        
        validCell.selectedView.isHidden = true
    }
}
