/*===- TableGen'erated file -------------------------------------*- C++ -*-===*\
|*                                                                            *|
|* Op Definitions                                                             *|
|*                                                                            *|
|* Automatically generated file, do not edit!                                 *|
|* From: SCR.td                                                               *|
|*                                                                            *|
\*===----------------------------------------------------------------------===*/

#ifdef GET_OP_LIST
#undef GET_OP_LIST

scr::AddEdgeOp,
scr::AddNodeOp,
scr::AtomicTxOp,
scr::EmptyOp,
scr::MakeContextOp,
scr::MakeEntityIdOp,
scr::MakeEntityOp,
scr::MakeHyperedgeOp,
scr::MakeRoleBindingOp,
scr::NoOpOp,
scr::ObserveNodeOp,
scr::RemoveEdgeOp,
scr::RemoveNodeOp,
scr::ReturnOp,
scr::StepOp,
scr::UpdateNodeValueOp,
scr::ValueBoolOp,
scr::ValueIntOp,
scr::ValueRealOp,
scr::ValueTextOp,
scr::ValueUnitOp
#endif // GET_OP_LIST

#ifdef GET_OP_CLASSES
#undef GET_OP_CLASSES


//===----------------------------------------------------------------------===//
// Local Utility Method Definitions
//===----------------------------------------------------------------------===//


static ::llvm::LogicalResult __mlir_ods_local_type_constraint_SCR1(
    ::mlir::Operation *op, ::mlir::Type type, ::llvm::StringRef valueKind,
    unsigned valueIndex) {
  if (!((true))) {
    return op->emitOpError(valueKind) << " #" << valueIndex
        << " must be any type, but got " << type;
  }
  return ::mlir::success();
}

static ::llvm::LogicalResult __mlir_ods_local_type_constraint_SCR2(
    ::mlir::Operation *op, ::mlir::Type type, ::llvm::StringRef valueKind,
    unsigned valueIndex) {
  if (!((true))) {
    return op->emitOpError(valueKind) << " #" << valueIndex
        << " must be variadic of any type, but got " << type;
  }
  return ::mlir::success();
}

static ::llvm::LogicalResult __mlir_ods_local_region_constraint_SCR1(
    ::mlir::Operation *op, ::mlir::Region &region, ::llvm::StringRef regionName,
    unsigned regionIndex) {
  if (!((true))) {
    return op->emitOpError("region #") << regionIndex
        << (regionName.empty() ? " " : " ('" + regionName + "') ")
        << "failed to verify constraint: any region";
  }
  return ::mlir::success();
}
namespace scr {


//===----------------------------------------------------------------------===//
// scr::AddEdgeOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

AddEdgeOpGenericAdaptorBase::AddEdgeOpGenericAdaptorBase(AddEdgeOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
AddEdgeOpAdaptor::AddEdgeOpAdaptor(AddEdgeOp op) : AddEdgeOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult AddEdgeOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult AddEdgeOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute AddEdgeOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code AddEdgeOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> AddEdgeOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void AddEdgeOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void AddEdgeOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult AddEdgeOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void AddEdgeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value edge) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(edge);
  odsState.addTypes(result);
}

AddEdgeOp AddEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value edge) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge)>(edge));
  auto __res__ = ::llvm::dyn_cast<AddEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddEdgeOp AddEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value edge) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge)>(edge));
}

void AddEdgeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value edge) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(edge);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

AddEdgeOp AddEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value edge) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge)>(edge));
  auto __res__ = ::llvm::dyn_cast<AddEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddEdgeOp AddEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value edge) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge)>(edge));
}

void AddEdgeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

AddEdgeOp AddEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<AddEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddEdgeOp AddEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void AddEdgeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

AddEdgeOp AddEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<AddEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddEdgeOp AddEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult AddEdgeOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult AddEdgeOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult AddEdgeOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void AddEdgeOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::AddEdgeOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::AddNodeOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

AddNodeOpGenericAdaptorBase::AddNodeOpGenericAdaptorBase(AddNodeOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
AddNodeOpAdaptor::AddNodeOpAdaptor(AddNodeOp op) : AddNodeOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult AddNodeOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult AddNodeOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute AddNodeOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code AddNodeOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> AddNodeOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void AddNodeOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void AddNodeOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult AddNodeOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void AddNodeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity);
  odsState.addTypes(result);
}

AddNodeOp AddNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity)>(entity));
  auto __res__ = ::llvm::dyn_cast<AddNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddNodeOp AddNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity)>(entity));
}

void AddNodeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

AddNodeOp AddNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity)>(entity));
  auto __res__ = ::llvm::dyn_cast<AddNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddNodeOp AddNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity)>(entity));
}

void AddNodeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

AddNodeOp AddNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<AddNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddNodeOp AddNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void AddNodeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

AddNodeOp AddNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<AddNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AddNodeOp AddNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult AddNodeOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult AddNodeOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult AddNodeOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void AddNodeOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::AddNodeOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::AtomicTxOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

AtomicTxOpGenericAdaptorBase::AtomicTxOpGenericAdaptorBase(AtomicTxOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
AtomicTxOpAdaptor::AtomicTxOpAdaptor(AtomicTxOp op) : AtomicTxOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult AtomicTxOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

void AtomicTxOp::getAsmResultNames(::mlir::OpAsmSetValueNameFn setNameFn) {
  auto resultGroup0 = getODSResults(0);
  if (!resultGroup0.empty())
    setNameFn(*resultGroup0.begin(), "result_graph");
  auto resultGroup1 = getODSResults(1);
  if (!resultGroup1.empty())
    setNameFn(*resultGroup1.begin(), "result_context");
}

::llvm::LogicalResult AtomicTxOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute AtomicTxOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code AtomicTxOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> AtomicTxOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void AtomicTxOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void AtomicTxOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult AtomicTxOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void AtomicTxOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(context);
  (void)odsState.addRegion();
  odsState.addTypes(result_graph);
  odsState.addTypes(result_context);
}

AtomicTxOp AtomicTxOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result_graph)>(result_graph), std::forward<decltype(result_context)>(result_context), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
  auto __res__ = ::llvm::dyn_cast<AtomicTxOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AtomicTxOp AtomicTxOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  return create(builder, builder.getLoc(), std::forward<decltype(result_graph)>(result_graph), std::forward<decltype(result_context)>(result_context), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
}

void AtomicTxOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(context);
  (void)odsState.addRegion();
  assert(resultTypes.size() == 2u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

AtomicTxOp AtomicTxOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
  auto __res__ = ::llvm::dyn_cast<AtomicTxOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AtomicTxOp AtomicTxOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
}

void AtomicTxOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  for (unsigned i = 0; i != 1; ++i)
    (void)odsState.addRegion();
  assert(resultTypes.size() == 2u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

AtomicTxOp AtomicTxOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<AtomicTxOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AtomicTxOp AtomicTxOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void AtomicTxOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  for (unsigned i = 0; i != 1; ++i)
    (void)odsState.addRegion();
  assert(resultTypes.size() == 2u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

AtomicTxOp AtomicTxOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<AtomicTxOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

AtomicTxOp AtomicTxOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult AtomicTxOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSResults(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;

    for (auto &region : ::llvm::MutableArrayRef((*this)->getRegion(0)))
      if (::mlir::failed(__mlir_ods_local_region_constraint_SCR1(*this, region, "body", index++)))
        return ::mlir::failure();
  }
  return ::mlir::success();
}

::llvm::LogicalResult AtomicTxOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult AtomicTxOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void AtomicTxOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::AtomicTxOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::EmptyOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

EmptyOpGenericAdaptorBase::EmptyOpGenericAdaptorBase(EmptyOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
EmptyOpAdaptor::EmptyOpAdaptor(EmptyOp op) : EmptyOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult EmptyOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult EmptyOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute EmptyOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code EmptyOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> EmptyOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void EmptyOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void EmptyOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult EmptyOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void EmptyOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result) {
  odsState.addTypes(result);
}

EmptyOp EmptyOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result));
  auto __res__ = ::llvm::dyn_cast<EmptyOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

EmptyOp EmptyOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result));
}

void EmptyOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes) {
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

EmptyOp EmptyOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes));
  auto __res__ = ::llvm::dyn_cast<EmptyOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

EmptyOp EmptyOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes));
}

void EmptyOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 0u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

EmptyOp EmptyOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<EmptyOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

EmptyOp EmptyOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void EmptyOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 0u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

EmptyOp EmptyOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<EmptyOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

EmptyOp EmptyOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult EmptyOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult EmptyOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult EmptyOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void EmptyOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::EmptyOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::MakeContextOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

MakeContextOpGenericAdaptorBase::MakeContextOpGenericAdaptorBase(MakeContextOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
MakeContextOpAdaptor::MakeContextOpAdaptor(MakeContextOp op) : MakeContextOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult MakeContextOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult MakeContextOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute MakeContextOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code MakeContextOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> MakeContextOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void MakeContextOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void MakeContextOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult MakeContextOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void MakeContextOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value logical_step, ::mlir::Value label) {
  odsState.addOperands(logical_step);
  odsState.addOperands(label);
  odsState.addTypes(result);
}

MakeContextOp MakeContextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value logical_step, ::mlir::Value label) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(logical_step)>(logical_step), std::forward<decltype(label)>(label));
  auto __res__ = ::llvm::dyn_cast<MakeContextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeContextOp MakeContextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value logical_step, ::mlir::Value label) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(logical_step)>(logical_step), std::forward<decltype(label)>(label));
}

void MakeContextOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value logical_step, ::mlir::Value label) {
  odsState.addOperands(logical_step);
  odsState.addOperands(label);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

MakeContextOp MakeContextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value logical_step, ::mlir::Value label) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(logical_step)>(logical_step), std::forward<decltype(label)>(label));
  auto __res__ = ::llvm::dyn_cast<MakeContextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeContextOp MakeContextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value logical_step, ::mlir::Value label) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(logical_step)>(logical_step), std::forward<decltype(label)>(label));
}

void MakeContextOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeContextOp MakeContextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<MakeContextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeContextOp MakeContextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void MakeContextOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeContextOp MakeContextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<MakeContextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeContextOp MakeContextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult MakeContextOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult MakeContextOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult MakeContextOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void MakeContextOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::MakeContextOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::MakeEntityIdOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

MakeEntityIdOpGenericAdaptorBase::MakeEntityIdOpGenericAdaptorBase(MakeEntityIdOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
MakeEntityIdOpAdaptor::MakeEntityIdOpAdaptor(MakeEntityIdOp op) : MakeEntityIdOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult MakeEntityIdOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult MakeEntityIdOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute MakeEntityIdOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code MakeEntityIdOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> MakeEntityIdOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void MakeEntityIdOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void MakeEntityIdOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult MakeEntityIdOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void MakeEntityIdOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value value) {
  odsState.addOperands(value);
  odsState.addTypes(result);
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<MakeEntityIdOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
}

void MakeEntityIdOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  odsState.addOperands(value);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<MakeEntityIdOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
}

void MakeEntityIdOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<MakeEntityIdOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void MakeEntityIdOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<MakeEntityIdOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityIdOp MakeEntityIdOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult MakeEntityIdOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult MakeEntityIdOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult MakeEntityIdOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void MakeEntityIdOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::MakeEntityIdOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::MakeEntityOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

MakeEntityOpGenericAdaptorBase::MakeEntityOpGenericAdaptorBase(MakeEntityOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
MakeEntityOpAdaptor::MakeEntityOpAdaptor(MakeEntityOp op) : MakeEntityOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult MakeEntityOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult MakeEntityOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute MakeEntityOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code MakeEntityOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> MakeEntityOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void MakeEntityOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void MakeEntityOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult MakeEntityOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void MakeEntityOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value id, ::mlir::Value type_name, ::mlir::Value value, ::mlir::Value props) {
  odsState.addOperands(id);
  odsState.addOperands(type_name);
  odsState.addOperands(value);
  odsState.addOperands(props);
  odsState.addTypes(result);
}

MakeEntityOp MakeEntityOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value id, ::mlir::Value type_name, ::mlir::Value value, ::mlir::Value props) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(id)>(id), std::forward<decltype(type_name)>(type_name), std::forward<decltype(value)>(value), std::forward<decltype(props)>(props));
  auto __res__ = ::llvm::dyn_cast<MakeEntityOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityOp MakeEntityOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value id, ::mlir::Value type_name, ::mlir::Value value, ::mlir::Value props) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(id)>(id), std::forward<decltype(type_name)>(type_name), std::forward<decltype(value)>(value), std::forward<decltype(props)>(props));
}

void MakeEntityOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value id, ::mlir::Value type_name, ::mlir::Value value, ::mlir::Value props) {
  odsState.addOperands(id);
  odsState.addOperands(type_name);
  odsState.addOperands(value);
  odsState.addOperands(props);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

MakeEntityOp MakeEntityOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value id, ::mlir::Value type_name, ::mlir::Value value, ::mlir::Value props) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(id)>(id), std::forward<decltype(type_name)>(type_name), std::forward<decltype(value)>(value), std::forward<decltype(props)>(props));
  auto __res__ = ::llvm::dyn_cast<MakeEntityOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityOp MakeEntityOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value id, ::mlir::Value type_name, ::mlir::Value value, ::mlir::Value props) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(id)>(id), std::forward<decltype(type_name)>(type_name), std::forward<decltype(value)>(value), std::forward<decltype(props)>(props));
}

void MakeEntityOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 4u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeEntityOp MakeEntityOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<MakeEntityOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityOp MakeEntityOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void MakeEntityOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 4u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeEntityOp MakeEntityOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<MakeEntityOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeEntityOp MakeEntityOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult MakeEntityOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup2 = getODSOperands(2);

    for (auto v : valueGroup2) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup3 = getODSOperands(3);

    for (auto v : valueGroup3) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult MakeEntityOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult MakeEntityOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void MakeEntityOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::MakeEntityOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::MakeHyperedgeOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

MakeHyperedgeOpGenericAdaptorBase::MakeHyperedgeOpGenericAdaptorBase(MakeHyperedgeOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
MakeHyperedgeOpAdaptor::MakeHyperedgeOpAdaptor(MakeHyperedgeOp op) : MakeHyperedgeOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult MakeHyperedgeOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult MakeHyperedgeOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute MakeHyperedgeOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code MakeHyperedgeOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> MakeHyperedgeOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void MakeHyperedgeOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void MakeHyperedgeOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult MakeHyperedgeOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void MakeHyperedgeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value id, ::mlir::Value edge_type, ::mlir::Value roles, ::mlir::Value props) {
  odsState.addOperands(id);
  odsState.addOperands(edge_type);
  odsState.addOperands(roles);
  odsState.addOperands(props);
  odsState.addTypes(result);
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value id, ::mlir::Value edge_type, ::mlir::Value roles, ::mlir::Value props) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(id)>(id), std::forward<decltype(edge_type)>(edge_type), std::forward<decltype(roles)>(roles), std::forward<decltype(props)>(props));
  auto __res__ = ::llvm::dyn_cast<MakeHyperedgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value id, ::mlir::Value edge_type, ::mlir::Value roles, ::mlir::Value props) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(id)>(id), std::forward<decltype(edge_type)>(edge_type), std::forward<decltype(roles)>(roles), std::forward<decltype(props)>(props));
}

void MakeHyperedgeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value id, ::mlir::Value edge_type, ::mlir::Value roles, ::mlir::Value props) {
  odsState.addOperands(id);
  odsState.addOperands(edge_type);
  odsState.addOperands(roles);
  odsState.addOperands(props);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value id, ::mlir::Value edge_type, ::mlir::Value roles, ::mlir::Value props) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(id)>(id), std::forward<decltype(edge_type)>(edge_type), std::forward<decltype(roles)>(roles), std::forward<decltype(props)>(props));
  auto __res__ = ::llvm::dyn_cast<MakeHyperedgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value id, ::mlir::Value edge_type, ::mlir::Value roles, ::mlir::Value props) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(id)>(id), std::forward<decltype(edge_type)>(edge_type), std::forward<decltype(roles)>(roles), std::forward<decltype(props)>(props));
}

void MakeHyperedgeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 4u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<MakeHyperedgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void MakeHyperedgeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 4u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<MakeHyperedgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeHyperedgeOp MakeHyperedgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult MakeHyperedgeOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup2 = getODSOperands(2);

    for (auto v : valueGroup2) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup3 = getODSOperands(3);

    for (auto v : valueGroup3) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult MakeHyperedgeOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult MakeHyperedgeOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void MakeHyperedgeOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::MakeHyperedgeOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::MakeRoleBindingOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

MakeRoleBindingOpGenericAdaptorBase::MakeRoleBindingOpGenericAdaptorBase(MakeRoleBindingOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
MakeRoleBindingOpAdaptor::MakeRoleBindingOpAdaptor(MakeRoleBindingOp op) : MakeRoleBindingOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult MakeRoleBindingOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult MakeRoleBindingOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute MakeRoleBindingOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code MakeRoleBindingOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> MakeRoleBindingOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void MakeRoleBindingOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void MakeRoleBindingOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult MakeRoleBindingOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void MakeRoleBindingOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value role, ::mlir::Value target) {
  odsState.addOperands(role);
  odsState.addOperands(target);
  odsState.addTypes(result);
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value role, ::mlir::Value target) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(role)>(role), std::forward<decltype(target)>(target));
  auto __res__ = ::llvm::dyn_cast<MakeRoleBindingOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value role, ::mlir::Value target) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(role)>(role), std::forward<decltype(target)>(target));
}

void MakeRoleBindingOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value role, ::mlir::Value target) {
  odsState.addOperands(role);
  odsState.addOperands(target);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value role, ::mlir::Value target) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(role)>(role), std::forward<decltype(target)>(target));
  auto __res__ = ::llvm::dyn_cast<MakeRoleBindingOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value role, ::mlir::Value target) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(role)>(role), std::forward<decltype(target)>(target));
}

void MakeRoleBindingOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<MakeRoleBindingOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void MakeRoleBindingOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<MakeRoleBindingOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

MakeRoleBindingOp MakeRoleBindingOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult MakeRoleBindingOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult MakeRoleBindingOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult MakeRoleBindingOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void MakeRoleBindingOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::MakeRoleBindingOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::NoOpOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

NoOpOpGenericAdaptorBase::NoOpOpGenericAdaptorBase(NoOpOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
NoOpOpAdaptor::NoOpOpAdaptor(NoOpOp op) : NoOpOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult NoOpOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

void NoOpOp::getAsmResultNames(::mlir::OpAsmSetValueNameFn setNameFn) {
  auto resultGroup0 = getODSResults(0);
  if (!resultGroup0.empty())
    setNameFn(*resultGroup0.begin(), "result_graph");
  auto resultGroup1 = getODSResults(1);
  if (!resultGroup1.empty())
    setNameFn(*resultGroup1.begin(), "result_context");
}

::llvm::LogicalResult NoOpOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute NoOpOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code NoOpOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> NoOpOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void NoOpOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void NoOpOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult NoOpOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void NoOpOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(context);
  odsState.addTypes(result_graph);
  odsState.addTypes(result_context);
}

NoOpOp NoOpOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result_graph)>(result_graph), std::forward<decltype(result_context)>(result_context), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
  auto __res__ = ::llvm::dyn_cast<NoOpOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

NoOpOp NoOpOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  return create(builder, builder.getLoc(), std::forward<decltype(result_graph)>(result_graph), std::forward<decltype(result_context)>(result_context), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
}

void NoOpOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(context);
  assert(resultTypes.size() == 2u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

NoOpOp NoOpOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
  auto __res__ = ::llvm::dyn_cast<NoOpOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

NoOpOp NoOpOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
}

void NoOpOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 2u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

NoOpOp NoOpOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<NoOpOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

NoOpOp NoOpOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void NoOpOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 2u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

NoOpOp NoOpOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<NoOpOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

NoOpOp NoOpOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult NoOpOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSResults(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult NoOpOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult NoOpOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void NoOpOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::NoOpOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::ObserveNodeOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

ObserveNodeOpGenericAdaptorBase::ObserveNodeOpGenericAdaptorBase(ObserveNodeOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
ObserveNodeOpAdaptor::ObserveNodeOpAdaptor(ObserveNodeOp op) : ObserveNodeOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult ObserveNodeOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult ObserveNodeOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute ObserveNodeOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code ObserveNodeOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> ObserveNodeOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void ObserveNodeOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void ObserveNodeOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult ObserveNodeOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void ObserveNodeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity_id);
  odsState.addTypes(result);
}

ObserveNodeOp ObserveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
  auto __res__ = ::llvm::dyn_cast<ObserveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ObserveNodeOp ObserveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
}

void ObserveNodeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity_id);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

ObserveNodeOp ObserveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
  auto __res__ = ::llvm::dyn_cast<ObserveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ObserveNodeOp ObserveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
}

void ObserveNodeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ObserveNodeOp ObserveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<ObserveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ObserveNodeOp ObserveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void ObserveNodeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ObserveNodeOp ObserveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<ObserveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ObserveNodeOp ObserveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult ObserveNodeOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult ObserveNodeOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult ObserveNodeOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void ObserveNodeOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::ObserveNodeOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::RemoveEdgeOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

RemoveEdgeOpGenericAdaptorBase::RemoveEdgeOpGenericAdaptorBase(RemoveEdgeOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
RemoveEdgeOpAdaptor::RemoveEdgeOpAdaptor(RemoveEdgeOp op) : RemoveEdgeOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult RemoveEdgeOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult RemoveEdgeOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute RemoveEdgeOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code RemoveEdgeOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> RemoveEdgeOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void RemoveEdgeOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void RemoveEdgeOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult RemoveEdgeOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void RemoveEdgeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value edge_id) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(edge_id);
  odsState.addTypes(result);
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value edge_id) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge_id)>(edge_id));
  auto __res__ = ::llvm::dyn_cast<RemoveEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value edge_id) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge_id)>(edge_id));
}

void RemoveEdgeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value edge_id) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(edge_id);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value edge_id) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge_id)>(edge_id));
  auto __res__ = ::llvm::dyn_cast<RemoveEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value edge_id) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(edge_id)>(edge_id));
}

void RemoveEdgeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<RemoveEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void RemoveEdgeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<RemoveEdgeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveEdgeOp RemoveEdgeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult RemoveEdgeOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult RemoveEdgeOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult RemoveEdgeOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void RemoveEdgeOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::RemoveEdgeOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::RemoveNodeOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

RemoveNodeOpGenericAdaptorBase::RemoveNodeOpGenericAdaptorBase(RemoveNodeOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
RemoveNodeOpAdaptor::RemoveNodeOpAdaptor(RemoveNodeOp op) : RemoveNodeOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult RemoveNodeOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult RemoveNodeOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute RemoveNodeOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code RemoveNodeOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> RemoveNodeOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void RemoveNodeOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void RemoveNodeOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult RemoveNodeOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void RemoveNodeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity_id);
  odsState.addTypes(result);
}

RemoveNodeOp RemoveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
  auto __res__ = ::llvm::dyn_cast<RemoveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveNodeOp RemoveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
}

void RemoveNodeOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity_id);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

RemoveNodeOp RemoveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
  auto __res__ = ::llvm::dyn_cast<RemoveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveNodeOp RemoveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id));
}

void RemoveNodeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

RemoveNodeOp RemoveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<RemoveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveNodeOp RemoveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void RemoveNodeOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

RemoveNodeOp RemoveNodeOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<RemoveNodeOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

RemoveNodeOp RemoveNodeOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult RemoveNodeOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult RemoveNodeOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult RemoveNodeOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void RemoveNodeOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::RemoveNodeOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::ReturnOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

ReturnOpGenericAdaptorBase::ReturnOpGenericAdaptorBase(ReturnOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}

std::pair<unsigned, unsigned> ReturnOpGenericAdaptorBase::getODSOperandIndexAndLength(unsigned index, unsigned odsOperandsSize) {
  bool isVariadic[] = {true};
  int prevVariadicCount = 0;
  for (unsigned i = 0; i < index; ++i)
    if (isVariadic[i]) ++prevVariadicCount;

  // Calculate how many dynamic values a static variadic operand corresponds to.
  // This assumes all static variadic operands have the same dynamic value count.
  int variadicSize = (odsOperandsSize - 0) / 1;
  // `index` passed in as the parameter is the static index which counts each
  // operand (variadic or not) as size 1. So here for each previous static variadic
  // operand, we need to offset by (variadicSize - 1) to get where the dynamic
  // value pack for this static operand starts.
  int start = index + (variadicSize - 1) * prevVariadicCount;
  int size = isVariadic[index] ? variadicSize : 1;
  return {start, size};
}


} // namespace detail
ReturnOpAdaptor::ReturnOpAdaptor(ReturnOp op) : ReturnOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult ReturnOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

std::pair<unsigned, unsigned> ReturnOp::getODSOperandIndexAndLength(unsigned index) {
  bool isVariadic[] = {true};
  int prevVariadicCount = 0;
  for (unsigned i = 0; i < index; ++i)
    if (isVariadic[i]) ++prevVariadicCount;

  // Calculate how many dynamic values a static variadic operand corresponds to.
  // This assumes all static variadic operands have the same dynamic value count.
  int variadicSize = (getOperation()->getNumOperands() - 0) / 1;
  // `index` passed in as the parameter is the static index which counts each
  // operand (variadic or not) as size 1. So here for each previous static variadic
  // operand, we need to offset by (variadicSize - 1) to get where the dynamic
  // value pack for this static operand starts.
  int start = index + (variadicSize - 1) * prevVariadicCount;
  int size = isVariadic[index] ? variadicSize : 1;
  return {start, size};
}

::mlir::MutableOperandRange ReturnOp::getOperandsMutable() {
  auto range = getODSOperandIndexAndLength(0);
  auto mutableRange = ::mlir::MutableOperandRange(getOperation(), range.first, range.second);
  return mutableRange;
}

::llvm::LogicalResult ReturnOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute ReturnOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code ReturnOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> ReturnOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void ReturnOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void ReturnOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult ReturnOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void ReturnOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::ValueRange operands) {
  odsState.addOperands(operands);
}

ReturnOp ReturnOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::ValueRange operands) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(operands)>(operands));
  auto __res__ = ::llvm::dyn_cast<ReturnOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ReturnOp ReturnOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::ValueRange operands) {
  return create(builder, builder.getLoc(), std::forward<decltype(operands)>(operands));
}

void ReturnOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 0u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ReturnOp ReturnOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<ReturnOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ReturnOp ReturnOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void ReturnOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 0u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ReturnOp ReturnOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<ReturnOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ReturnOp ReturnOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult ReturnOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR2(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult ReturnOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult ReturnOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::ReturnOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::StepOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

StepOpGenericAdaptorBase::StepOpGenericAdaptorBase(StepOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
StepOpAdaptor::StepOpAdaptor(StepOp op) : StepOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult StepOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

void StepOp::getAsmResultNames(::mlir::OpAsmSetValueNameFn setNameFn) {
  auto resultGroup0 = getODSResults(0);
  if (!resultGroup0.empty())
    setNameFn(*resultGroup0.begin(), "result_graph");
  auto resultGroup1 = getODSResults(1);
  if (!resultGroup1.empty())
    setNameFn(*resultGroup1.begin(), "result_context");
}

::llvm::LogicalResult StepOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute StepOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code StepOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> StepOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void StepOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void StepOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult StepOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void StepOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(context);
  (void)odsState.addRegion();
  odsState.addTypes(result_graph);
  odsState.addTypes(result_context);
}

StepOp StepOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result_graph)>(result_graph), std::forward<decltype(result_context)>(result_context), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
  auto __res__ = ::llvm::dyn_cast<StepOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

StepOp StepOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result_graph, ::mlir::Type result_context, ::mlir::Value hypergraph, ::mlir::Value context) {
  return create(builder, builder.getLoc(), std::forward<decltype(result_graph)>(result_graph), std::forward<decltype(result_context)>(result_context), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
}

void StepOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(context);
  (void)odsState.addRegion();
  assert(resultTypes.size() == 2u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

StepOp StepOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
  auto __res__ = ::llvm::dyn_cast<StepOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

StepOp StepOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value context) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(context)>(context));
}

void StepOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  for (unsigned i = 0; i != 1; ++i)
    (void)odsState.addRegion();
  assert(resultTypes.size() == 2u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

StepOp StepOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<StepOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

StepOp StepOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void StepOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 2u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  for (unsigned i = 0; i != 1; ++i)
    (void)odsState.addRegion();
  assert(resultTypes.size() == 2u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

StepOp StepOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<StepOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

StepOp StepOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult StepOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSResults(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;

    for (auto &region : ::llvm::MutableArrayRef((*this)->getRegion(0)))
      if (::mlir::failed(__mlir_ods_local_region_constraint_SCR1(*this, region, "body", index++)))
        return ::mlir::failure();
  }
  return ::mlir::success();
}

::llvm::LogicalResult StepOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult StepOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void StepOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::StepOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::UpdateNodeValueOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

UpdateNodeValueOpGenericAdaptorBase::UpdateNodeValueOpGenericAdaptorBase(UpdateNodeValueOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
UpdateNodeValueOpAdaptor::UpdateNodeValueOpAdaptor(UpdateNodeValueOp op) : UpdateNodeValueOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult UpdateNodeValueOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult UpdateNodeValueOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute UpdateNodeValueOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code UpdateNodeValueOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> UpdateNodeValueOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void UpdateNodeValueOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void UpdateNodeValueOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult UpdateNodeValueOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void UpdateNodeValueOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id, ::mlir::Value new_value) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity_id);
  odsState.addOperands(new_value);
  odsState.addTypes(result);
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id, ::mlir::Value new_value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id), std::forward<decltype(new_value)>(new_value));
  auto __res__ = ::llvm::dyn_cast<UpdateNodeValueOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value hypergraph, ::mlir::Value entity_id, ::mlir::Value new_value) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id), std::forward<decltype(new_value)>(new_value));
}

void UpdateNodeValueOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id, ::mlir::Value new_value) {
  odsState.addOperands(hypergraph);
  odsState.addOperands(entity_id);
  odsState.addOperands(new_value);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id, ::mlir::Value new_value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id), std::forward<decltype(new_value)>(new_value));
  auto __res__ = ::llvm::dyn_cast<UpdateNodeValueOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value hypergraph, ::mlir::Value entity_id, ::mlir::Value new_value) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(hypergraph)>(hypergraph), std::forward<decltype(entity_id)>(entity_id), std::forward<decltype(new_value)>(new_value));
}

void UpdateNodeValueOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 3u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<UpdateNodeValueOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void UpdateNodeValueOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 3u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<UpdateNodeValueOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

UpdateNodeValueOp UpdateNodeValueOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult UpdateNodeValueOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup1 = getODSOperands(1);

    for (auto v : valueGroup1) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
    auto valueGroup2 = getODSOperands(2);

    for (auto v : valueGroup2) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult UpdateNodeValueOp::verifyInvariants() {
  if(::mlir::succeeded(verifyInvariantsImpl()) && ::mlir::succeeded(verify()))
    return ::mlir::success();
  return ::mlir::failure();
}

::llvm::LogicalResult UpdateNodeValueOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void UpdateNodeValueOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::UpdateNodeValueOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::ValueBoolOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

ValueBoolOpGenericAdaptorBase::ValueBoolOpGenericAdaptorBase(ValueBoolOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
ValueBoolOpAdaptor::ValueBoolOpAdaptor(ValueBoolOp op) : ValueBoolOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult ValueBoolOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult ValueBoolOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute ValueBoolOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code ValueBoolOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> ValueBoolOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void ValueBoolOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void ValueBoolOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult ValueBoolOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void ValueBoolOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value value) {
  odsState.addOperands(value);
  odsState.addTypes(result);
}

ValueBoolOp ValueBoolOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueBoolOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueBoolOp ValueBoolOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
}

void ValueBoolOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  odsState.addOperands(value);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

ValueBoolOp ValueBoolOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueBoolOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueBoolOp ValueBoolOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
}

void ValueBoolOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueBoolOp ValueBoolOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<ValueBoolOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueBoolOp ValueBoolOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void ValueBoolOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueBoolOp ValueBoolOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<ValueBoolOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueBoolOp ValueBoolOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult ValueBoolOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult ValueBoolOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult ValueBoolOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void ValueBoolOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::ValueBoolOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::ValueIntOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

ValueIntOpGenericAdaptorBase::ValueIntOpGenericAdaptorBase(ValueIntOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
ValueIntOpAdaptor::ValueIntOpAdaptor(ValueIntOp op) : ValueIntOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult ValueIntOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult ValueIntOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute ValueIntOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code ValueIntOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> ValueIntOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void ValueIntOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void ValueIntOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult ValueIntOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void ValueIntOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value value) {
  odsState.addOperands(value);
  odsState.addTypes(result);
}

ValueIntOp ValueIntOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueIntOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueIntOp ValueIntOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
}

void ValueIntOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  odsState.addOperands(value);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

ValueIntOp ValueIntOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueIntOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueIntOp ValueIntOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
}

void ValueIntOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueIntOp ValueIntOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<ValueIntOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueIntOp ValueIntOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void ValueIntOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueIntOp ValueIntOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<ValueIntOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueIntOp ValueIntOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult ValueIntOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult ValueIntOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult ValueIntOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void ValueIntOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::ValueIntOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::ValueRealOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

ValueRealOpGenericAdaptorBase::ValueRealOpGenericAdaptorBase(ValueRealOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
ValueRealOpAdaptor::ValueRealOpAdaptor(ValueRealOp op) : ValueRealOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult ValueRealOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult ValueRealOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute ValueRealOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code ValueRealOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> ValueRealOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void ValueRealOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void ValueRealOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult ValueRealOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void ValueRealOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value value) {
  odsState.addOperands(value);
  odsState.addTypes(result);
}

ValueRealOp ValueRealOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueRealOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueRealOp ValueRealOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
}

void ValueRealOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  odsState.addOperands(value);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

ValueRealOp ValueRealOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueRealOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueRealOp ValueRealOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
}

void ValueRealOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueRealOp ValueRealOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<ValueRealOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueRealOp ValueRealOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void ValueRealOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueRealOp ValueRealOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<ValueRealOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueRealOp ValueRealOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult ValueRealOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult ValueRealOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult ValueRealOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void ValueRealOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::ValueRealOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::ValueTextOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

ValueTextOpGenericAdaptorBase::ValueTextOpGenericAdaptorBase(ValueTextOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
ValueTextOpAdaptor::ValueTextOpAdaptor(ValueTextOp op) : ValueTextOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult ValueTextOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult ValueTextOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute ValueTextOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code ValueTextOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> ValueTextOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void ValueTextOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void ValueTextOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult ValueTextOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void ValueTextOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result, ::mlir::Value value) {
  odsState.addOperands(value);
  odsState.addTypes(result);
}

ValueTextOp ValueTextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueTextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueTextOp ValueTextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result), std::forward<decltype(value)>(value));
}

void ValueTextOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  odsState.addOperands(value);
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

ValueTextOp ValueTextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
  auto __res__ = ::llvm::dyn_cast<ValueTextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueTextOp ValueTextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::Value value) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(value)>(value));
}

void ValueTextOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueTextOp ValueTextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<ValueTextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueTextOp ValueTextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void ValueTextOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 1u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueTextOp ValueTextOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<ValueTextOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueTextOp ValueTextOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult ValueTextOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSOperands(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "operand", index++)))
        return ::mlir::failure();
    }
  }
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult ValueTextOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult ValueTextOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void ValueTextOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::ValueTextOp)

namespace scr {


//===----------------------------------------------------------------------===//
// scr::ValueUnitOp definitions
//===----------------------------------------------------------------------===//

namespace detail {

ValueUnitOpGenericAdaptorBase::ValueUnitOpGenericAdaptorBase(ValueUnitOp op) : odsAttrs(op->getRawDictionaryAttrs()), odsOpName(op->getName()), properties(op.getProperties()), odsRegions(op->getRegions()) {}


} // namespace detail
ValueUnitOpAdaptor::ValueUnitOpAdaptor(ValueUnitOp op) : ValueUnitOpGenericAdaptor(op->getOperands(), op) {}

::llvm::LogicalResult ValueUnitOpAdaptor::verify(::mlir::Location loc) {
  return ::mlir::success();
}

::llvm::LogicalResult ValueUnitOp::setPropertiesFromAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
      return ::mlir::success();
}

::mlir::Attribute ValueUnitOp::getPropertiesAsAttr(::mlir::MLIRContext *ctx, const Properties &prop) {
    ::mlir::SmallVector<::mlir::NamedAttribute> attrs;
    ::mlir::Builder odsBuilder{ctx};

  if (!attrs.empty())
    return odsBuilder.getDictionaryAttr(attrs);
  return {};
}

llvm::hash_code ValueUnitOp::computePropertiesHash(const Properties &prop) {
  using llvm::hash_value;
  return llvm::hash_combine();
}

std::optional<mlir::Attribute> ValueUnitOp::getInherentAttr(::mlir::MLIRContext *ctx, const Properties &prop, llvm::StringRef name) {
  return std::nullopt;
}

void ValueUnitOp::setInherentAttr(Properties &prop, llvm::StringRef name, mlir::Attribute value) {
}

void ValueUnitOp::populateInherentAttrs(::mlir::MLIRContext *ctx, const Properties &prop, ::mlir::NamedAttrList &attrs) {
}

::llvm::LogicalResult ValueUnitOp::verifyInherentAttrs(::mlir::OperationName opName, ::mlir::NamedAttrList &attrs, llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
    return ::mlir::success();
}

void ValueUnitOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::Type result) {
  odsState.addTypes(result);
}

ValueUnitOp ValueUnitOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::Type result) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(result)>(result));
  auto __res__ = ::llvm::dyn_cast<ValueUnitOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueUnitOp ValueUnitOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::Type result) {
  return create(builder, builder.getLoc(), std::forward<decltype(result)>(result));
}

void ValueUnitOp::build(::mlir::OpBuilder &odsBuilder, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes) {
  assert(resultTypes.size() == 1u && "mismatched number of results");
  odsState.addTypes(resultTypes);
}

ValueUnitOp ValueUnitOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes));
  auto __res__ = ::llvm::dyn_cast<ValueUnitOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueUnitOp ValueUnitOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes));
}

void ValueUnitOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  assert(operands.size() == 0u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.addAttributes(attributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueUnitOp ValueUnitOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
  auto __res__ = ::llvm::dyn_cast<ValueUnitOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueUnitOp ValueUnitOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, ::llvm::ArrayRef<::mlir::NamedAttribute> attributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(attributes)>(attributes));
}

void ValueUnitOp::build(::mlir::OpBuilder &, ::mlir::OperationState &odsState, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  assert(operands.size() == 0u && "mismatched number of parameters");
  odsState.addOperands(operands);
  odsState.useProperties(const_cast<Properties&>(properties));
  odsState.addAttributes(discardableAttributes);
  assert(resultTypes.size() == 1u && "mismatched number of return types");
  odsState.addTypes(resultTypes);
}

ValueUnitOp ValueUnitOp::create(::mlir::OpBuilder &builder, ::mlir::Location location, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  ::mlir::OperationState __state__(location, getOperationName());
  build(builder, __state__, std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
  auto __res__ = ::llvm::dyn_cast<ValueUnitOp>(builder.create(__state__));
  assert(__res__ && "builder didn't return the right type");
  return __res__;
}

ValueUnitOp ValueUnitOp::create(::mlir::ImplicitLocOpBuilder &builder, ::mlir::TypeRange resultTypes, ::mlir::ValueRange operands, const Properties &properties, ::llvm::ArrayRef<::mlir::NamedAttribute> discardableAttributes) {
  return create(builder, builder.getLoc(), std::forward<decltype(resultTypes)>(resultTypes), std::forward<decltype(operands)>(operands), std::forward<decltype(properties)>(properties), std::forward<decltype(discardableAttributes)>(discardableAttributes));
}

::llvm::LogicalResult ValueUnitOp::verifyInvariantsImpl() {
  {
    unsigned index = 0; (void)index;
    auto valueGroup0 = getODSResults(0);

    for (auto v : valueGroup0) {
      if (::mlir::failed(__mlir_ods_local_type_constraint_SCR1(*this, v.getType(), "result", index++)))
        return ::mlir::failure();
    }
  }
  return ::mlir::success();
}

::llvm::LogicalResult ValueUnitOp::verifyInvariants() {
  return verifyInvariantsImpl();
}

::llvm::LogicalResult ValueUnitOp::setPropertiesFromParsedAttr(Properties &prop, ::mlir::Attribute attr, ::llvm::function_ref<::mlir::InFlightDiagnostic()> emitError) {
  ::mlir::DictionaryAttr dict = ::llvm::dyn_cast<::mlir::DictionaryAttr>(attr);
  if (!dict) {
    emitError() << "expected DictionaryAttr to set properties";
    return ::mlir::failure();
  }
  // keep track of used keys in the input dictionary to be able to error out
  // if there are some unknown ones.
  ::mlir::DenseSet<::mlir::StringAttr> usedKeys;
  ::mlir::MLIRContext *ctx = dict.getContext();
  (void)ctx;

  for (::mlir::NamedAttribute attr : dict) {
    if (!usedKeys.contains(attr.getName()))
      return emitError() << "unknown key '" << attr.getName() <<
          "' when parsing properties dictionary";
  }
  return ::mlir::success();
}

void ValueUnitOp::getEffects(::llvm::SmallVectorImpl<::mlir::SideEffects::EffectInstance<::mlir::MemoryEffects::Effect>> &effects) {
}


} // namespace scr
MLIR_DEFINE_EXPLICIT_TYPE_ID(scr::ValueUnitOp)


#endif // GET_OP_CLASSES

