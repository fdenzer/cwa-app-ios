//
// Corona-Warn-App
//
// SAP SE and all other contributors
// copyright owners license this file to you under the Apache
// License, Version 2.0 (the "License"); you may not use this
// file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//

import Foundation
import UIKit

enum UpdateAlertType {
	case none
	case update
	case forceUpdate
}

class AppUpdateCheckHelper {

	let client: Client

    /// The retained `NotificationCenter` observer that listens for `UIApplication.didBecomeActiveNotification` notifications.
    var applicationDidBecomeActiveObserver: NSObjectProtocol?

	init(client: Client) {
		self.client = client
	}
	deinit {
		removeObserver()
	}

	func checkAppVersionDialog(for vc: UIViewController?) {
		client.appConfiguration { result in
			/*guard let versionInfo: SAP_ApplicationVersionConfiguration = result?.appVersion else {
				return
			}*/
			guard let appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
				return
			}
			let minVersion = "0.1.0"// "\(versionInfo.ios.min.major).\(versionInfo.ios.min.minor).\(versionInfo.ios.min.patch)"
			let latestVersion = "1.0.0"// "\(versionInfo.ios.latest.major).\(versionInfo.ios.latest.minor).\(versionInfo.ios.latest.patch)"
			guard let alert = self.createAlert(self.compareVersion(currentVersion: appVersion, minVersion: minVersion, latestVersion: latestVersion), vc: vc) else {
				return
			}
			vc?.present(alert, animated: true, completion: nil)
		}
	}

	private func setObserver(vc: UIViewController?) {
		guard self.applicationDidBecomeActiveObserver == nil else { return }
		self.applicationDidBecomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
			guard let self = self else { return }
			self.checkAppVersionDialog(for: vc)
		}
	}

	private func removeObserver() {
		NotificationCenter.default.removeObserver(applicationDidBecomeActiveObserver as Any)
        applicationDidBecomeActiveObserver = nil
	}

	func createAlert(_ type: UpdateAlertType, vc: UIViewController?) -> UIAlertController? {
		let alert = UIAlertController(title: AppStrings.UpdateMessage.title, message: AppStrings.UpdateMessage.text, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: NSLocalizedString(AppStrings.UpdateMessage.actionUpdate, comment: ""), style: .default, handler: { _ in
			//TODO: Add correct App Store ID
			guard let url: URL = URL(string: "itms-apps://itunes.apple.com/app/apple-store/") else {
				return
			}
				UIApplication.shared.open(url, options: [:], completionHandler: nil)
		}))
		switch type {
		case .update:
			alert.addAction(UIAlertAction(title: NSLocalizedString(AppStrings.UpdateMessage.actionLater, comment: ""), style: .default, handler: { _ in
				//Do nothing
			}))
		case .forceUpdate:
			alert.message = AppStrings.UpdateMessage.textForce
			self.setObserver(vc: vc)
		case .none:
			return nil
		}
		return alert
	}

	func compareVersion(currentVersion: String, minVersion: String, latestVersion: String) -> UpdateAlertType {
		let checkMinVersion = currentVersion.compare(minVersion, options: .numeric)
		if checkMinVersion == .orderedAscending {
			return .forceUpdate
		} else {
			let checkLatestVersion = currentVersion.compare(latestVersion, options: .numeric)
			if checkLatestVersion == .orderedAscending {
				return .update
			}
		}
		return .none
	}
}
