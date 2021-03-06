//
//  ActivityDetailViewController.swift
//  ActiDiabet
//
//  Created by 佟诗博 on 18/4/20.
//  Copyright © 2020 Shibo Tong. All rights reserved.
//

import UIKit
import YoutubePlayer_in_WKWebView

class ActivityDetailViewController: UIViewController {
    ///This is the activity detail view page
    
    var activity: Activity?
    var likeButton: UIButton!
    var coredataController: CoredataProtocol?
    private var notificationCenter: Notifications?
    
    // Views
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var timeView: UIView!
    @IBOutlet weak var indoorView: UIView!
    @IBOutlet weak var typeView: UIView!
    @IBOutlet weak var addView: UIView!
    @IBOutlet weak var completeView: UIView!
    
    @IBOutlet weak var playerView: WKYTPlayerView!
    
    // Labels
    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var timeTextField: UITextField!
    @IBOutlet weak var indoorLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
    // Buttons
    @IBOutlet weak var locationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as? AppDelegate
        self.coredataController = delegate?.coredataController
        self.notificationCenter = delegate?.notification
        guard let ac = activity else { return }
        self.setupView(id: ac.video)
        setRound()
        setInputView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        playerView.stopVideo()
    }

    // MARK: Setup View functions
    // setup labels
    func setupView(id: String) {
        self.activityLabel.text = activity?.activityName
        timeTextField.text = "\(activity?.duration ?? 0)"
        typeLabel.text = activity?.activityType.toString()
        if let activity = self.activity {
            if activity.indoor {
                indoorLabel.text = "Indoor"
                locationButton.isHidden = true
            } else {
                indoorLabel.text = "Outdoor"
                locationButton.isHidden = false
            }
            
            
        }
        initLikeButton()
        playerView.load(withVideoId: id)
    }
    
    func initLikeButton() {
        likeButton = UIButton(type: .custom)
        setlikeButton()
        likeButton.addTarget(self, action: #selector(changeLike(_:)), for: .touchUpInside)
        let buttonItem = UIBarButtonItem(customView: likeButton)
        self.navigationItem.rightBarButtonItem = buttonItem
    }
    
    // set favourite button
    func setlikeButton() {
        if let activity = self.activity {
            if activity.like {
                likeButton.setImage(UIImage(systemName: "heart.fill"), for: .normal)
                likeButton.tintColor = .systemPink
            } else {
                likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
                likeButton.tintColor = .systemGray2
            }
        }
    }
     
    // setup inputviews for textfields
    func setInputView() {
        let timePicker = UIPickerView()
        timePicker.delegate = self
        timeTextField.inputView = timePicker
    }

    // set round corner of views
    func setRound() {
        addView.makeRound()
        completeView.makeRound()
        titleView.makeRound()
        timeView.makeRound()
        indoorView.makeRound()
        typeView.makeRound()
    }
    
    // MARK: Button functions
    // Back button function
    @IBAction func backButtonFunction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    // Complete activity function
    @IBAction func completeActivity(_ sender: Any) {
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let database = delegate.databaseController as DatabaseProtocol
        let userid = UserDefaults.standard.object(forKey: "userid") as! String
        
        guard let duration = Int(timeTextField.text!) else { return }
        guard let activity = activity else { return }
        // save activity to coredata
        coredataController?.finishActivity(activity: activity, duration: duration)
        // show alert
        let alert = UIAlertController(title: "Did you like this activity?", message: "", preferredStyle: .alert)
        // like action
        let likeAction = UIAlertAction(title: "Yes I did!", style: .default) { (alertaction) in
            database.addReview(userid: userid, activity: self.activity!, rate: 1)
            self.navigationController?.popViewController(animated: true)
        }
        // dislike action
        let dontlikeAction = UIAlertAction(title: "Not sure", style: .default) { (alertaction) in
            database.addReview(userid: userid, activity: self.activity!, rate: -1)
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(likeAction)
        alert.addAction(dontlikeAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // add to plan function
    @IBAction func addToPlan(_ sender: Any) {
        // show alert
        let alert = UIAlertController(title: "Please select a time for reminder", message: "", preferredStyle: .alert)
        // add textfield to alert
        alert.addTextField { (textfield) in
            self.alertTextField = textfield
            // set datepicker as input view of textfield
            let datePicker = UIDatePicker()
            datePicker.locale = Locale(identifier: "en_GB")
            datePicker.datePickerMode = .dateAndTime
            datePicker.addTarget(self, action: #selector(self.dateChanged(datePicker:)), for: .valueChanged)
            textfield.inputView = datePicker
        }
        // cancel action
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        // save action (save to coredata)
        let save = UIAlertAction(title: "Save", style: .default) { (action) in
            guard let duration = Int(self.timeTextField.text!) else { return }
            guard let date = self.dateForSelection else { return }
            guard let activity = self.activity else { return }
            self.notificationCenter?.createNotification(with: date)
            self.coredataController?.addActivity(activity: activity, duration: duration, date: date)
            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(save)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    // change like button of activity
    @objc func changeLike(_ sender: Any) {
        self.activity?.changeFavourite()
        self.setlikeButton()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        timeTextField.resignFirstResponder()
    }
    
    // MARK: Add plan variables and functions
    // variables for performing add plan
    private var alertTextField: UITextField?
    private var dateForSelection: Date?

    // when date change, show on textfield
    @objc func dateChanged(datePicker: UIDatePicker) {
        dateForSelection = datePicker.date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        alertTextField?.text = dateFormatter.string(from: datePicker.date)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if self.activity?.activityID == 4 {
            let destination = segue.destination as! MapViewController
            destination.filter.insert(.cycling)
        }
        if self.activity?.activityID == 5 || self.activity?.activityID == 6 {
            let destination = segue.destination as! MapViewController
            destination.filter.insert(.pool)
        }
    }
}

// MARK: - PickerViewDelegate, PickerViewDataSource
extension ActivityDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 60
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        timeTextField.text = "\(row + 1)"
    }
}

