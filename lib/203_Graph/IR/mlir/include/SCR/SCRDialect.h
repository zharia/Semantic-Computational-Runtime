//===- SCRDialect.h - SCR Dialect Declaration -*- C++ -*-===//
//
// Dialect class declaration for the SCR Semantic Hypergraph dialect.
// Manually defined (not ODS-generated) to support type parsing/printing.
//
//===-----------------------------------------------------===//

#ifndef SCR_DIALECT_H
#define SCR_DIALECT_H

#include "SCR/SCROps.h"
#include <memory>

namespace mlir { class Pass; }

namespace scr {

class SCRDialect : public ::mlir::Dialect {
public:
  explicit SCRDialect(::mlir::MLIRContext *context);
  ~SCRDialect() override;

  static constexpr ::llvm::StringLiteral getDialectNamespace() {
    return ::llvm::StringLiteral("scr");
  }

  void initialize();

  ::mlir::Type parseType(::mlir::DialectAsmParser &parser) const override;
  void printType(::mlir::Type type,
                 ::mlir::DialectAsmPrinter &os) const override;

private:
  void registerTypes();
};

void registerSCRDialect(::mlir::MLIRContext &context);

// Cross-op verification pass
std::unique_ptr<::mlir::Pass> createSCRVerifyPass();

} // namespace scr

#endif // SCR_DIALECT_H
