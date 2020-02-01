//
//  Configuration.swift
//  WeaverCommand
//
//  Created by Théophane Rupin on 2/4/19.
//

import Foundation
import PathKit
import Yams
import ShellOut
import WeaverCodeGen

// MARK: - Configuration

struct Configuration {
    
    let projectPath: Path
    let mainOutputPath: Path
    let testsOutputPath: Path
    let inputPathStrings: [String]
    let ignoredPathStrings: [String]
    let cachePath: Path
    let recursiveOff: Bool
    let tests: Bool
    let testableImports: [String]?
    
    private init(inputPathStrings: [String]?,
                 ignoredPathStrings: [String]?,
                 projectPath: Path?,
                 mainOutputPath: Path?,
                 testsOutputPath: Path?,
                 cachePath: Path?,
                 recursiveOff: Bool?,
                 tests: Bool?,
                 testableImports: [String]?) {

        self.inputPathStrings = inputPathStrings ?? Defaults.inputPathStrings
        self.ignoredPathStrings = ignoredPathStrings ?? []

        let projectPath = projectPath ?? Defaults.projectPath
        self.projectPath = projectPath

        self.mainOutputPath = mainOutputPath
            .map { $0.isFile ? $0 : $0 + Defaults.mainOutputFileName }
            .map { $0.isRelative ? projectPath + $0 : $0 } ?? Defaults.mainOutputPath
        self.testsOutputPath = testsOutputPath
            .map { $0.isFile ? $0 : $0 + Defaults.testOutputFileName }
            .map { $0.isRelative ? projectPath + $0 : $0 } ?? Defaults.testsOutputPath

        self.cachePath = cachePath ?? Defaults.cachePath
        self.recursiveOff = recursiveOff ?? Defaults.recursiveOff
        self.tests = tests ?? Defaults.tests
        self.testableImports = testableImports
    }
    
    init(configPath: Path? = nil,
         inputPathStrings: [String]? = nil,
         ignoredPathStrings: [String]? = nil,
         projectPath: Path? = nil,
         mainOutputPath: Path? = nil,
         testsOutputPath: Path? = nil,
         cachePath: Path? = nil,
         recursiveOff: Bool? = nil,
         tests: Bool? = nil,
         testableImports: [String]? = nil) throws {
        
        let projectPath = projectPath ?? Defaults.projectPath
        let configPath = Configuration.prepareConfigPath(configPath ?? Defaults.configPath, projectPath: projectPath)
        let cachePath = Configuration.prepareCachePath(cachePath ?? Defaults.cachePath, projectPath: projectPath)
        
        var configuration: Configuration
        switch (configPath.extension, configPath.isFile) {
        case ("json"?, true):
            let jsonDecoder = JSONDecoder()
            configuration = try jsonDecoder.decode(Configuration.self, from: try configPath.read())
        case ("yaml"?, true):
            let yamlDecoder = YAMLDecoder()
            configuration = try yamlDecoder.decode(Configuration.self, from: try configPath.read(), userInfo: [:])
        default:
            configuration = Configuration(inputPathStrings: inputPathStrings,
                                          ignoredPathStrings: ignoredPathStrings,
                                          projectPath: projectPath,
                                          mainOutputPath: mainOutputPath,
                                          testsOutputPath: testsOutputPath,
                                          cachePath: cachePath,
                                          recursiveOff: recursiveOff,
                                          tests: tests,
                                          testableImports: testableImports)
        }
        
        self.inputPathStrings = inputPathStrings ?? configuration.inputPathStrings
        self.ignoredPathStrings = ignoredPathStrings ?? configuration.ignoredPathStrings
        self.projectPath = projectPath
        self.mainOutputPath = mainOutputPath ?? configuration.mainOutputPath
        self.testsOutputPath = testsOutputPath ?? configuration.testsOutputPath
        self.cachePath = cachePath
        self.recursiveOff = recursiveOff ?? configuration.recursiveOff
        self.tests = tests ?? configuration.tests
        self.testableImports = testableImports ?? configuration.testableImports
    }
    
    private static func prepareConfigPath(_ configPath: Path, projectPath: Path) -> Path {
        let configPath = configPath.isRelative ? projectPath + configPath : configPath
        if configPath.isDirectory {
            if (configPath + Defaults.configJSONFile).isFile {
                return configPath + Defaults.configJSONFile
            } else if (configPath + Defaults.configYAMLFile).isFile {
                return configPath + Defaults.configYAMLFile
            }
        }
        return configPath
    }
    
    private static func prepareCachePath(_ cachePath: Path, projectPath: Path) -> Path {
        return cachePath.isRelative ? projectPath + cachePath : cachePath
    }
    
    private var recursive: Bool {
        return recursiveOff == false
    }
}

// MARK: - Constants

extension Configuration {

    enum Defaults {
        static let configPath = Path(".")
        static let configYAMLFile = Path(".weaver.yaml")
        static let configJSONFile = Path(".weaver.json")
        static let mainOutputFileName = Path("Weaver.swift")
        static let mainOutputPath = Path(".") + mainOutputFileName
        static let testOutputFileName = Path("Weaver.swift")
        static let testsOutputPath = Path(".") + testOutputFileName
        static let cachePath = Path(".weaver_cache.json")
        static let recursiveOff = false
        static let inputPathStrings = ["."]
        static let detailedResolvers = false
        static let tests = false
        
        static var projectPath: Path {
            if let projectPath = ProcessInfo.processInfo.environment["WEAVER_PROJECT_PATH"] {
                return Path(projectPath)
            } else {
                return Path(".")
            }
        }
    }
}

// MARK: - Decodable

extension Configuration: Decodable {

    private enum Keys: String, CodingKey {
        case projectPath = "project_path"
        case mainOutputPath = "main_output_path"
        case testsOutputPath = "tests_output_path"
        case inputPaths = "input_paths"
        case ignoredPaths = "ignored_paths"
        case recursive
        case tests
        case testableImports = "testable_imports"
        case cachePath = "cache_path"
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        if container.contains(.projectPath) {
            Logger.log(.error, "\(Keys.projectPath.rawValue) cannot be overriden in the configuration file.")
        }
        
        projectPath = Defaults.projectPath
        mainOutputPath = try container.decodeIfPresent(Path.self, forKey: .mainOutputPath) ?? Defaults.mainOutputPath
        testsOutputPath = try container.decodeIfPresent(Path.self, forKey: .testsOutputPath) ?? Defaults.testsOutputPath
        inputPathStrings = try container.decodeIfPresent([String].self, forKey: .inputPaths) ?? Defaults.inputPathStrings
        ignoredPathStrings = try container.decodeIfPresent([String].self, forKey: .ignoredPaths) ?? []
        recursiveOff = !(try container.decodeIfPresent(Bool.self, forKey: .recursive) ?? !Defaults.recursiveOff)
        tests = try container.decodeIfPresent(Bool.self, forKey: .tests) ?? Defaults.tests
        testableImports = try container.decodeIfPresent([String].self, forKey: .testableImports)
        cachePath = try container.decodeIfPresent(Path.self, forKey: .cachePath) ?? Defaults.cachePath
    }
}

extension Path: Decodable {
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode(String.self))
    }
}

// MARK: - Utils

extension Configuration {
    
    private static let annotationRegex = "\\/\\/[[:space:]]*\(TokenBuilder.annotationRegexString)"
    private static let propertyWrapperRegex = "\"@\\w*Weaver\""
    
    func inputPaths() throws -> [Path]  {
        var inputPaths = Set<Path>()

        let inputDirectories = Set(inputPathStrings
            .lazy
            .map { self.projectPath + $0 }
            .filter { $0.exists && $0.isDirectory }
            .map { $0.absolute().string })

        if inputDirectories.isEmpty == false {
            let grepArguments = ["-lR", "-e", Configuration.annotationRegex, "-e", Configuration.propertyWrapperRegex] + Array(inputDirectories)
            inputPaths.formUnion(try shellOut(to: "grep", arguments: grepArguments)
                .split(separator: "\n")
                .lazy
                .map { Path(String($0)) }
                .filter { $0.extension == "swift" })
        }
        
        inputPaths.formUnion(inputPathStrings
            .lazy
            .map { self.projectPath + $0 }
            .filter { $0.exists && $0.isFile && $0.extension == "swift" })

        inputPaths.subtract(try ignoredPathStrings
            .lazy
            .map { self.projectPath + $0 }
            .flatMap { $0.isFile ? [$0] : recursive ? try $0.recursiveChildren() : try $0.children() }
            .filter { $0.extension == "swift" })
        
        return inputPaths.sorted()
    }
}
