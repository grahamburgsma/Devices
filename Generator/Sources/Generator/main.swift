import Foundation
import SwiftSoup
import Slab
import Devices

// TODO: Retrieve image from Frames?
// TODO: Get content from wikipedia?
// TODO: Flag to generate from local file
// TODO: Pass mocks to generator

private struct Generator {
    
    private let slab = Slab()
    private let decoder = JSONDecoder()
    private let currentDirectory = URL(fileURLWithPath: #file, isDirectory: false).deletingLastPathComponent()
    
    func generate() throws {

        let newLocation = URL(string: "https://www.theiphonewiki.com/wiki/Models")!
        log("Downloading latest data from \(newLocation)")
        let newString = try String(contentsOf: newLocation, encoding: .utf8)
        let newDocument = try SwiftSoup.parse(newString)
        let newTables = try newDocument.getElementsByTag("table")
        
        let storedLocation = Bundle.module.resourceURL!.appendingPathComponent("Models - The iPhone Wiki.html")
        if FileManager.default.fileExists(atPath: storedLocation.path) {
            let storedString = try String(contentsOf: storedLocation, encoding: .utf8)
            let storedDocument = try SwiftSoup.parse(storedString)
            let storedTables = try storedDocument.getElementsByTag("table")
            
            guard try newTables.outerHtml() != storedTables.outerHtml() else {
                return log("No changes detected since last download")
            }
        }
        
        var output =
        """
        // Generated on \(Date())
        // Manual modifications will be overwitten.
        """
        
        try write(to: &output, from: newTables, at: 1, for: Airpod.self)
        try write(to: &output, from: newTables, at: 2, for: Airtag.self)
        try write(to: &output, from: newTables, at: 3, for: AppleTV.self)
        try write(to: &output, from: newTables, at: 4, for: SiriRemote.self)
        try write(to: &output, from: newTables, at: 5, for: AppleWatch.self)
        try write(to: &output, from: newTables, at: 6, for: HomePod.self)
        try write(to: &output, from: newTables, at: 7, for: iPad.self)
        try write(to: &output, from: newTables, at: 8, for: ApplePencil.self)
        try write(to: &output, from: newTables, at: 9, for: SmartKeyboard.self)
        try write(to: &output, from: newTables, at: 10, for: iPadAir.self)
        try write(to: &output, from: newTables, at: 11, for: iPadPro.self)
        try write(to: &output, from: newTables, at: 12, for: iPadMini.self)
        try write(to: &output, from: newTables, at: 13, for: iPhone.self)
        try write(to: &output, from: newTables, at: 14, for: iPodTouch.self)
        try write(to: &output, from: newTables, at: 15, for: iMac.self)
        try write(to: &output, from: newTables, at: 16, for: MacMini.self)
        try write(to: &output, from: newTables, at: 17, for: MacBookAir.self)
        try write(to: &output, from: newTables, at: 18, for: MacBookPro.self)
        
        try persist(output)
        try persistWiki(newString)
    }

    private func write<T: Decodable>(to string: inout String, from tables: Elements, at index: Int, for type: T.Type) throws {
        
        log("Parsing \(type)")
        
        let array = try slab.convert(
            tables[index].outerHtml(),
            configuration:
                    .init(
                        modify: { element, row, col in
                            try element.select("sup").remove()
                            return element
                        }
                    )
        )
        let data = try JSONSerialization.data(withJSONObject: array, options: [])
        let objects = try decoder.decode([T].self, from: data)
        
        string.append(
        """
        
        
        public extension \(type) {
            static var all: [\(type)] {
                [
        \(try {
            try objects.map { "\t\t\t\(try encode($0))" }.joined(separator: ",\n")
        }())
                ]
            }
        }
        """
        )
    }
    
    private func persistWiki(_ string: String) throws {
        log("Saving `Models - The iPhone Wiki.html`")
        let ouputDirectory = currentDirectory.appendingPathComponent("Resources/Models - The iPhone Wiki.html")
        let data = string.data(using: .utf8)!
        try data.write(to: ouputDirectory)
    }
    
    private func persist(_ string: String) throws {
        log("Saving `Devices.swift`")
        let ouputDirectory = currentDirectory.appendingPathComponent("../../../Sources/Devices/Devices.swift")
        let data = string.data(using: .utf8)!
        try data.write(to: ouputDirectory)
    }

    private func encode(_ object: Any) throws -> String {
        let airpod = Mirror(reflecting: object)
        let params = try airpod.children.map { child in
            let value: String = try {
                switch child.value {
                case let array as [String]: return "[\(array.map { "\"\($0)\"" }.joined(separator: ", "))]"
                case let string as String: return "\"\(string)\""
                default: throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown type found during encoding"])
                }
            }()
            return "\(child.label!): \(value)"
        }
            .joined(separator: ", ")

        return ".init(\(params))"
    }
}

func log(_ string: String) {
    print("Devices Generator: \(string)")
}

//func main(args: [String]) throws {
//}
//    try main(args: CommandLine.arguments)

do {
    log("Started")
    try Generator().generate()
    log("Finished")
    exit(EXIT_SUCCESS)
} catch {
    log("ERROR - \(error.localizedDescription)")
    exit(EXIT_FAILURE)
}
RunLoop.main.run()
