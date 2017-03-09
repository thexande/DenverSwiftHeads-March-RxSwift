//
//  ViewController.swift
//  rxMeetup
//
//  Created by Alex Murphy on 3/7/17.
//  Copyright © 2017 Alex Murphy. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

struct ValidUser {
    let email: String
    let phone: String
    let password: String
}
struct Validators {
    static let email = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
    static let phone = NSPredicate(format: "SELF MATCHES %@", "^[0-9]+$")
    static let password = NSPredicate(format: "SELF MATCHES %@", "^.{4,8}$")
}

class InputCell: UITableViewCell {
    let title: String
    let validator: NSPredicate
    let disposeBag = DisposeBag()
    lazy var textField: UITextField = {
        let field = UITextField()
        field.backgroundColor = UIColor.white
        field.textColor = UIColor.black
        field.layer.borderColor = UIColor.white.cgColor
        field.layer.cornerRadius = 5
        field.layer.borderWidth = 2
        field.placeholder = self.title
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    lazy var textFieldConstraints: [NSLayoutConstraint] = [
        NSLayoutConstraint(item: self.textField, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1, constant: 15),
        NSLayoutConstraint(item: self.textField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50),
        NSLayoutConstraint(item: self.textField, attribute: .left, relatedBy: .equal, toItem: self.contentView, attribute: .left, multiplier: 1, constant: 50),
        NSLayoutConstraint(item: self.textField, attribute: .right, relatedBy: .equal, toItem: self.contentView, attribute: .right, multiplier: 1, constant: -50)
    ]
    
    lazy var validationObservable: Observable<Bool> = self.textField
        .rx
        .text
        .debounce(0.3, scheduler: MainScheduler.instance)
        .map{ text -> Bool in
            guard let text = text else { return false }
            let hasValidated = self.validator.evaluate(with: text)
            self.textField.layer.borderColor = hasValidated ? UIColor.green.cgColor : UIColor.red.cgColor
            return hasValidated
    }
    
    lazy var contentObservable: Observable<[String:String]> = self.textField
        .rx
        .text
        .orEmpty
        .debounce(0.3, scheduler: MainScheduler.instance)
        .flatMap{ text -> Observable<[String:String]> in
            return text.isEmpty ? .just([String: String]()) : .just([self.title: text])
    }
    
    init(title: String, validator: NSPredicate) {
        self.title = title
        self.validator = validator
        super.init(style: .default, reuseIdentifier: nil)
        self.contentView.addSubview(self.textField)
        NSLayoutConstraint.activate(textFieldConstraints)
        self.contentView.backgroundColor = UIColor.black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UIViewController {
    let disposeBag = DisposeBag()
    var formHasValidated: Bool = false
    let cells: [UITableViewCell] = [
        InputCell(title: "Email", validator: Validators.email),
        InputCell(title: "Phone Number", validator: Validators.phone),
        InputCell(title: "Password",  validator: Validators.password)
    ]
    lazy var table: UITableView = {
        let table = UITableView()
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    lazy var tableViewConstraints: [NSLayoutConstraint] = [
        NSLayoutConstraint(item: self.table, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: self.table, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: self.table, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0),
        NSLayoutConstraint(item: self.table, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
    ]
    


    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.table)
        NSLayoutConstraint.activate(self.tableViewConstraints)
        configureValidationObserver()
        configureContentObserver()
    }
    
    func configureValidationObserver(){
        var validationObservers = [Observable<Bool>]()
        for cell in self.cells {
            if let cell = cell as? InputCell {
                validationObservers.append(cell.validationObservable)
            }
        }
        _ = Observable.combineLatest(validationObservers) { registrationObservers -> Bool in
            print(registrationObservers)
            return registrationObservers.reduce(true, { $0 && $1 })
            }
            .subscribe(onNext:{ validationStatus in
                print(validationStatus)
                self.formHasValidated = true
            }).addDisposableTo(disposeBag)
    }
    
    func configureContentObserver() {
        var contentObservables = [Observable<[String:String]>]()
        for cell in self.cells {
            if let cell = cell as? InputCell {
                contentObservables.append(cell.contentObservable)
            }
        }
        _ = Observable.combineLatest(contentObservables) { contentObservables -> [String:String] in
            return contentObservables.flatMap{ $0 }.reduce( [String: String]() ) { (dict, tuple) -> [String: String] in
                var mutableDict = dict
                mutableDict.updateValue(tuple.1, forKey: tuple.0)
                return mutableDict
            }
        }
            .subscribe(onNext:{ registrationFieldsDict in
                if self.formHasValidated {
                    print("Registration Fields have validated: \(registrationFieldsDict)")
                }
                print("Registration Fields: \(registrationFieldsDict)")

            }).addDisposableTo(disposeBag)
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return self.cells[indexPath.row]
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }
}

    
