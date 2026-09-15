//===- SCRVerification.cpp - SCR Cross-Op Verification Pass -*- C++ -*-===//
//
// Walk-based verification pass for cross-op invariants.
//
//===-----------------------------------------------------===//

#include "SCR/SCRDialect.h"

#include "mlir/Pass/Pass.h"
#include "mlir/IR/Visitors.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/Operation.h"

using namespace mlir;

namespace {

struct SCRVerifyPass
    : public PassWrapper<SCRVerifyPass, OperationPass<>> {

  StringRef getName() const override { return "scr-verify"; }
  StringRef getArgument() const override { return "scr-verify"; }
  StringRef getDescription() const override { return "Run SCR semantic verification"; }

  void runOnOperation() override {
    Operation *op = getOperation();
    bool hasError = false;

    op->walk([&](Operation *nestedOp) {
      if (auto stepOp = dyn_cast<scr::StepOp>(nestedOp)) {
        if (mlir::failed(verifyRegionOp(stepOp)))
          hasError = true;
      }
      if (auto txOp = dyn_cast<scr::AtomicTxOp>(nestedOp)) {
        if (mlir::failed(verifyRegionOp(txOp)))
          hasError = true;
      }
    });

    if (hasError)
      signalPassFailure();
  }

private:
  template <typename OpT>
  LogicalResult verifyRegionOp(OpT op) {
    Region &region = op.getOperation()->getRegion(0);

    if (region.empty() || std::next(region.begin()) != region.end()) {
      op.emitOpError("region must have exactly one block");
      return failure();
    }

    Block &block = region.front();
    if (block.empty()) {
      op.emitOpError("region block must not be empty");
      return failure();
    }

    Operation &terminator = block.back();
    if (!terminator.hasTrait<OpTrait::IsTerminator>()) {
      op.emitOpError("region block must end with a terminator");
      return failure();
    }

    return success();
  }
};

} // namespace

std::unique_ptr<mlir::Pass> scr::createSCRVerifyPass() {
  return std::make_unique<SCRVerifyPass>();
}
