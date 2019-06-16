/*
 * Copyright (c) 2016 - 2019 Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/git/cryptopassphrase.git
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice is present in all copies.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import ObjFW
import ObjFW_Bridge

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
        guard let name = nameField?.text?.ofObject else { return }
        guard let lengthString = lengthField?.text?.ofObject else { return }

        guard name.length > 0 else {
            showAlert(controller: self, title: "Name missing",
                      message: "Please enter a name.")
            return
        }

        var lengthValid = true
        var length: size_t = 0
        OFException.try({
            length = lengthString.decimalValue

            if length < 3 || length > 64 {
                lengthValid = false
            }
        }, catch: { (OFException) in
            lengthValid = false
        })

        guard lengthValid else {
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

        let keyFile = self.keyFile?.ofObject
        siteStorage.setSite(name, length: length,
                            legacy: legacySwitch?.isOn ?? false,
                            keyFile: keyFile)
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
