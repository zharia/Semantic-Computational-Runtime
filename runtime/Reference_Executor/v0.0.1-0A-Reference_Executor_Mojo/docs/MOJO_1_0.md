# Mojo 1.0 Compatibility Notes

0A targets Mojo 1.0.0.

Important 1.0 changes reflected in this project:

- `fn` is not used; functions and methods use `def`.
- Variables explicitly use `var`.
- `Copyable` means explicitly copyable.
- `ImplicitlyCopyable` is an opt-in marker.
- Collection types such as `Dict` are explicitly copied with `.copy()`.
- Ownership transfer uses `^`.
- `__deinit__` is the current destructor spelling.
- Imports are explicit.
- Package modules use explicit relative imports.
- `String`/`List`/`Dict` use the current 1.0 APIs.
- Mojo's native `std.testing` framework is used for tests.
