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

import ObjFW
import UIKit

class SelectKeyFileController: UITableViewController {
    public var addSiteController: AddSiteController?

    private var keyFiles: [String] = []
    private var httpServer: OFHTTPServer
    private var httpServerDelegate: HTTPServerDelegate
    private var httpServerThread: OFThread

    required init?(coder aDecoder: NSCoder) {
        httpServer = OFHTTPServer()
        httpServer.host = "127.0.0.1".ofObject

        httpServerDelegate = HTTPServerDelegate()
        httpServer.delegate = self.httpServerDelegate

        httpServerThread = OFThread()

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let documentDirectory = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true).first
        else {
            print("Could not get key files: No documents directory")
            navigationController?.popViewController(animated: true)
            return
        }

        do {
            keyFiles = try FileManager.default.contentsOfDirectory(
                atPath: documentDirectory).sorted()
        } catch let error as NSError {
            print("Could not get key files: \(error)")
            navigationController?.popViewController(animated: true)
            return
        }

        httpServerThread.start()
    }

    override func viewDidDisappear(_ animated: Bool) {
        httpServerThread.runLoop.stop()
        httpServerThread.join()
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return keyFiles.count + 1
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "keyFile") ??
            UITableViewCell(style: .default, reuseIdentifier: "keyFile")
        cell.textLabel?.text =
            indexPath.row > 0 ? keyFiles[indexPath.row - 1] : "None"
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        addSiteController?.keyFile =
            indexPath.row > 0 ? keyFiles[indexPath.row - 1] : nil
        addSiteController?.keyFileLabel?.text =
            indexPath.row > 0 ? keyFiles[indexPath.row - 1] : "None"

        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func upload(_ sender: Any?) {
        let timer = OFTimer.scheduledTimer(withTimeInterval: 0,
                                           repeats: false) { (OFTimer) in
            self.httpServer.port = 0
            self.httpServer.start()

            let message =
                "Navigate to http://\(self.httpServer.host!.nsObject):" +
                "\(self.httpServer.port)/ in your browser.\n\n" +
                "Press OK when done."
            let alert = UIAlertController(title: "Server Running",
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(title: "OK", style: .default, handler: nil))

            DispatchQueue.main.sync {
                self.present(alert, animated: true) {
                    self.httpServer.stop()
                }
            }
        }
        httpServerThread.runLoop.add(timer)
    }
}
