//===- SCROps.h - SCR Operation Declarations -*- C++ -*-===//
//
// Operation declarations for the SCR dialect.
//
//===-----------------------------------------------------===//

#ifndef SCR_OPS_H
#define SCR_OPS_H

#include "mlir/IR/OpDefinition.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "mlir/Interfaces/InferTypeOpInterface.h"
#include "mlir/Bytecode/BytecodeOpInterface.h"

#define GET_OP_CLASSES
#include "SCROps.h.inc"

#endif // SCR_OPS_H
