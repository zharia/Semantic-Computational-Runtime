//===- SCRVerification.cpp - SCR Verification Passes -*- C++ -*-===//
//
// Verification pass stubs for the SCR dialect.
//
//===-----------------------------------------------------===//

#include "SCR/SCRDialect.h"
#include "SCR/SCROps.h"
#include "SCR/SCRTypes.h"

#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Operation.h"

using namespace mlir;

namespace scr {

void registerSCRPasses() {
  // Pass registration will be added when the C++ pass infrastructure is
  // connected to the TableGen pass definitions in SCRVerification.td.
}

} // namespace scr
