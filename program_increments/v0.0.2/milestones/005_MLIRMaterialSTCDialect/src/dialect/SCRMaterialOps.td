//===-- SCRMaterialOps.td - SCR Material and STC Dialect Ops -*- tablegen -*-===//
//
// Defines MLIR operations for SCR material property evaluation and
// spatial cellular Semantic Transition Calculus (STC).
//
//===----------------------------------------------------------------------===//

#ifndef SCR_MATERIAL_OPS
#define SCR_MATERIAL_OPS

include "mlir/IR/OpBase.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

def SCR_Dialect : Dialect {
  let name = "scr";
  let summary = "Semantic Computational Runtime MLIR Dialect";
  let cppNamespace = "::mlir::scr";
}

def STC_Dialect : Dialect {
  let name = "stc";
  let summary = "Semantic Transition Calculus MLIR Dialect";
  let cppNamespace = "::mlir::stc";
}

//--- Material Lookup Op ---
def MaterialLookupOp : Op<SCR_Dialect, "material.lookup", [Pure]> {
  let summary = "Lookup compile-time material property by ID";
  let arguments = (ins StrAttr:$material_id, StrAttr:$property_name);
  let results = (outs AnyType:$result);
}

//--- Hookean Stress Evaluation Op ---
def EvalHookeanStressOp : Op<SCR_Dialect, "material.eval_hookean", [Pure]> {
  let summary = "Evaluate 3D symmetric Hookean stress tensor from strain";
  let arguments = (ins 
    TensorOf<[F32, F64]>:$strain_tensor, 
    F64Attr:$youngs_modulus_gpa, 
    F64Attr:$poisson_ratio
  );
  let results = (outs TensorOf<[F32, F64]>:$stress_tensor);
}

//--- STC Stencil Load Op ---
def STCLoadStencilOp : Op<STC_Dialect, "stencil_load", [Pure]> {
  let summary = "Load spatial cellular neighborhood stencil (N6, N18, N26)";
  let arguments = (ins 
    AnyMemRef:$grid, 
    Index:$x, Index:$y, Index:$z, 
    StrAttr:$pattern
  );
  let results = (outs VectorOf<[I16]>:$neighborhood);
}

//--- STC Rule Apply Op ---
def STCRuleApplyOp : Op<STC_Dialect, "rule_apply", [Pure]> {
  let summary = "Apply state transition calculus rule over stencil vector";
  let arguments = (ins 
    VectorOf<[I16]>:$neighborhood, 
    I32Attr:$rule_id
  );
  let results = (outs I16:$next_state);
}

#endif // SCR_MATERIAL_OPS
