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

import ObjFW
import ObjFWBridge

class SiteStorage: OFObject {
    private static let lengthField = NSNumber(value: 0)
    private static let legacyField = NSNumber(value: 1)
    private static let keyFileField = NSNumber(value: 2)

    private var path: OFString
    private var storage: [String: [NSNumber: AnyObject]]
    private var sites: [String]

    override init() {
        let fileManager = OFFileManager.default
        let userDataPath = OFSystemInfo.userDataPath!

        if !fileManager.directoryExists(atPath: userDataPath) {
            fileManager.createDirectory(atPath: userDataPath)
        }

        let path = userDataPath.appendingPathComponent(
            OFString(utf8String: "sites.msgpack"))

        var storage: [String: [NSNumber: AnyObject]]? = nil
        OFException.try({
            let decoded = (OFData(contentsOfFile: path)
                .objectByParsingMessagePack)
                as? OFDictionary<OFString, OFDictionary<OFNumber, AnyObject>>
            storage =
                (decoded?.nsObject as? [String: [NSNumber: AnyObject]]) ?? [:]
        }, catch: { (OFException) in
            storage = [:]
        })

        self.path = path
        self.storage = storage!
        self.sites = self.storage.keys.sorted()
    }

    func sites(withFilter filter: String?) -> [String] {
        return storage.keys.sorted().filter({ (name) in
            if let filter = filter {
                return name.localizedCaseInsensitiveContains(filter)
            }
            return true
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

        ofStorage.messagePackRepresentation.write(toFile: path)
        sites = storage.keys.sorted()
    }
}
