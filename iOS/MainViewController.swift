/*
 * Copyright (c) 2016 - 2024 Jonathan Schleifer <js@nil.im>
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
