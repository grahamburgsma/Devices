public struct iPhone: Decodable {
    public let generation: String
    public let aNumber: String
    public let bootrom: String
    public let fccID: String
    public let internalName: String
    public let identifier: String
    public let finish: String
    public let storage: String
    public let model: String
    
    enum CodingKeys: String, CodingKey {
        case generation = "Generation"
        case aNumber = "\"A\" Number"
        case bootrom = "Bootrom"
        case fccID = "FCC ID"
        case internalName = "Internal Name"
        case identifier = "Identifier"
        case finish = "Finish"
        case storage = "Storage"
        case model = "Model"
    }
}
