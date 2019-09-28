import Vapor

public struct DataTablesRequest: Codable, Content {
    let draw: Int
    let columns: [DataTablesColumn]
    let order: [DataTablesOrder]
    let start: Int
    let length: Int
    let search: DataTablesSearch
}