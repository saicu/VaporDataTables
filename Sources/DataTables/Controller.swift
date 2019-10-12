import Vapor
import Fluent
import SQL

struct DataTablesController<ModelType: Model> where ModelType.Database.QueryFilterMethod: SQLBinaryOperator {
    let modelType: ModelType.Type
    let keyPaths: [AnyKeyPath]
    let formatter: DateFormatter

    init(_ modelType: ModelType.Type, keyPaths: [AnyKeyPath]) {
        self.modelType = modelType
        self.keyPaths = keyPaths
        self.formatter = DateFormatter()
    }

    init(_ modelType: ModelType.Type, keyPaths: [AnyKeyPath], dateFormatter: DateFormatter) {
        self.modelType = modelType
        self.keyPaths = keyPaths
        self.formatter = dateFormatter
    }

    public func dataTablesHandler(_ req: Request, dataTablesRequest: DataTablesRequest) -> Future<DataTablesResponse> {
        var sortOrder: ModelType.Database.QuerySortDirection = ModelType.Database.querySortDirectionAscending
        var sort: ModelType.Database.QuerySort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(ModelType.idKey)), sortOrder)
        let range = dataTablesRequest.start >= 0 && dataTablesRequest.start < dataTablesRequest.start+dataTablesRequest.length ? dataTablesRequest.start..<dataTablesRequest.start+dataTablesRequest.length : 0..<10

        if !dataTablesRequest.order.isEmpty && dataTablesRequest.order[0].dir == "desc" {
            sortOrder = ModelType.Database.querySortDirectionDescending
        }

        if self.keyPaths.count >= dataTablesRequest.order[0].column {
            switch (self.keyPaths[dataTablesRequest.order[0].column]) {
                case let path as KeyPath<ModelType, String>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, String?>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Int>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Int?>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Double>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Double?>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Float>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Float?>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Bool>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Bool?>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Date>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                case let path as KeyPath<ModelType, Date?>:
                    sort = ModelType.Database.querySort(ModelType.Database.queryField(.keyPath(path)), sortOrder)
                    break;
                default:
                    break;
            }
        }

        var filterSearch = false
        var query = ModelType.query(on: req)

        // apply filters
        for column in dataTablesRequest.columns {
            if let searchData = column.search.value, searchData != "" {
                filterSearch = true
                query = self.applyFilter(at: column.data, query: query, searchData: searchData, range: true)    
            }
        }
        
        if filterSearch {  // when filtering
            let qCopy = query.copy()
            return map(query.sort(sort).range(range).all(), ModelType.query(on: req).count(), qCopy.count()) { queryData, queryCount, querySearchCount -> DataTablesResponse in
                return DataTablesResponse(
                    sEcho: dataTablesRequest.draw,
                    iTotalRecords: queryCount,
                    iTotalDisplayRecords: querySearchCount,
                    aaData: self.mapKeyPathsToString(queryData)
                )
            }
        } else if !filterSearch, let searchData = dataTablesRequest.search.value, searchData != "" { // when searching
            // apply search
            query = query.group(ModelType.Database.queryFilterRelationOr) { q in
                for (i, _) in self.keyPaths.enumerated() {
                    _ = self.applyFilter(at: i, query: q, searchData: searchData)
                } 
            }

            let qCopy = query.copy()
            return map(
                query.sort(sort).range(range).all(), 
                ModelType.query(on: req).count(), 
                qCopy.count()
            ) { queryData, queryCount, querySearchCount -> DataTablesResponse in
                return DataTablesResponse(
                    sEcho: dataTablesRequest.draw,
                    iTotalRecords: queryCount,
                    iTotalDisplayRecords: querySearchCount,
                    aaData: self.mapKeyPathsToString(queryData)
                )
            }

        } else { // without filter/search
            return map(query.sort(sort).range(range).all(), ModelType.query(on: req).count()) { queryData, queryCount -> DataTablesResponse in
                return DataTablesResponse(
                    sEcho: dataTablesRequest.draw,
                    iTotalRecords: queryCount,
                    iTotalDisplayRecords: queryCount,
                    aaData: self.mapKeyPathsToString(queryData)
                )
            }
        }
    }

}

private extension DataTablesController {
    private func mapKeyPathsToString<ModelType: Model>(_ modelData: [ModelType]) -> [[String]] {
        return modelData.map { data in
            var stringData: [String] = []
            for key in self.keyPaths {
                if let value = data[keyPath: key] {
                    if let optionalValue = value as? OptionalProtocol {
                        if optionalValue.isSome() {
                            stringData.append("\(optionalValue.unwrap() is Date ? self.formatter.string(from: optionalValue.unwrap() as! Date) : optionalValue.unwrap())")
                        } else {
                            stringData.append("")
                        }
                    } else {
                        stringData.append("\(value is Date ? self.formatter.string(from: value as! Date) : value)")
                    }
                }
            }
            return stringData
        }
    }

    private func applyFilter(at index: Int, query: QueryBuilder<ModelType.Database, ModelType>, searchData: String, range: Bool = false) -> QueryBuilder<ModelType.Database, ModelType> {
        guard self.keyPaths.count >= index else {
            return query
        }

        let searchRange: [String] = range ? searchData.split(separator: "-").map { return String($0).trim() } : []

        switch (self.keyPaths[index]) {
            case let path as KeyPath<ModelType, String>:
                return query.filter(path, ModelType.Database.QueryFilterMethod.like, searchData)
            case let path as KeyPath<ModelType, String?>:
                return query.filter(path, ModelType.Database.QueryFilterMethod.like, searchData)

            case let path as KeyPath<ModelType, Int>:
                if searchRange.count == 2 {
                    if let searchStart = Int(searchRange[0]), let searchEnd = Int(searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = Int(searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query
            case let path as KeyPath<ModelType, Int?>:
                if searchRange.count == 2 {
                    if let searchStart = Int(searchRange[0]), let searchEnd = Int(searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = Int(searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query

            case let path as KeyPath<ModelType, Double>:
                if searchRange.count == 2 {
                    if let searchStart = Double(searchRange[0]), let searchEnd = Double(searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = Double(searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query
            case let path as KeyPath<ModelType, Double?>:
                if searchRange.count == 2 {
                    if let searchStart = Double(searchRange[0]), let searchEnd = Double(searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = Double(searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query
            
            case let path as KeyPath<ModelType, Float>:
                if searchRange.count == 2 {
                    if let searchStart = Float(searchRange[0]), let searchEnd = Float(searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = Float(searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query
            case let path as KeyPath<ModelType, Float?>:
                if searchRange.count == 2 {
                    if let searchStart = Float(searchRange[0]), let searchEnd = Float(searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = Float(searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query

            case let path as KeyPath<ModelType, Bool>:
                if let searchData = Bool(searchData) {
                    query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                }
                return query
            case let path as KeyPath<ModelType, Bool?>:
                if let searchData = Bool(searchData) {
                    query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                }
                return query

            case let path as KeyPath<ModelType, Date>:
                if searchRange.count == 2 {
                    if let searchStart = self.formatter.date(from: searchRange[0]), let searchEnd = self.formatter.date(from: searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = self.formatter.date(from: searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query
            case let path as KeyPath<ModelType, Date?>:
                if searchRange.count == 2 {
                    if let searchStart = self.formatter.date(from: searchRange[0]), let searchEnd = self.formatter.date(from: searchRange[1]) {
                        query.filter(path, ModelType.Database.queryFilterMethodGreaterThanOrEqual, searchStart).filter(path, ModelType.Database.queryFilterMethodLessThanOrEqual, searchEnd)
                    }
                } else {
                    if let searchData = self.formatter.date(from: searchData) {
                        query.filter(path, ModelType.Database.queryFilterMethodEqual, searchData)
                    }
                }
                return query
            default:
                return query
        }
    }
}