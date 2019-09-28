struct DataTablesColumn: Codable {
    let data: Int
    let name: String?
    let searchable: Bool
    let orderable: Bool
    let search: DataTablesSearch
}

struct DataTablesSearch: Codable {
    let value: String?
    let regex: Bool
}

struct DataTablesOrder: Codable {
    let column: Int
    let dir: String
}