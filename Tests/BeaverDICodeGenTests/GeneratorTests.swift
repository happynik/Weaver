//
//  GeneratorTests.swift
//  BeaverDICodeGenTests
//
//  Created by Théophane Rupin on 3/4/18.
//

import Foundation
import XCTest
import SourceKittenFramework
import PathKit

@testable import BeaverDICodeGen

final class GeneratorTests: XCTestCase {
    
    let templatePath = Path(#file).parent() + Path("../../Resources/dependency_resolver.stencil")
    
    func test_generator_should_generate_a_valid_swift_code() {
        
        do {
            let file = File(contents: """
final class MyService {
  let dependencies: DependencyResolver

  // beaverdi: api = API <- APIProtocol
  // beaverdi: api.scope = .graph
  // beaverdi: api.customRef = true

  // beaverdi: router = Router <- RouterProtocol
  // beaverdi: router.scope = .container

  // beaverdi: session = Session

  final class MyEmbeddedService {

    // beaverdi: session = Session? <- SessionProtocol?
    // beaverdi: session.scope = .container

    // beaverdi: api <- APIProtocol
  }

  init(_ dependencies: DependencyResolver) {
    self.dependencies = dependencies
  }
}

class AnotherService {
    // This class is ignored
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let syntaxTree = try parser.parse()
            
            let generator = try Generator(template: templatePath)
            let string = try generator.generate(from: syntaxTree)
            
            XCTAssertEqual(string!, """
/// This file is generated by BeaverDI
/// DO NOT EDIT!

import BeaverDI

// MARK: - MyService

final class MyServiceDependencyContainer: DependencyContainer {

    init() {
        super.init()
    }

    override func registerDependencies(in store: DependencyStore) {
        
        store.register(APIProtocol.self, scope: .graph, builder: { dependencies in
            return self.apiCustomRef(dependencies)
        })
        store.register(RouterProtocol.self, scope: .container, builder: { dependencies in
            return Router.makeRouter(injecting: dependencies)
        })
        store.register(Session.self, scope: .graph, builder: { dependencies in
            return Session.makeSession(injecting: dependencies)
        })
    }
}

protocol MyServiceDependencyResolver {
    
    var api: APIProtocol { get }
    var router: RouterProtocol { get }
    var session: Session { get }
}

extension MyServiceDependencyContainer: MyServiceDependencyResolver {
    
    var api: APIProtocol {
        return resolve(APIProtocol.self)
    }
    var router: RouterProtocol {
        return resolve(RouterProtocol.self)
    }
    var session: Session {
        return resolve(Session.self)
    }
}



// MARK: - MyEmbeddedService

final class MyEmbeddedServiceDependencyContainer: DependencyContainer {

    init(_ parent: DependencyContainer) {
        super.init(parent)
    }

    override func registerDependencies(in store: DependencyStore) {
        
        store.register(SessionProtocol?.self, scope: .container, builder: { dependencies in
            return Session.makeSession(injecting: dependencies)
        })
    }
}

protocol MyEmbeddedServiceDependencyResolver {
    
    var session: SessionProtocol? { get }
    var api: APIProtocol { get }
}

extension MyEmbeddedServiceDependencyContainer: MyEmbeddedServiceDependencyResolver {
    
    var session: SessionProtocol? {
        return resolve(SessionProtocol?.self)
    }
    var api: APIProtocol {
        return resolve(APIProtocol.self)
    }
}

extension MyService.MyEmbeddedService {

    static func makeMyEmbeddedService(injecting parentDependencies: DependencyContainer) -> MyEmbeddedService {
        let dependencies = MyEmbeddedServiceDependencyContainer(parentDependencies)
        return MyEmbeddedService(injecting: dependencies)
    }
}

""")
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func test_generator_should_return_nil_when_no_annotation_is_detected() {
        
        do {
            let file = File(contents: """
final class MyService {
  let dependencies: DependencyResolver

  init(_ dependencies: DependencyResolver) {
    self.dependencies = dependencies
  }
}
""")
            
            let lexer = Lexer(file, fileName: "test.swift")
            let tokens = try lexer.tokenize()
            let parser = Parser(tokens, fileName: "test.swift")
            let syntaxTree = try parser.parse()
            
            let generator = try Generator(template: templatePath)
            let string = try generator.generate(from: syntaxTree)
            
            XCTAssertNil(string)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
