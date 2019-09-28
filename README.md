# VaporDataTables 

<a href="https://github.com/vapor/vapor">
    <img src="https://img.shields.io/badge/vapor-3.x-brightgreen.svg" alt="Vapor 3.x">
</a>

<a href="https://swift.org">
    <img src="http://img.shields.io/badge/swift-5.x-brightgreen.svg" alt="Swift 5.x">
</a>

## Features

Generate AJAX endpoints for populating [DataTables](https://datatables.net/) from your Fluent models with one line of code.


| Feature | Status | Notes |
|---------|:------:|-------|
| Easy Setup through Fluent Model | ✅ | Postgres, MySQL, SQLite |
| Sorting | ✅ | |
| Pagination | ✅ | |
| Search | ✅ | Use % as wildcard |
| Filtering | ✅ | Use % as wildcard, x-y for range (see screenshot below) |
| Joins | ❌ | Joining other Models |


## Installation

### package.swift

```swift
dependencies: [
    .package(url: "https://github.com/saicu/VaporDataTables.git", from: "1.0.0")
]
```

and

```swift
targets: [
    target(name: "App", dependencies: ["DataTables"])
]

```

Configure your `package.swift` to use VaporDataTables.


## Usage

### routes.swift (or similar, eg RouteCollection)
```swift
import Vapor
import DataTables

public func routes(_ router: Router) throws {
    router.dataTables(Todo.self, expose: [\Todo.id, \Todo.title], at: "todos", "dataTables")
}

```
This creates a route for the model *Todo* at `/todos/dataTables`.

Expose propertys of your model by passing their **KeyPath**s in the **same order** as the HTML table columns.

You can also pass a DateFormatter for custom display/filtering of your dates. 
```swift
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd"
router.dataTables(Todo.self, expose: [\Todo.id, \Todo.title], dateFormatter: dateFormatter, at: "todos", "dataTables")
```

### index.html
```html
<!DOCTYPE html>
<html>
    <head>
        <title>DataTables Example</title>
        <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css">
    </head>
    <body>
        <table id="myTable">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Title</th>
                </tr>
            </thead>
            <tfoot>
                <tr>
                    <th>ID</th>
                    <th>Title</th>
                </tr>
            </tfoot>
        </table>

        <script type="text/javascript" src="https://code.jquery.com/jquery-3.4.1.min.js"></script>
        <script type="text/javascript" src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js"></script>
        <script>
            let config = {
                "processing": true,
                "serverSide": true,
                "ajax": {
                    "url": "/todos/dataTables", // change this to your new url
                    "type": "POST",
                    "contentType": "application/json",
                    "data": function(d) {
                        return JSON.stringify(d);
                    }
                }
            };

            var table = $('#myTable').DataTable(config);

            // optional: add filter input to each column, connect their event
            $('#myTable tfoot th').each(function () {
                var title = $(this).text();
                $(this).html( '<input type="text" style="width: 100%" placeholder="Filter '+title+'" />' );
            });

            table.columns().every( function () {
                var self = this;

                $( 'input', this.footer() ).on( 'keyup change clear', function () {
                    if ( self.search() !== this.value ) {
                        self
                            .search( this.value )
                            .draw();
                    }
                });
            });
        </script>
    </body>
</html>
```
You'll need to configure DataTables to make a *POST request in JSON format*, see the example config in the script part above (don't forget to change the url).


### Success

Voilá, your server-side proccessed table with sorting, filtering, pagination and full-text search is all set up.

![alt text](https://github.com/saicu/VaporDataTables/raw/master/Img/screen.png "Screenshot")
