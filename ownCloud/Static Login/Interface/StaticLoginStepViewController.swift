//
//  StaticLoginStepViewControllerTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 26.11.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit

class StaticLoginStepViewController : StaticTableViewController {
	weak var loginViewController : StaticLoginViewController?

	var centerVertically : Bool = false

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.view.backgroundColor = .clear
	}

	init(loginViewController theLoginViewController: StaticLoginViewController) {
		super.init(style: .grouped)

		loginViewController = theLoginViewController
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	class FullWidthHeaderView : UIView, Themeable {
		init() {
			super.init(frame: .zero)
		}

		deinit {
			if hasRegistered {
				Theme.shared.unregister(client: self)
			}
		}

		required init?(coder aDecoder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}

		private var hasRegistered : Bool = false

		override func didMoveToSuperview() {
			if self.superview != nil {
				self.widthAnchor.constraint(equalTo: self.superview!.widthAnchor).isActive = true

				if !hasRegistered {
					hasRegistered = true
					Theme.shared.register(client: self, applyImmediately: true)
				}
			}
		}

		private var themeAppliers : [ThemeApplier] = []

		func addThemeApplier(_ applier: @escaping ThemeApplier) {
			themeAppliers.append(applier)
		}

		func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
			for applier in themeAppliers {
				applier(theme, collection, event)
			}
		}
	}

	static func buildHeader(title: String, message: String?, cellSpacing: CGFloat = 20, topSpacing : CGFloat = 30, bottomSpacing : CGFloat = 20 ) -> UIView {
		let horizontalPadding: CGFloat = 0

		let headerView = FullWidthHeaderView()
		headerView.translatesAutoresizingMaskIntoConstraints = false

		let titleLabel = UILabel()
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: UILayoutConstraintAxis.horizontal)

		titleLabel.text = title
		titleLabel.textAlignment = .center
		titleLabel.numberOfLines = 0
		headerView.addSubview(titleLabel)

		headerView.addThemeApplier({ (_, collection, _) in
			titleLabel.applyThemeCollection(collection, itemStyle: .title)
		})

		titleLabel.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.5, weight: .bold)

		NSLayoutConstraint.activate([
			titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: headerView.safeAreaLayoutGuide.leftAnchor, constant: horizontalPadding),
			titleLabel.rightAnchor.constraint(lessThanOrEqualTo: headerView.safeAreaLayoutGuide.rightAnchor, constant: -horizontalPadding),
			titleLabel.centerXAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.centerXAnchor),

			titleLabel.topAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.topAnchor, constant: topSpacing)
		])

		if message != nil {
			let messageLabel = UILabel()
			messageLabel.translatesAutoresizingMaskIntoConstraints = false
			messageLabel.setContentHuggingPriority(UILayoutPriority.defaultLow, for: UILayoutConstraintAxis.horizontal)

			messageLabel.text = message
			messageLabel.textAlignment = .center
			messageLabel.numberOfLines = 0

			headerView.addThemeApplier({ (_, collection, _) in
				messageLabel.applyThemeCollection(collection)
			})

			headerView.addSubview(messageLabel)

			NSLayoutConstraint.activate([
				messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: cellSpacing),
				messageLabel.leftAnchor.constraint(greaterThanOrEqualTo: headerView.safeAreaLayoutGuide.leftAnchor, constant: horizontalPadding),
				messageLabel.rightAnchor.constraint(lessThanOrEqualTo: headerView.safeAreaLayoutGuide.rightAnchor, constant: -horizontalPadding),
				messageLabel.centerXAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.centerXAnchor),
				messageLabel.bottomAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.bottomAnchor, constant: -bottomSpacing)
			])
		} else {
			NSLayoutConstraint.activate([
				titleLabel.bottomAnchor.constraint(equalTo: headerView.safeAreaLayoutGuide.bottomAnchor, constant: -bottomSpacing)
			])
		}

		return headerView
	}
}

extension StaticTableViewSection {
	@discardableResult
	func addStaticHeader(title: String, message: String?) -> UIView {
		let sectionHeaderView : UIView = StaticLoginStepViewController.buildHeader(title: title, message: message)

		self.headerView = sectionHeaderView

		return sectionHeaderView
	}

	@discardableResult
	func addButtonFooter(proceedLabel: String, cancelLabel : String?, topSpacing : CGFloat = 30) -> (UIButton, UIButton?) {
		let containerView = StaticLoginStepViewController.FullWidthHeaderView()
		let continueButton : ThemeButton = ThemeButton()
		var cancelButton : UIButton?

		// containerView.translatesAutoresizingMaskIntoConstraints = false
		continueButton.translatesAutoresizingMaskIntoConstraints = false

		continueButton.setTitle(proceedLabel, for: .normal)

		containerView.addSubview(continueButton)

		NSLayoutConstraint.activate([
			continueButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topSpacing),
			continueButton.leftAnchor.constraint(equalTo: containerView.leftAnchor),
			continueButton.rightAnchor.constraint(equalTo: containerView.rightAnchor)
		])

		if cancelLabel != nil {
			cancelButton = UIButton()
			cancelButton?.translatesAutoresizingMaskIntoConstraints = false

			cancelButton?.setTitle(cancelLabel, for: .normal)

			containerView.addSubview(cancelButton!)

			NSLayoutConstraint.activate([
				cancelButton!.topAnchor.constraint(equalTo: continueButton.bottomAnchor, constant: 10),
				cancelButton!.leftAnchor.constraint(equalTo: containerView.leftAnchor),
				cancelButton!.rightAnchor.constraint(equalTo: containerView.rightAnchor),
				cancelButton!.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
			])
		} else {
			NSLayoutConstraint.activate([
				continueButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
			])
		}

		containerView.addThemeApplier({ [weak continueButton, cancelButton] (_, collection, _) in
			continueButton?.applyThemeCollection(collection)
			cancelButton?.applyThemeCollection(collection)
		})

		self.footerView = containerView

		return (continueButton, cancelButton)
	}
}