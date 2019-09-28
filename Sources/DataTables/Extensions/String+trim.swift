import Foundation

extension String {    
    func trim() -> String { 
        return self.trimmingCharacters(in: NSCharacterSet.whitespaces) 
    } 
}