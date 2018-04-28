//
//  LPCustomInputViewController.swift
//  LPInputViewDemo
//
//  Created by pengli on 2018/4/28.
//  Copyright © 2018年 pengli. All rights reserved.
//

import UIKit
import LPInputView

class LPCustomInputViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    lazy var inputBar: LPInputView = {
        let rect = CGRect(x: 0, y: 0, width: view.frame.width, height: 60)
        return LPInputView(frame: rect, config: LPInputViewConfig())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.layer.borderColor = UIColor.red.cgColor
        tableView.layer.borderWidth = 1
        
        inputBar.delegate = self
        view.addSubview(inputBar)
        
        let right = UIBarButtonItem(barButtonSystemItem: .done,
                                    target: self,
                                    action: #selector(rightButtonClicked))
        navigationItem.rightBarButtonItem = right
        right.isEnabled = false
    }
    
    @objc func rightButtonClicked(_ sender: UIBarButtonItem) {
        print("rightButtonClicked")
    }
}

extension LPCustomInputViewController: UITableViewDelegate, UITableViewDataSource {
    
    private var textCell: LPCustomInputViewCell? {
        let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))
        return cell as? LPCustomInputViewCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row == 0 else {
            return tableView.dequeueReusableCell(withIdentifier: "LPCustomOtherCell", for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "LPCustomInputViewCell",
                                                 for: indexPath) as! LPCustomInputViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
    }
}

extension LPCustomInputViewController: LPInputViewDelegate, LPEmoticonViewDelegate {
    
    // MARK: -  LPInputViewDelegate
    
    func inputViewDidChangeFrame(_ inputView: LPInputView) {
        
    }
    
    func inputView(_ inputView: LPInputView, shouldHandleClickedFor item: UIButton, type: LPInputToolBarItemType) -> Bool {
        if type == .at {
            pushFriendsVC(nil)
            return false
        }
        return true
    }
    
    func inputView(_ inputView: LPInputView, containerViewFor type: LPInputToolBarItemType) -> UIView? {
        switch type {
        case .emotion:
            return LPEmoticonView.instance(delegate: self)
        case .more:
            return LPMoreView(target: self, action: #selector(moreItemClicked))
        default:
            return nil
        }
    }
    
    //    func inputView(_ inputView: LPInputView, textView: LPStretchyTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    //    }
    
    func inputView(_ inputView: LPInputView, textView: LPStretchyTextView, didProcessEditing editedRange: NSRange, changeInLength delta: Int) {
        navigationItem.rightBarButtonItem?.isEnabled = textView.textStorage.length > 0
    }
    
    func inputView(_ inputView: LPInputView, inputAtCharacter character: String) {
        pushFriendsVC(character)
    }
    
    func inputView(_ inputView: LPInputView, shouldHandleForMaximumLengthExceedsLimit maxLength: Int) -> Bool {
        print("字符超出限制：\(maxLength)")
        return true
    }
    
    func inputView(_ inputView: LPInputView, sendFor textView: LPStretchyTextView) -> Bool {
        sendMSG()
        return true
    }
    
    // MARK: - LPEmoticonViewDelegate
    
    func inputEmoticon(id: String, img: UIImage) {
        guard let textView = inputBar.textView else { return }
        textView.insertEmotion(LPTextAttachment(image: img, scale: 1.0, tag: id))
    }
    
    func inputEmoticonDelete() {
        inputBar.textView?.deleteCharacters()
    }
    
    func inputEmoticonSend() {
        sendMSG()
    }
    
    // MARK: -
    // MARK: - Action
    
    private func pushFriendsVC(_ character: String?) {
        let vc = LPFriendListController(style: .plain)
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
        vc.selectedBlock = { friend in
            self.inputBar.textView?.insertUser(withID: friend.id,
                                               name: friend.name,
                                               checkAt: character)
        }
    }
    
    private func sendMSG() {
        guard let textView = inputBar.textView else { return }
        
        let atUserPlaceholderByBlock: (Int, LPAtUser) -> String = { (index, _) -> String in
            return "@{\(index)}"
        }
        let result = textView.textStorage.lp_parse(atUserPlaceholderByBlock)
        print(result.description)
        
        textView.clearTextStorage()
    }
    
    @objc private func moreItemClicked(_ sender: UIButton) {
        let title = "提示"
        let msg = "您点击了“\(sender.titleLabel?.text ?? "")”"
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "👌", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
