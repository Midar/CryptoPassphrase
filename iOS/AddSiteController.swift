/*
 * Copyright (c) 2016 - 2023 Jonathan Schleifer <js@nil.im>
 *
 * https://fl.nil.im/cryptopassphrase
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND ISC DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS.  IN NO EVENT SHALL ISC BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
 * OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

import UIKit
import ObjFW
import ObjFWBridge

class AddSiteController: UITableViewController {
    @IBOutlet var nameField: UITextField?
    @IBOutlet var lengthField: UITextField?
    @IBOutlet var legacySwitch: UISwitch?
    public var keyFile: String?
    @IBOutlet var keyFileLabel: UILabel?
    public var mainViewController: MainViewController?

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 1 && indexPath.row == 1 {
            self.performSegue(withIdentifier: "selectKeyFile", sender: self)
        }
    }

    override func tableView(
        _ tableView: UITableView,
        willSelectRowAt indexPath: IndexPath
    ) -> IndexPath? {
        if indexPath.section == 1 && indexPath.row == 1 {
            return indexPath
        }

        return nil
    }

    private func showAlert(controller: UIViewController, title: String,
                           message: String) {
        let alert = UIAlertController(title: title, message: message,
                                      preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }

    @IBAction func done(_ sender: Any) {
        guard let name = nameField?.text else { return }
        guard let lengthString = lengthField?.text else { return }

        guard name.count > 0 else {
            showAlert(controller: self, title: "Name missing",
                      message: "Please enter a name.")
            return
        }

        guard let length = UInt(lengthString), length >= 3, length <= 64 else {
            showAlert(controller: self, title: "Invalid length",
                      message: "Please enter a number between 3 and 64.")
            return
        }

        guard let siteStorage = mainViewController?.siteStorage else { return }

        guard !siteStorage.hasSite(name) else {
            showAlert(controller: self, title: "Site Already Exists",
                      message: "Please pick a name that does not exist yet.")
            return
        }

        siteStorage.setSite(name, length: length,
                            isLegacy: legacySwitch?.isOn ?? false,
                            keyFile: self.keyFile)
        mainViewController?.reset()
        navigationController?.popViewController(animated: true)
    }

    @IBAction func cancel(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "selectKeyFile" {
            let controller = segue.destination as? SelectKeyFileController
            controller?.addSiteController = self
        }
    }
}
