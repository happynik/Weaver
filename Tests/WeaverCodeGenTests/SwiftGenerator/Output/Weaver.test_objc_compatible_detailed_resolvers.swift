import Foundation

/// This file is generated by Weaver 0.12.4
/// DO NOT EDIT!

// MARK: - FooTest20

typealias FooTest20DependencyResolver = FuuTest20Resolver

@objc final class FooTest20DependencyContainer: NSObject, FooTest20DependencyResolver {

    private var _fuu: Optional<FuuTest20> = nil
    var fuu: FuuTest20 {
        if let value: FuuTest20 = _fuu {
            return value
        }
        let value: FuuTest20 = FuuTest20()
        _fuu = value
        return value
    }

    override init() {
        super.init()
        _ = fuu
    }
}

protocol FooTest20ObjCDependencyInjectable: AnyObject {
}

