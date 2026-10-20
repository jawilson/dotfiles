// Pins two directories in the Finder sidebar's Favorites: `--first PATH` goes at the top
// and `--last PATH` at the bottom. An entry already in place is left alone; one that is
// elsewhere in the list is moved. The LSSharedFileList API is deprecated, but it is the
// only scriptable interface to the sidebar. Compile it with swiftc; `swift` crashes when
// it interprets this file.
import CoreServices
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("finder-favorites: \(message)\n".utf8))
    exit(1)
}

let arguments = CommandLine.arguments
guard arguments.count == 5, arguments[1] == "--first", arguments[3] == "--last" else {
    fail("usage: finder-favorites --first PATH --last PATH")
}
func directoryURL(_ path: String) -> URL {
    URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL
}

guard let list = LSSharedFileListCreate(nil, kLSSharedFileListFavoriteItems.takeUnretainedValue(), nil)?.takeRetainedValue() else {
    fail("cannot open the Finder favorites list")
}

func favorites() -> [(item: LSSharedFileListItem, path: String)] {
    var seed: UInt32 = 0
    guard let snapshot = LSSharedFileListCopySnapshot(list, &seed)?.takeRetainedValue() as? [LSSharedFileListItem] else {
        fail("cannot read the Finder favorites list")
    }
    // Never prompt or mount a volume for a server favorite: this runs unattended.
    let flags = UInt32(kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes)
    return snapshot.map { item in
        let url = LSSharedFileListItemCopyResolvedURL(item, flags, nil)?.takeRetainedValue() as URL?
        return (item, url?.standardizedFileURL.path ?? "")
    }
}

// Puts `url` at the top or bottom unless it is already there. An old copy is removed first:
// inserting a URL that is already listed and then removing the old item deletes both.
// BeforeFirst cannot insert into an empty list, where Last is equivalent.
// BeforeFirst and Last are sentinel pointers, not objects: retaining them, as
// takeUnretainedValue() does, crashes. Borrow them without a retain instead.
func pin(_ url: URL, atTop: Bool) {
    let current = favorites()
    if (atTop ? current.first : current.last)?.path == url.path { return }
    for entry in current where entry.path == url.path {
        if LSSharedFileListItemRemove(list, entry.item) != noErr { fail("cannot move \(url.path)") }
    }
    let isEmpty = current.allSatisfy { $0.path == url.path }
    let anchor = atTop && !isEmpty ? kLSSharedFileListItemBeforeFirst : kLSSharedFileListItemLast
    let item = anchor._withUnsafeGuaranteedRef {
        LSSharedFileListInsertItemURL(list, $0, nil, nil, url as CFURL, nil, nil)
    }
    if item == nil { fail("cannot add \(url.path)") }
    print("finder-favorites: pinned \(url.path) at the \(atTop ? "top" : "bottom")")
}

pin(directoryURL(arguments[2]), atTop: true)
pin(directoryURL(arguments[4]), atTop: false)
