/// This file is generated by Weaver 0.12.2
/// DO NOT EDIT!
// MARK: - FooTest12
protocol FooTest12DependencyResolver {
    var fii: FiiTest12 { get }
}
final class FooTest12DependencyContainer: FooTest12DependencyResolver {
    private var _fii: FiiTest12?
    var fii: FiiTest12 {
        if let value = _fii { return value }
        let value = FiiTest12()
        _fii = value
        return value
    }
    init() {
        _ = fii
    }
}
// MARK: - FuuTest12
protocol FuuTest12DependencyResolver {
    var foo: FooTest12 { get }
}
final class FuuTest12DependencyContainer: FuuTest12DependencyResolver {
    private var _foo: FooTest12?
    var foo: FooTest12 {
        if let value = _foo { return value }
        let value = FooTest12(injecting: FooTest12DependencyContainer())
        _foo = value
        return value
    }
    init() {
        _ = foo
    }
}
