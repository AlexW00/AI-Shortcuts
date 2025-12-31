import Foundation
import AppIntents

/// Helper for safely accessing security-scoped resources from IntentFile parameters.
/// This is required for sandboxed apps to read files from user-selected locations
/// like Desktop, Documents, or other protected directories.
enum SecurityScopedFileAccess {
    
    /// Reads data from an IntentFile with proper security-scoped resource access.
    /// - Parameter file: The IntentFile to read data from
    /// - Returns: The file's data
    /// - Throws: If the file data is empty or cannot be accessed
    static func readData(from file: IntentFile) throws -> Data {
        // Start accessing security-scoped resource if available
        let needsSecurityScope = file.fileURL?.startAccessingSecurityScopedResource() ?? false
        
        defer {
            if needsSecurityScope {
                file.fileURL?.stopAccessingSecurityScopedResource()
            }
        }
        
        // Try to get file data - first from IntentFile.data, then try reading from URL
        var data = file.data
        if data.isEmpty, let fileURL = file.fileURL {
            // Fallback: try reading directly from the URL
            data = (try? Data(contentsOf: fileURL)) ?? Data()
        }
        
        guard !data.isEmpty else {
            throw SecurityScopedFileError.emptyFile
        }
        
        return data
    }
    
    /// Reads data from multiple IntentFiles with proper security-scoped resource access.
    /// Files that cannot be accessed are skipped with a warning logged.
    /// - Parameter files: The IntentFiles to read data from
    /// - Returns: Array of tuples containing the file and its data (empty data files are filtered out)
    static func readDataFromFiles(_ files: [IntentFile]) -> [(file: IntentFile, data: Data)] {
        var results: [(file: IntentFile, data: Data)] = []
        
        for file in files {
            // Start accessing security-scoped resource if available
            let needsSecurityScope = file.fileURL?.startAccessingSecurityScopedResource() ?? false
            
            defer {
                if needsSecurityScope {
                    file.fileURL?.stopAccessingSecurityScopedResource()
                }
            }
            
            // Try to get file data - first from IntentFile.data, then try reading from URL
            var data = file.data
            if data.isEmpty, let fileURL = file.fileURL {
                // Fallback: try reading directly from the URL
                data = (try? Data(contentsOf: fileURL)) ?? Data()
            }
            
            if !data.isEmpty {
                results.append((file: file, data: data))
            }
        }
        
        return results
    }
    
    /// Processes multiple files with security-scoped access, executing a closure for each.
    /// This is useful when you need to perform operations on each file individually.
    /// - Parameters:
    ///   - files: The IntentFiles to process
    ///   - handler: A closure that processes each file and its data
    /// - Returns: Array of results from the handler
    static func processFiles<T>(_ files: [IntentFile], handler: (IntentFile, Data) throws -> T?) rethrows -> [T] {
        var results: [T] = []
        
        for file in files {
            // Start accessing security-scoped resource if available
            let needsSecurityScope = file.fileURL?.startAccessingSecurityScopedResource() ?? false
            
            defer {
                if needsSecurityScope {
                    file.fileURL?.stopAccessingSecurityScopedResource()
                }
            }
            
            // Try to get file data - first from IntentFile.data, then try reading from URL
            var data = file.data
            if data.isEmpty, let fileURL = file.fileURL {
                // Fallback: try reading directly from the URL
                data = (try? Data(contentsOf: fileURL)) ?? Data()
            }
            
            if !data.isEmpty, let result = try handler(file, data) {
                results.append(result)
            }
        }
        
        return results
    }
}

/// Errors related to security-scoped file access
enum SecurityScopedFileError: LocalizedError {
    case emptyFile
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The file is empty or could not be read."
        case .accessDenied:
            return "Access to the file was denied. Please ensure the file is accessible."
        }
    }
}
