/*
 * Copyright (c) 2016 - 2021 Jonathan Schleifer <js@nil.im>
 *
 * https://fossil.nil.im/cryptopassphrase
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
import ObjFWBridge

class ShowDetailsController: UITableViewController, UITextFieldDelegate {
    @IBOutlet var nameField: UITextField?
    @IBOutlet var lengthField: UITextField?
    @IBOutlet var legacySwitch: UISwitch?
    @IBOutlet var keyFileField: UITextField?
    @IBOutlet var passphraseField: UITextField?
    public var mainViewController: MainViewController?

    private var name: String = ""
    private var length: UInt = 0
    private var isLegacy: Bool = false
    private var keyFile: String? = nil

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let mainViewController = self.mainViewController else { return }
        guard let tableView = mainViewController.tableView else { return }
        let siteStorage = mainViewController.siteStorage
        guard let indexPath = tableView.indexPathForSelectedRow else { return }

        name = mainViewController.sites[indexPath.row]
        length = siteStorage.length(forSite: name)
        isLegacy = siteStorage.isLegacy(site: name)
        keyFile = siteStorage.keyFile(forSite: name)

        nameField?.text = name
        lengthField?.text = "\(length)"
        legacySwitch?.isOn = isLegacy
        keyFileField?.text = keyFile

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }

    static private func clearNSMutableString(_ string: NSMutableString) {
        /*
         * NSMutableString does not offer a way to zero the string.
         * This is in the hope that setting a single character at an index just
         * replaces that character in memory, and thus allows us to zero the
         * password.
         */
        for i in 0..<string.length {
            string.replaceCharacters(in: NSRange(location: i, length: 1),
                                     with: " ")
        }
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        passphraseField?.resignFirstResponder()
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 3 {
            switch indexPath.row {
            case 0:
                self.generateAndCopy()
            case 1:
                self.generateAndShow()
            default:
                break
            }
        }
    }

    private func generateAndCopy() {
        self.generateWithCallback { (password: NSMutableString) in
            let pasteboard = UIPasteboard.general
            pasteboard.string = password as String

            ShowDetailsController.clearNSMutableString(password)

            let message = "The password has been copied into the clipboard."
            let alert = UIAlertController(title: "Password Generated",
                                          message: message,
                                          preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) {
                (UIAlertAction) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(action)

            self.present(alert, animated: true, completion: nil)
        }
    }

    private func generateAndShow() {
        self.generateWithCallback { (password: NSMutableString) in
            let alert = UIAlertController(title: "Generated Passphrase",
                                          message: password as String,
                                          preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) {
                (UIAlertAction) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(action)

            self.present(alert, animated: true) {
                ShowDetailsController.clearNSMutableString(password)
            }
        }
    }

    private func generateWithCallback(
        _ block: @escaping (_: NSMutableString) -> ()
    ) {
        let generator: PasswordGenerator = isLegacy ?
            LegacyPasswordGenerator() : NewPasswordGenerator()
        generator.site = name.ofObject
        generator.length = size_t(length)

        if let keyFile = keyFile {
            guard let documentDirectory = NSSearchPathForDirectoriesInDomains(
                .documentDirectory, .userDomainMask, true).first
            else {
                print("Could not get key files: No documents directory")
                return
            }

            let keyFilePath = documentDirectory.ofObject.appendingPathComponent(
                keyFile.ofObject)
            generator.keyFile = OFMutableData(contentsOfFile: keyFilePath)
        }

        let passphraseText = (passphraseField?.text ?? "") as NSString
        let passphraseLen = passphraseText.lengthOfBytes(
            using: String.Encoding.utf8.rawValue) + 1
        let passphrase = OFSecureData(count: passphraseLen,
                                      allowsSwappableMemory: false)
        memcpy(passphrase.mutableItems, passphraseText.utf8String!,
               passphraseLen)
        generator.passphrase = passphrase

        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let activityController = mainStoryboard.instantiateViewController(
            withIdentifier: "activityIndicator")
        navigationController?.view.addSubview(activityController.view)

        DispatchQueue.global(qos: .default).async {
            generator.derivePassword()

            let password = NSMutableString(
                bytes: generator.output.items!,
                length: generator.length,
                encoding: String.Encoding.utf8.rawValue)!

            DispatchQueue.main.sync {
                activityController.view.isHidden = true
                block(password)
            }
        }
    }

    @IBAction func remove(_ sender: Any?) {
        let message = "Do you want to remove this site?"
        let alert = UIAlertController(title: "Remove Site?",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "No", style: .cancel, handler: nil))
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) {
            (UIAlertAction) in
            self.mainViewController?.siteStorage.removeSite(self.name)
            self.mainViewController?.reset()

            self.navigationController?.popViewController(animated: true)
        }
        alert.addAction(yesAction)

        self.present(alert, animated: true, completion: nil)
    }
}
