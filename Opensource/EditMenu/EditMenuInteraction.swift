//
//  EditMenuInteraction.swift
//
//  Created by songgeb on 2023/9/15.
//  Copyright © 2023 songgeb. All rights reserved.
//

import UIKit

@objcMembers
class EditMenuInteractionItem: NSObject {
    let title: String
    var callback: (() -> Void)?
    init(title: String, callback: (() -> Void)? = nil) {
        self.title = title
        self.callback = callback
    }
}

/// 对系统的UIMenuController和UIEditMenuInteraction进行封装，支持自定义EditMenu功能
/// 通过showMenu方法传入选项数据及事件回调block
@objcMembers
class EditMenuInteraction: NSObject {
    private var showingItems: [EditMenuInteractionItem]?
    private var targetRect: CGRect?
    private let seperator = "_"
    // iOS 16之前使用官方的UIMenuController
    private lazy var menuController: UIMenuController = .shared

    private lazy var dummyView: EditMenuInteractionDummy = {
        let view = EditMenuInteractionDummy { [weak self] selector in
            guard let self = self else { return }
            self.selectMenuItem(selector)
        }
        return view
    }()

    // iOS 16之后使用官方的UIEditMenuInteraction
    private lazy var rawMenuInteraction: Any? = {
        if #available(iOS 16, *) {
            return UIEditMenuInteraction(delegate: self) as Any
        }
        return nil
    }()

    @available(iOS 16, *)
    private var menuInteraction: UIEditMenuInteraction? {
        get {
            rawMenuInteraction as? UIEditMenuInteraction
        }
        set {
            rawMenuInteraction = newValue
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        clear()
    }

    // MARK: public function

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(willMenuControllerHide(_:)), name: UIMenuController.willHideMenuNotification, object: nil)
    }

    /// 显示menu
    /// - Parameters:
    ///   - items:
    ///   - rect: 相对于interactionView的一个rect，一般为希望显示menu的selection的最小包围矩形
    ///   - indexPath:
    func showMenu(_ items: [EditMenuInteractionItem], targetRect: CGRect, for view: UIView) {
        guard !items.isEmpty else { return }

        showingItems = items
        self.targetRect = targetRect

        if #available(iOS 16, *) {
            guard let menuInteraction = menuInteraction else { return }
            view.addInteraction(menuInteraction)
            let config = UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero)
            menuInteraction.presentEditMenu(with: config)
        } else {
            menuController.menuItems = nil
            menuController.setMenuVisible(false, animated: false)

            dummyView.updateActions(actionsForDummyView(items))
            view.addSubview(dummyView)
            dummyView.frame = view.bounds

            dummyView.becomeFirstResponder()
            DispatchQueue.main.async {
                self.menuController.menuItems = self.menuItems(from: items)
                self.menuController.setTargetRect(targetRect, in: self.dummyView)
                self.menuController.setMenuVisible(true, animated: true)
            }
        }
    }

    func dismissMenu() {
        if #available(iOS 16, *) {
            menuInteraction?.dismissMenu()
        } else {
            menuController.setMenuVisible(false, animated: true)
        }
        clear()
    }

    /// 选中某个menuitem时执行。该方法仅在iOS 16之前会执行
    func selectMenuItem(_ selector: Selector) {
        guard let item = menuItem(from: selector) else { return }
        item.callback?()
    }

    // MARK: private function

    @objc private func willMenuControllerHide(_: Notification) {
        guard let _ = showingItems else { return }
        clear()
    }

    private func clear() {
        if #available(iOS 16, *) {
        } else {
            if let _ = showingItems {
                menuController.menuItems = nil
                dummyView.removeFromSuperview()
            }
        }
        showingItems = nil
        targetRect = nil
    }

    private func menuItems(from items: [EditMenuInteractionItem]) -> [UIMenuItem] {
        items.enumerated().compactMap {
            let item = $0.element
            return UIMenuItem(title: item.title, action: selector(from: item, index: $0.offset))
        }
    }

    private func menuItem(from selector: Selector) -> EditMenuInteractionItem? {
        let selectorString = NSStringFromSelector(selector) as String
        let cmps = selectorString.components(separatedBy: seperator)
        guard let items = showingItems, cmps.count == 2, let index = Int(cmps[1])
        else { return nil }
        return items[index]
    }

    private func selector(from _: EditMenuInteractionItem, index: Int) -> Selector {
        // selector产生规则
        Selector("clickMenuItem\(seperator)\(index)")
    }

    private func actionsForDummyView(_ items: [EditMenuInteractionItem]) -> Set<String> {
        var set = Set<String>()
        items.enumerated().forEach {
            set.insert(NSStringFromSelector(selector(from: $0.element, index: $0.offset)))
        }
        return set
    }
}

// MARK: UIEditMenuInteractionDelegate

extension EditMenuInteraction: UIEditMenuInteractionDelegate {
    @available(iOS 16.0, *)
    func editMenuInteraction(_: UIEditMenuInteraction, targetRectFor _: UIEditMenuConfiguration) -> CGRect {
        guard let rect = targetRect else {
            return .zero
        }
        return rect
    }

    @available(iOS 16.0, *)
    func editMenuInteraction(_: UIEditMenuInteraction, menuFor _: UIEditMenuConfiguration, suggestedActions _: [UIMenuElement]) -> UIMenu? {
        // items -> UIMenu
        guard let items = showingItems else { return nil }

        func action(from item: EditMenuInteractionItem) -> UIAction {
            UIAction(title: item.title) { [weak self] _ in
                guard let self = self else { return }
                item.callback?()
            }
        }

        let actions = items.map {
            action(from: $0)
        }
        return UIMenu(children: actions)
    }
}
