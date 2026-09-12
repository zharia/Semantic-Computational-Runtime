//===- SCROps.cpp - SCR Operation Implementation -*- C++ -*-===//
//
// Operation implementation for the SCR dialect.
// Includes per-op verifiers for type correctness.
//
//===-----------------------------------------------------===//

#include "SCR/SCROps.h"
#include "SCR/SCRTypes.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/Operation.h"
#include "mlir/IR/Builders.h"

using namespace mlir;
using namespace scr;

// Helper: check that a value is an OpaqueType with expected typeData.
static bool isScrType(Value val, StringRef expected) {
  auto opaque = dyn_cast<OpaqueType>(val.getType());
  if (!opaque)
    return false;
  return opaque.getTypeData() == expected;
}

// ---- Per-op verifiers ----

LogicalResult AddNodeOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getEntity(), "entity"))
    return emitOpError("second operand must be !scr.entity");
  if (!isScrType(getResult(), "hypergraph"))
    return emitOpError("result must be !scr.hypergraph");
  return success();
}

LogicalResult RemoveNodeOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getEntityId(), "entity_id"))
    return emitOpError("second operand must be !scr.entity_id");
  if (!isScrType(getResult(), "hypergraph"))
    return emitOpError("result must be !scr.hypergraph");
  return success();
}

LogicalResult AddEdgeOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getEdge(), "hyperedge"))
    return emitOpError("second operand must be !scr.hyperedge");
  if (!isScrType(getResult(), "hypergraph"))
    return emitOpError("result must be !scr.hypergraph");
  return success();
}

LogicalResult RemoveEdgeOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getEdgeId(), "entity_id"))
    return emitOpError("second operand must be !scr.entity_id");
  if (!isScrType(getResult(), "hypergraph"))
    return emitOpError("result must be !scr.hypergraph");
  return success();
}

LogicalResult UpdateNodeValueOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getEntityId(), "entity_id"))
    return emitOpError("second operand must be !scr.entity_id");
  if (!isScrType(getNewValue(), "value"))
    return emitOpError("third operand must be !scr.value");
  if (!isScrType(getResult(), "hypergraph"))
    return emitOpError("result must be !scr.hypergraph");
  return success();
}

LogicalResult NoOpOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getContext(), "context"))
    return emitOpError("second operand must be !scr.context");
  if (!isScrType(getResultGraph(), "hypergraph"))
    return emitOpError("first result must be !scr.hypergraph");
  if (!isScrType(getResultContext(), "context"))
    return emitOpError("second result must be !scr.context");
  return success();
}

LogicalResult AtomicTxOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getContext(), "context"))
    return emitOpError("second operand must be !scr.context");
  if (!isScrType(getResultGraph(), "hypergraph"))
    return emitOpError("first result must be !scr.hypergraph");
  if (!isScrType(getResultContext(), "context"))
    return emitOpError("second result must be !scr.context");
  return success();
}

LogicalResult StepOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getContext(), "context"))
    return emitOpError("second operand must be !scr.context");
  if (!isScrType(getResultGraph(), "hypergraph"))
    return emitOpError("first result must be !scr.hypergraph");
  if (!isScrType(getResultContext(), "context"))
    return emitOpError("second result must be !scr.context");
  return success();
}

LogicalResult ObserveNodeOp::verify() {
  if (!isScrType(getHypergraph(), "hypergraph"))
    return emitOpError("first operand must be !scr.hypergraph");
  if (!isScrType(getEntityId(), "entity_id"))
    return emitOpError("second operand must be !scr.entity_id");
  if (!isScrType(getResult(), "value"))
    return emitOpError("result must be !scr.value");
  return success();
}

#define GET_OP_CLASSES
#include "SCROps.cpp.inc"
