//
//  Logger.swift
//  instaDownload
//
//  Created by 권진구 on 7/16/25.
//

import Foundation
import os

enum LogLevel: String {
    case debug   = "🐛 DEBUG"
    case info    = "ℹ️ INFO"
    case warning = "⚠️ WARNING"
    case error   = "❌ ERROR"
}

enum LogCategory: String {
    case general  = "general"
    case network  = "network"
    case database = "database"
    case auth     = "auth"
    case ui       = "ui"
    case step     = "step"
}

struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.app"
    
    private static var loggers: [LogCategory: os.Logger] = [:]
    private static func logger(for category: LogCategory) -> os.Logger {
        if let existing = loggers[category] {
            return existing
        }
        let newLogger = os.Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = newLogger
        return newLogger
    }
    
    static func log(
        _ message: String = "",
        level: LogLevel = .debug,
        category : LogCategory = .general,
        file: String = #file,
        line: Int = #line,
        function: String = #function
    ) {
        let time = "\(Date())"
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(time)] [\(level.rawValue)] [\(fileName):\(line)] [\(function)] ▶︎ \(message)"
        
        let logger = Self.logger(for: category)
        
        /**
         디버깅모드, xcode콘솔
         debug, info, warning, error
         
         consol.app
         warning, error만 보임
         */
        
        // OSLog 출력
        switch level {
        case .debug:
#if DEBUG
            logger.debug("\(logMessage)")
#endif
        case .info:
#if DEBUG
            logger.info("\(logMessage)")
#endif
        case .warning:
            logger.warning("\(logMessage)")
        case .error:
            logger.error("\(logMessage)")
        }
    }
}


extension Logger {
    static func debug(_ message: String, category: LogCategory = .general,
                      file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .debug, category: category, file: file, line: line, function: function)
    }

    static func info(_ message: String, category: LogCategory = .general,
                     file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .info, category: category, file: file, line: line, function: function)
    }

    static func warning(_ message: String, category: LogCategory = .general,
                        file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .warning, category: category, file: file, line: line, function: function)
    }

    static func error(_ message: String, category: LogCategory = .general,
                      file: String = #file, line: Int = #line, function: String = #function) {
        log(message, level: .error, category: category, file: file, line: line, function: function)
    }
}

extension Logger {
    static func printLogNetworkFailure() {
        let logSt = """
        ----------------------------------
        ---------- Network Failure -------
        ----------------------------------
"""
        Logger.error(logSt)
    }
}
