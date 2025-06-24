/*
 * Copyright (c) 2016 - 2024 Jonathan Schleifer <js@nil.im>
 *
 * https://git.nil.im/js/CryptoPassphrase
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
import ObjFWBridge

class SiteStorage: OFObject {
    private static let lengthField = NSNumber(value: 0)
    private static let legacyField = NSNumber(value: 1)
    private static let keyFileField = NSNumber(value: 2)

    private var IRI: OFIRI
    private var storage: [String: [NSNumber: AnyObject]]
    private var sites: [String]

    override init() {
        let fileManager = OFFileManager.default
        let userDataIRI = OFSystemInfo.userDataIRI!

        if !fileManager.directoryExists(at: userDataIRI) {
            fileManager.createDirectory(at: userDataIRI)
        }

        let IRI = userDataIRI.appendingPathComponent(
            OFString(utf8String: "sites.msgpack"))

        var storage: [String: [NSNumber: AnyObject]]? = nil
        OFException.try({
            let decoded = (OFData(contentsOf: IRI).objectByParsingMessagePack)
                as? OFDictionary<OFString, OFDictionary<OFNumber, AnyObject>>
            storage =
                (decoded?.nsObject as? [String: [NSNumber: AnyObject]]) ?? [:]
        }, catch: { (OFException) in
            storage = [:]
        })

        self.IRI = IRI
        self.storage = storage!
        self.sites = self.storage.keys.sorted()
    }

    func sites(withFilter filter: String?) -> [String] {
        return storage.keys.sorted().filter({ (name) in
            if filter == nil || filter!.isEmpty {
                return true
            }
            return name.localizedCaseInsensitiveContains(filter!)
        })
    }

    func hasSite(_ name: String) -> Bool {
        return (storage[name] != nil)
    }

    func length(forSite name: String) -> UInt {
        guard let site = storage[name] else {
            OFInvalidArgumentException().throw()
        }

        return (site[SiteStorage.lengthField] as! NSNumber).uintValue
    }

    func isLegacy(site name: String) -> Bool {
        guard let site = storage[name] else { return false }
        return (site[SiteStorage.legacyField] as! NSNumber).boolValue
    }

    func keyFile(forSite name: String) -> String? {
        guard let site = storage[name] else { return nil }

        guard let keyFile = site[SiteStorage.keyFileField], !(keyFile is NSNull)
        else {
            return nil
        }

        return keyFile as? String
    }

    func setSite(_ name: String, length: UInt, isLegacy: Bool,
                 keyFile: String?) {
        var siteDictionary: [NSNumber: AnyObject] = [
            SiteStorage.lengthField: NSNumber(value: length),
            SiteStorage.legacyField: NSNumber(value: isLegacy),
        ]
        siteDictionary[SiteStorage.keyFileField] = keyFile as AnyObject?

        storage[name] = siteDictionary
        self.update()
    }

    func removeSite(_ name: String) {
        storage[name] = nil
        self.update()
    }

    private func update() {
        let ofStorage = (storage as NSDictionary).ofObject

        ofStorage.messagePackRepresentation.write(to: IRI)
        sites = storage.keys.sorted()
    }
}
