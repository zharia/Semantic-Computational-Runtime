//===- SCRDialect.cpp - SCR Dialect Implementation -*- C++ -*-===//
//
// Dialect registration and type parsing for the SCR dialect.
// Types are MLIR OpaqueType with the "scr" namespace prefix.
//
//===-----------------------------------------------------===//

#include "SCR/SCRDialect.h"
#include "SCR/SCROps.h"

#include "mlir/IR/DialectImplementation.h"

using namespace mlir;
using namespace scr;

SCRDialect::SCRDialect(MLIRContext *context)
    : Dialect(getDialectNamespace(), context,
              TypeID::get<SCRDialect>()) {
  initialize();
}

SCRDialect::~SCRDialect() {}

void SCRDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "SCROps.cpp.inc"
  >();
}

Type SCRDialect::parseType(DialectAsmParser &parser) const {
  StringRef mnemonic;
  if (parser.parseKeyword(&mnemonic))
    return Type();

  if (mnemonic == "entity_id" || mnemonic == "value" ||
      mnemonic == "entity" || mnemonic == "role_binding" ||
      mnemonic == "hyperedge" || mnemonic == "hypergraph" ||
      mnemonic == "context") {
    auto ns = StringAttr::get(getContext(), getDialectNamespace());
    return OpaqueType::get(ns, mnemonic);
  }

  parser.emitError(parser.getNameLoc(), "unknown scr type: ") << mnemonic;
  return Type();
}

void SCRDialect::printType(Type type, DialectAsmPrinter &printer) const {
  if (auto opaque = dyn_cast<OpaqueType>(type)) {
    printer << opaque.getTypeData();
  } else {
    llvm_unreachable("unexpected scr type");
  }
}

void scr::registerSCRDialect(MLIRContext &context) {
  context.getOrLoadDialect<scr::SCRDialect>();
}
