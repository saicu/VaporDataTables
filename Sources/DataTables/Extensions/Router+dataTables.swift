import Vapor
import Fluent
import SQL

public extension Router {
    func dataTables<ModelType: Model>(
        _ type: ModelType.Type,
        expose keyPaths: [AnyKeyPath],
        at path: PathComponentsRepresentable...
    ) where ModelType.Database.QueryFilterMethod: SQLBinaryOperator {
        let controller = DataTablesController(type, keyPaths: keyPaths)
        self.post(DataTablesRequest.self, at: path, use: controller.dataTablesHandler)
    }

    func dataTables<ModelType: Model>(
        _ type: ModelType.Type,
        expose keyPaths: [AnyKeyPath],
        dateFormatter: DateFormatter,
        at path: PathComponentsRepresentable...
    ) where ModelType.Database.QueryFilterMethod: SQLBinaryOperator {
        let controller = DataTablesController(type, keyPaths: keyPaths, dateFormatter: dateFormatter)
        self.post(DataTablesRequest.self, at: path, use: controller.dataTablesHandler)
    }
}