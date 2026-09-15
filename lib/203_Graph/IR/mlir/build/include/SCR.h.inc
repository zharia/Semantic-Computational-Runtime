/*===- TableGen'erated file -------------------------------------*- C++ -*-===*\
|*                                                                            *|
|* Dialect Declarations                                                       *|
|*                                                                            *|
|* Automatically generated file, do not edit!                                 *|
|* From: SCR.td                                                               *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

namespace scr {

/// SCR Semantic Hypergraph Dialect
/// MLIR representation of the closed SCR semantic algebra.
class SCRDialect : public ::mlir::Dialect {
  explicit SCRDialect(::mlir::MLIRContext *context);

  void initialize();
  friend class ::mlir::MLIRContext;
public:
  ~SCRDialect() override;
  static constexpr ::llvm::StringLiteral getDialectNamespace() {
    return ::llvm::StringLiteral("scr");
  }
};

} // namespace scr
MLIR_DECLARE_EXPLICIT_TYPE_ID(scr::SCRDialect)
