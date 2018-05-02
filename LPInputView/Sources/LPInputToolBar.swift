//
//  LPInputToolBar.swift
//  LPInputView
//
//  Created by pengli on 2018/4/23.
//  Copyright © 2018年 pengli. All rights reserved.
//

import UIKit

protocol LPInputToolBarDelegate: class {
    func toolBarDidChangeHeight(_ toolBar: LPInputToolBar)
    func toolBar(_ toolBar: LPInputToolBar, barItemClicked item: UIButton, type: LPInputToolBarItemType)
    
    func toolBar(_ toolBar: LPInputToolBar, textViewShouldBeginEditing textView: UITextView) -> Bool
    
    func toolBar(_ toolBar: LPInputToolBar, textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool
    func toolBar(_ toolBar: LPInputToolBar, textView: LPStretchyTextView, didProcessEditing editedRange: NSRange, changeInLength delta: Int)
    func toolBar(_ toolBar: LPInputToolBar, inputAtCharacter character: String)
}

public class LPInputToolBar: UIView {
    weak var delegate: LPInputToolBarDelegate?
    var status: LPInputToolBarItemType = .text {
        didSet {
            renewStatus(status, oldValue: oldValue)
        }
    }
    
    public var contentInset = UIEdgeInsets(top: 10,
                                           left: 15,
                                           bottom: 10,
                                           right: 15)
    public var interitemSpacing: CGFloat = 10
    
    private(set) var recordButton: LPRecordButton?
    private(set) var config: LPInputToolBarConfig
    
    private var items: [LPInputToolBarItemType: UIView] = [:]
    private var itemTypes: [LPInputToolBarItemType]
    
    private var topSeparator: UIView?
    private var bottomSeparator: UIView?
    
    deinit {
        print("LPInputToolBar: -> release memory.")
    }
    
    public init(frame: CGRect, config: LPInputToolBarConfig) {
        self.config = config
        self.itemTypes = config.toolBarItems
        
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.white
        self.commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard size.width != 0.0 else { return size }
        
        if status == .voice {
            return CGSize(width: size.width, height: 54.0)
        }
        
        var viewHeight: CGFloat = 0.0
        var textViewWidth: CGFloat = size.width
        
        for type in itemTypes where type != .text {
            if let item = items[type] {
                textViewWidth -= item.frame.width
                viewHeight = max(viewHeight, item.frame.height)
            }
        }
        
        if let textView = textView
            , (textView.superview == nil || textView.superview is LPInputToolBar) {
            textViewWidth -= (CGFloat(itemTypes.count - 1) * interitemSpacing)
            textView.frame.size.width = textViewWidth - contentInset.left - contentInset.right
            
            textView.layoutIfNeeded() // TextView 自适应高度
            viewHeight = textView.frame.height
        }
        
        viewHeight = viewHeight + contentInset.top + contentInset.bottom
        return CGSize(width: size.width, height: viewHeight)
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        var left: CGFloat = 0.0
        for (idx, type) in itemTypes.enumerated() {
            if let item = items[type] {
                if idx == 0 {
                    item.frame.origin.x = contentInset.left
                } else {
                    item.frame.origin.x = left + interitemSpacing
                }
                item.center.y = frame.height / 2.0
                left = item.frame.maxX
                
                if item.superview == nil { addSubview(item) }
            }
        }
        
        if let recordBtn = recordButton, let sv = superview
            , let ssv = sv.superview {
            recordBtn.center.x = ssv.frame.width / 2
            recordBtn.frame.origin.y = ssv.frame.height - LPKeyboard.shared.safeAreaInsets.bottom - frame.height - recordBtn.frame.height - contentInset.bottom
            if recordBtn.superview == nil { ssv.addSubview(recordBtn) }
        }
        
        if let separator = bottomSeparator {
            separator.frame.origin.y = frame.height - 0.5
        }
    }
}

// MARK: - Public Funs

public extension LPInputToolBar {
    
    var textView: LPStretchyTextView? {
        if let textView = items[.text] as? LPStretchyTextView { return textView }
        return config.textViewOfCustomToolBarItem
    }
    
    var isShowKeyboard: Bool {
        get { return textView?.isFirstResponder ?? false }
        set {
            guard let textView = textView else { return }
            if newValue {
                textView.becomeFirstResponder()
            } else {
                textView.resignFirstResponder()
            }
        }
    }
    
    func item(with itemType: LPInputToolBarItemType) -> UIView? {
        return items[itemType]
    }
}

// MARK: -
// MARK: - Private

extension LPInputToolBar {
    
    private func commonInit() {
        contentInset = config.barContentInset
        interitemSpacing = config.barInteritemSpacing
        
        for type in itemTypes {
            switch type {
            case .voice, .emotion, .at, .more:
                let btn = UIButton(type: .custom)
                config.configItem(btn, type: type)
                btn.tag = type.rawValue
                btn.sizeToFit()
                btn.addTarget(self, action: #selector(barItemClicked), for: .touchUpInside)
                items[type] = btn
                if type == .voice {
                    let recordBtn = LPRecordButton(type: .custom)
                    config.configRecordButton(recordBtn)
                    recordBtn.isHidden = true
                    recordBtn.sizeToFit()
                    recordButton = recordBtn
                }
            case .text:
                let textView = LPStretchyTextView(frame: .zero)
                textView.font = UIFont.systemFont(ofSize: 14.0)
                textView.textColor = UIColor.black
                textView.backgroundColor = UIColor.clear
                textView.returnKeyType = .send
                config.configTextView(textView, type: type)
                textView.tag = type.rawValue
                items[type] = textView
            default:
                if let custom = config.configCustomBarItem(for: type) {
                    custom.tag = type.rawValue
                    items[type] = custom
                }
            }
        }
        
        if let textView = textView {
            textView.stretchyDelegate = self
            textView.isAtEnabled = config.isAtEnabled
        }
        
        /// 处理分隔符
        guard let separators = config.separatorOfToolBar else { return }
        for separator in separators {
            switch separator.loc {
            case .top:
                let sep = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 0.5))
                sep.backgroundColor = separator.color ?? #colorLiteral(red: 0.8980392157, green: 0.8980392157, blue: 0.8980392157, alpha: 1)
                addSubview(sep)
                topSeparator = sep
            case .bottom:
                let sep = UIView(frame: CGRect(x: 0, y: frame.height - 0.5, width: frame.width, height: 0.5))
                sep.backgroundColor = separator.color ?? #colorLiteral(red: 0.8980392157, green: 0.8980392157, blue: 0.8980392157, alpha: 1)
                addSubview(sep)
                bottomSeparator = sep
            }
        }
    }
    
    @objc private func barItemClicked(_ sender: UIButton) {
        let type = LPInputToolBarItemType(rawValue: sender.tag)
        delegate?.toolBar(self, barItemClicked: sender, type: type)
    }
    
    private func renewStatus(_ status: LPInputToolBarItemType,
                             oldValue: LPInputToolBarItemType) {
        guard let textView = textView
            , let recordButton = recordButton else { return }
        if oldValue == .voice {
            textView.alpha = 0.0
            textView.isHidden = false
            recordButton.alpha = 1.0
            animate({
                textView.alpha = 1.0
                recordButton.alpha = 0.0
            }, completion: { (finished) in
                recordButton.isHidden = true
            })
            sizeToFit()
        } else if self.status == .voice {
            textView.alpha = 1.0
            recordButton.alpha = 0.0
            recordButton.isHidden = false
            animate({
                textView.alpha = 0.0
                recordButton.alpha = 1.0
            }, completion: { (finished) in
                textView.isHidden = true
            })
            sizeToFit()
        } else {
            textView.alpha = 0.0
            textView.isHidden = false
            animate({
                textView.alpha = 1.0
                recordButton.alpha = 0.0
            }, completion: { (finished) in
                recordButton.isHidden = true
            })
            sizeToFit()
        }
    }
    
    private func animate(_ animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {
        let options = UIViewAnimationOptions(rawValue: 7)
        UIView.animate(withDuration: 0.25,
                       delay: 0.0,
                       options: options,
                       animations: animations,
                       completion: completion)
    }
}

// MARK: - Delegate Funcs

extension LPInputToolBar: LPStretchyTextViewDelegate {
    
    public func textView(_ textView: LPStretchyTextView, heightDidChange newHeight: CGFloat) {
        guard let delegate = delegate else { return }
        let height = newHeight + contentInset.top + contentInset.bottom
        animate({
            self.frame.size.height = height
        }, completion: nil)
        delegate.toolBarDidChangeHeight(self)
    }
    
    public func textView(_ textView: LPStretchyTextView, inputAtCharacter character: String) {
        delegate?.toolBar(self, inputAtCharacter: character)
    }
    
    public func textView(_ textView: LPStretchyTextView, didProcessEditing editedRange: NSRange, changeInLength delta: Int) {
        delegate?.toolBar(self, textView: textView, didProcessEditing: editedRange, changeInLength: delta)
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return delegate?.toolBar(self, textViewShouldBeginEditing: textView) ?? true
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return delegate?.toolBar(self, textView: textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }
}
