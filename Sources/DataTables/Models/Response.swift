import Vapor

public struct DataTablesResponse: Codable, Content {
    var sEcho, iTotalRecords, iTotalDisplayRecords: Int
    var aaData: [[String]]
}