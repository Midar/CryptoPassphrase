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

class MainViewController: UIViewController, UISearchBarDelegate,
                          UITableViewDelegate, UITableViewDataSource {
    public var sites: [String] = []
    public var siteStorage = SiteStorage()
    @IBOutlet var searchBar: UISearchBar?
    @IBOutlet var tableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.reset()
    }

    func reset() {
        searchBar?.text = ""
        sites = siteStorage.sites(withFilter: nil)
        tableView?.reloadData()
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return sites.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "site") ??
            UITableViewCell(style: .default, reuseIdentifier: "site")
        cell.textLabel?.text = sites[indexPath.row]
        return cell
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        sites = siteStorage.sites(withFilter: searchBar.text)
        tableView?.reloadData()
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showDetails", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case .some("addSite"):
            let destination = segue.destination as? AddSiteController
            destination?.mainViewController = self
        case .some("showDetails"):
            let destination = segue.destination as? ShowDetailsController
            destination?.mainViewController = self
        default:
            break
        }
    }
}
