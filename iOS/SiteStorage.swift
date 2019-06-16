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
import ObjFW_Bridge

class SiteStorage: OFObject {
    private typealias Storage =
        OFMutableDictionary<OFString, OFDictionary<OFNumber, AnyObject>>

    private static let lengthField = OFNumber(uInt8: 0)
    private static let legacyField = OFNumber(uInt8: 1)
    private static let keyFileField = OFNumber(uInt8: 2)

    private var path: OFString
    private var storage: Storage
    private var sites: OFArray<OFString>

    override init() {
        let fileManager = OFFileManager.default
        let userDataPath = OFSystemInfo.userDataPath!

        if !fileManager.directoryExists(atPath: userDataPath) {
            fileManager.createDirectory(atPath: userDataPath)
        }

        let path = userDataPath.appendingPathComponent(
            OFString(utf8String: "sites.msgpack"))
        var storage: Storage? = nil
        OFException.try({
            storage = OFData(contentsOfFile: path).messagePackValue as? Storage
        }, catch: { (OFException) in
            storage = OFMutableDictionary()
        })

        self.path = path
        self.storage = storage!
        self.sites = self.storage.allKeys.sorted
    }

    func sites(withFilter filter: OFString?) -> OFArray<OFString> {
        // FIXME: We need case folding here, but there is no method for it yet.
        let filter = filter?.lowercase

        return storage.allKeys.sorted.filteredArray({
            (name: Any, index: size_t) -> Bool in
            if filter == nil {
                return true
            }

            let name = name as! OFString
            return name.lowercase.contains(filter!)
        })
    }

    func hasSite(_ name: OFString) -> Bool {
        return (storage[name] != nil)
    }

    func length(forSite name: OFString) -> size_t {
        guard let site = storage[name] else {
            OFInvalidArgumentException().throw()
            abort()
        }

        return (site[SiteStorage.lengthField] as! OFNumber).sizeValue
    }

    func isLegacy(site name: OFString) -> Bool {
        guard let site = storage[name] else {
            OFInvalidArgumentException().throw()
            abort()
        }

        return (site[SiteStorage.legacyField] as! OFNumber).boolValue
    }

    func keyFile(forSite name: OFString) -> OFString? {
        guard let site = storage[name] else {
            OFInvalidArgumentException().throw()
            abort()
        }

        let keyFile = site[SiteStorage.keyFileField]
        if keyFile is OFNull {
            return nil
        }

        return keyFile as? OFString
    }

    func setSite(_ name: OFString, length: size_t, legacy: Bool,
                 keyFile: OFString?) {
        let siteDictionary = OFMutableDictionary<OFNumber, AnyObject>()

        siteDictionary.setObject(OFNumber(size: length),
                                 forKey: SiteStorage.lengthField)
        siteDictionary.setObject(OFNumber(bool: legacy),
                                 forKey: SiteStorage.legacyField)
        if keyFile != nil {
            siteDictionary.setObject(keyFile!, forKey: SiteStorage.keyFileField)
        }

        siteDictionary.makeImmutable()
        storage.setObject(siteDictionary, forKey: name)

        self.update()
    }

    func removeSite(_ name: OFString) {
        self.storage.removeObject(forKey: name)
        self.update()
    }

    private func update() {
        storage.messagePackRepresentation.write(toFile: path)
        sites = storage.allKeys.sorted
    }
}
