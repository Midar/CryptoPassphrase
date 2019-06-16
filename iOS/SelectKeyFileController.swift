/*
 * Copyright (c) 2016 - 2019 Jonathan Schleifer <js@heap.zone>
 *
 * https://heap.zone/git/scrypt-pwgen.git
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

    deinit {
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
