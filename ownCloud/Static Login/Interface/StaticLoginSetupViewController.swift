//
//  StaticLoginSetupViewController.swift
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
import ownCloudSDK

class StaticLoginSetupViewController : StaticLoginStepViewController {
	var profile : StaticLoginProfile
	var bookmark : OCBookmark

	init(loginViewController theLoginViewController: StaticLoginViewController, profile theProfile: StaticLoginProfile) {
		profile = theProfile
		bookmark = OCBookmark(for: profile.url!)

		super.init(loginViewController: theLoginViewController)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private var username : String?
	private var password : String?

	func loginMaskSection() -> StaticTableViewSection {
		var loginMaskSection : StaticTableViewSection

		loginMaskSection = StaticTableViewSection(headerTitle: nil, identifier: "loginMaskSection")
		loginMaskSection.addStaticHeader(title: profile.name!, message: profile.prompt)

		loginMaskSection.add(row: StaticTableViewRow(textFieldWithAction: { [weak self] (row, _) in
			self?.username = row.value as? String
		}, placeholder: "Username", keyboardType: .asciiCapable, autocorrectionType: .no, autocapitalizationType: .none, returnKeyType: .continue, identifier: "username"))

		loginMaskSection.add(row: StaticTableViewRow(secureTextFieldWithAction: { [weak self] (row, _) in
			self?.password = row.value as? String
		}, placeholder: "Password", keyboardType: .asciiCapable, autocorrectionType: .no, autocapitalizationType: .none, returnKeyType: .continue, identifier: "password"))

		let (proceedButton, cancelButton) = loginMaskSection.addButtonFooter(proceedLabel: "Login", cancelLabel: "Cancel")
		proceedButton.addTarget(self, action: #selector(self.proceed(_:)), for: .touchUpInside)
		cancelButton?.addTarget(self, action: #selector(self.cancel(_:)), for: .touchUpInside)

		return loginMaskSection
	}

	func tokenMaskSection() -> StaticTableViewSection {
		var tokenMaskSection : StaticTableViewSection

		tokenMaskSection = StaticTableViewSection(headerTitle: nil, identifier: "tokenMaskSection")
		tokenMaskSection.addStaticHeader(title: profile.name!, message: profile.prompt)

		let (proceedButton, cancelButton) = tokenMaskSection.addButtonFooter(proceedLabel: "Continue", cancelLabel: "Cancel")
		proceedButton.addTarget(self, action: #selector(self.proceed(_:)), for: .touchUpInside)
		cancelButton?.addTarget(self, action: #selector(self.cancel(_:)), for: .touchUpInside)

		return tokenMaskSection
	}

	func busySection(message: String) -> StaticTableViewSection {
		let busySection : StaticTableViewSection = StaticTableViewSection(headerTitle: nil, identifier: "busySection")
		let activityIndicator : UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
		let containerView : StaticLoginStepViewController.FullWidthHeaderView = StaticLoginStepViewController.FullWidthHeaderView()
		let centerView : UIView = UIView()
		let messageLabel : UILabel = UILabel()

		containerView.translatesAutoresizingMaskIntoConstraints = false
		centerView.translatesAutoresizingMaskIntoConstraints = false
		messageLabel.translatesAutoresizingMaskIntoConstraints = false
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false

		centerView.addSubview(activityIndicator)
		centerView.addSubview(messageLabel)

		containerView.addSubview(centerView)

		containerView.addThemeApplier({ (_, collection, _) in
			messageLabel.applyThemeCollection(collection)
		})

		messageLabel.text = message

		NSLayoutConstraint.activate([
			activityIndicator.widthAnchor.constraint(equalToConstant: 30),
			activityIndicator.heightAnchor.constraint(equalToConstant: 30),
			activityIndicator.leftAnchor.constraint(equalTo: centerView.leftAnchor),
			activityIndicator.topAnchor.constraint(equalTo: centerView.topAnchor),
			activityIndicator.bottomAnchor.constraint(equalTo: centerView.bottomAnchor),

			messageLabel.centerYAnchor.constraint(equalTo: centerView.centerYAnchor),
			messageLabel.leftAnchor.constraint(equalTo: activityIndicator.rightAnchor, constant: 20),
			messageLabel.rightAnchor.constraint(equalTo: centerView.rightAnchor),

			centerView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 40),
			centerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
			centerView.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor),
			centerView.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor),
			centerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -40)
		])

		busySection.headerView = containerView

		activityIndicator.startAnimating()

		return busySection
	}

	@objc func proceed(_ sender: Any?) {
		if let connection = OCConnection(bookmark: bookmark, persistentStoreBaseURL: nil) {
			var options : [OCAuthenticationMethodKey : Any] = [:]

			if let authMethodIdentifier = bookmark.authenticationMethodIdentifier {
				if OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authMethodIdentifier)?.type() == .passphrase {
					options[.usernameKey] = username ?? ""
					options[.passphraseKey] = password ?? ""
				}
			}

			options[.presentingViewControllerKey] = self

			connection.generateAuthenticationData(withMethod: bookmark.authenticationMethodIdentifier, options: options, completionHandler: { (error, authMethodIdentifier, authMethodData) in
				if error == nil {
					self.bookmark.authenticationMethodIdentifier = authMethodIdentifier
					self.bookmark.authenticationData = authMethodData

					self.bookmark.name = self.profile.bookmarkName

					OCBookmarkManager.shared.addBookmark(self.bookmark)
				} else {
					if let nsError = error as NSError?,
					   nsError.isOCError(withCode: .errorAuthorizationFailed) {
					   	OnMainThread {
							self.navigationController?.view.shakeHorizontally()
						}
					}
				}
			})
		}
	}

	@objc func cancel(_ sender: Any?) {
		self.navigationController?.popViewController(animated: true)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
	}

	var busySection : StaticTableViewSection?

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		busySection = self.busySection(message: "Contacting sever…")

		self.addSection(busySection!)
		self.determineSupportedAuthMethod()
	}

	func determineSupportedAuthMethod() {
		if let connection = OCConnection(bookmark: bookmark, persistentStoreBaseURL: nil) {
			connection.prepareForSetup(options: nil, completionHandler: { (connectionIssue, _, _, preferredAuthenticationMethods) in
				var proceed : Bool = true

				if let issue = connectionIssue {
					proceed = self.show(issue: issue, proceed: { () in
						OnMainThread {
						//	self.determineSupportedAuthMethod()
						}
					}, cancel: { () in
						OnMainThread {
							self.cancel(nil)
						}
					})
				}

				if proceed, preferredAuthenticationMethods != nil, let authenticationMethod = preferredAuthenticationMethods!.first {
					self.bookmark.authenticationMethodIdentifier = preferredAuthenticationMethods?.first

					if let authMethodClass = OCAuthenticationMethod.registeredAuthenticationMethod(forIdentifier: authenticationMethod) {
						OnMainThread {
							self.tableView.performBatchUpdates({
								self.removeSection(self.busySection!, animated: true)

								switch authMethodClass.type() {
									case .passphrase:
										self.addSection(self.loginMaskSection(), animated: true)

									case .token:
										self.addSection(self.tokenMaskSection(), animated: true)
								}
							}, completion: nil)
						}
					}
				} else {
					self.bookmark.authenticationMethodIdentifier = nil
				}
			})
		}
	}

	func show(issue: OCConnectionIssue?, proceed: (() -> Void)? = nil, cancel: (() -> Void)? = nil) -> Bool {
		if let displayIssues = issue?.prepareForDisplay() {
			if displayIssues.displayLevel.rawValue >= OCConnectionIssueLevel.warning.rawValue {
				// Present issues if the level is >= warning
				OnMainThread {
					let issuesViewController = ConnectionIssueViewController(displayIssues: displayIssues, completion: { (response) in
						switch response {
							case .cancel:
								issue?.reject()

							case .approve:
								issue?.approve()
								proceed?()

							case .dismiss:
								cancel?()
						}
					})

					self.present(issuesViewController, animated: true, completion: nil)
				}

				return false
			} else {
				// Do not present issues
				issue?.approve()
				proceed?()
			}
		}

		return true
	}
}