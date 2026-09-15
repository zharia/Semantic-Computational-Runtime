//===- SCRTypes.cpp - SCR Type Implementation -*- C++ -*-===//
//
// Type implementation for the SCR dialect.
//
//===-----------------------------------------------------===//

#include "SCR/SCRTypes.h"
#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

#define GET_TYPEDEF_CLASSES
#include "SCRTypes.cpp.inc"
