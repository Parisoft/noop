/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.validation

import com.google.inject.Inject
import org.eclipse.xtext.validation.Check
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.^extension.TypeSystem
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable

import static org.parisoft.noop.noop.NoopPackage.Literals.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.Method
import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.noop.Block
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.ElseStatement
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.BreakStatement
import org.parisoft.noop.noop.ContinueStatement

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class NoopValidator extends AbstractNoopValidator {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Expressions
	@Inject extension Collections

	public static val CLASS_RECURSIVE_HIERARCHY = 'CLASS_RECURSIVE_HIERARCHY'
	public static val FIELD_TYPE_SAME_HIERARCHY = 'FIELD_TYPE_SAME_HIERARCHY'
	public static val FIELD_STORAGE = 'FIELD_STORAGE'
	public static val FIELD_DUPLICITY = 'FIELD_DUPLICITY'
	public static val FIELD_OVERRIDEN_TYPE = 'FIELD_OVERRIDEN_TYPE' // TODO keep or remove? (if remove, must change member polymorphic ref)
	public static val FIELD_OVERRIDEN_DIMENSION = 'FIELD_OVERRIDEN_DIMENSION'
	public static val STATIC_FIELD_CONTAINER = 'STATIC_FIELD_CONTAINER'
	public static val STATIC_FIELD_STORAGE_TYPE = 'STATIC_FIELD_STORAGE_TYPE'
	public static val STATIC_FIELD_ROM_TYPE = 'STATIC_FIELD_ROM_TYPE'
	public static val STATIC_FIELD_ROM_VALUE = 'STATIC_FIELD_ROM_VALUE'
	public static val CONSTANT_FIELD_TYPE = 'CONSTANT_FIELD_TYPE'
	public static val CONSTANT_FIELD_DIMENSION = 'CONSTANT_FIELD_DIMENSION'
	public static val CONSTANT_FIELD_STORAGE = 'CONSTANT_FIELD_STORAGE'
	public static val CONSTANT_FIELD_VALUE = 'CONSTANT_FIELD_VALUE'
	public static val VARIABLE_VOID_TYPE = 'VARIABLE_VOID_TYPE'
	public static val VARIABLE_INES_HEADER_TYPE = 'VARIABLE_INES_HEADER_TYPE'
	public static val VARIABLE_DUPLICITY = 'VARIABLE_DUPLICITY'
	public static val VARIABLE_NEVER_USED = 'VARIABLE_NEVER_USED'
	public static val PARAMETER_VOID_TYPE = 'PARAMETER VOID_TYPE'
	public static val PARAMETER_INES_HEADER_TYPE = 'PARAMETER INES_HEADER_TYPE'
	public static val PARAMETER_STORAGE_TYPE = 'PARAMETER_STORAGE_TYPE'
	public static val PARAMETER_DUPLICITY = 'PARAMETER_DUPLICITY'
	public static val PARAMETER_OVERRIDEN_DIMENSION = 'PARAMETER_OVERRIDEN_DIMENSION'
	public static val METHOD_DUPLICITY = 'METHOD_DUPLICITY'
	public static val METHOD_DIMENSIONAL_VOID = 'METHOD DIMENSIONAL_VOID'
	public static val METHOD_STORAGE_TYPE = 'METHOD_STORAGE_TYPE'
	public static val METHOD_OVERRIDEN_TYPE = 'METHOD_OVERRIDEN_TYPE'
	public static val METHOD_OVERRIDEN_DIMENSION = 'METHOD_OVERRIDEN_DIMENSION'
	public static val RETURN_UNBOUNDED_DIMENSION = 'RETURN_UNBOUNDED_DIMENSION'
	public static val RETURN_INCONSISTENT_DIMENSION = 'RETURN_INCONSISTENT_DIMENSION'
	public static val STATEMENT_UNREACHABLE = 'STATEMENT_UNREACHABLE'
	public static val IF_CONDITION_TYPE = 'IF_CONDITION_TYPE'
	public static val IF_CONSTANT_CONDITION = 'IF_CONSTANT_CONDITION'
	public static val IF_EMPTY_BODY = 'IF_EMPTY_BODY'
	public static val ELSE_EMPTY_BODY = 'ELSE_EMPTY_BODY'

	@Check
	def classRecursiveHierarchy(NoopClass c) {
		if (c.superClass == c || c.superClasses.drop(1).exists[isInstanceOf(c)]) {
			error('Recursive hierarchy is not allowed', NOOP_CLASS__SUPER_CLASS, CLASS_RECURSIVE_HIERARCHY,
				c.superClass.name)
		}
	}

	@Check
	def fieldTypeSameHierarchy(Variable v) {
		if (v.isField && v.isNonStatic) {
			val varClass = v.containerClass
			val varType = v.typeOf

			if (varClass.isInstanceOf(varType) || varType.isInstanceOf(varClass)) {
				error('Type of non-static fields cannot be on the same hierarchy of the field\'s class',
					VARIABLE__VALUE, FIELD_TYPE_SAME_HIERARCHY)
			}
		}
	}

	@Check
	def fieldStorage(Variable v) {
		if (v.isField && v.isNonStatic && v.storage !== null) {
			error('Non-static fields cannot be tagged', MEMBER__STORAGE, FIELD_STORAGE)
		}
	}

	@Check
	def fieldDuplicity(Variable v) {
		if (v.isField) {
			if (v.containerClass.declaredFields.takeWhile[it != v].exists[it.name == v.name]) {
				error('''Field «v.name» is duplicated''', MEMBER__NAME, FIELD_DUPLICITY)
			}
		}
	}

	@Check
	def fieldOverridenType(Variable v) {
		if (v.isField) {
			val overriden = v.containerClass.allFieldsTopDown.findFirst[v.isOverrideOf(it)]

			if (overriden !== null) {
				val overridenType = overriden.typeOf

				if (v.typeOf.isNotEquals(overridenType)) {
					error('''Field «v.name» must have the same «overridenType.name» type of the overriden field''',
						VARIABLE__VALUE, FIELD_OVERRIDEN_TYPE)
				}
			}
		}
	}

	@Check
	def fieldOverridenDimension(Variable v) {
		if (v.isField) {
			val overriden = v.containerClass.superClass.allFieldsTopDown.findFirst[v.isOverrideOf(it)]

			if (overriden !== null) {
				val overrideDimension = overriden.dimensionOf

				if (v.dimensionOf !== overrideDimension) {
					if (overrideDimension.isEmpty) {
						error('''Field «v.name» must have no dimension as the overriden field''', MEMBER__NAME,
							FIELD_OVERRIDEN_DIMENSION)
					} else if (overrideDimension.size == 1) {
						error('''Field «v.name» must have the same dimension of length «overrideDimension.head» as the overriden field''',
							MEMBER__NAME, FIELD_OVERRIDEN_DIMENSION)
					} else {
						error('''Field «v.name» must have the same «overrideDimension.join('x')» dimension of the overriden field''',
							MEMBER__NAME, FIELD_OVERRIDEN_DIMENSION)
					}
				}
			}
		}
	}

	@Check
	def staticFieldContainer(Variable v) {
		if (v.isStatic && v.isNonField) {
			error('''«IF v.isParameter»Parameters«ELSE»Local variables«ENDIF» cannot be declared as static''',
				MEMBER__NAME, STATIC_FIELD_CONTAINER)
		}
	}

	@Check
	def staticFieldStorageType(Variable v) {
		if (v.isStatic && v.storage?.type == StorageType::INLINE) {
			error('''Fields cannot be tagged as «v.storage.type.literal.substring(1)»''', MEMBER__STORAGE,
				STATIC_FIELD_STORAGE_TYPE)
		}
	}

	@Check
	def staticFieldRomType(Variable v) {
		if (v.isStatic && v.isROM && v.typeOf.isNonPrimitive) {
			error('''Type of static fields tagged as «v.storage.type.literal.substring(1)» must be «TypeSystem::LIB_PRIMITIVES.join(', ')»''',
				VARIABLE__VALUE, STATIC_FIELD_ROM_TYPE)
		}
	}

	@Check
	def staticFieldRomValue(Variable v) {
		if (v.isStatic && v.isROM && v.dimensionOf.isEmpty && v.value.isNonConstant) {
			error('''Fields tagged as «v.storage.type.literal.substring(0)» must be declared with a constant value''',
				VARIABLE__VALUE, STATIC_FIELD_ROM_VALUE)
		}
	}

	@Check
	def constantFieldType(Variable v) {
		if (v.isConstant && v.typeOf.isNonPrimitive) {
			error('''Type of constant fields must be «TypeSystem::LIB_PRIMITIVES.join(', ')»''', VARIABLE__VALUE,
				CONSTANT_FIELD_TYPE)
		}
	}

	@Check
	def constantFieldDimension(Variable v) {
		if (v.isConstant && v.dimensionOf.isNotEmpty) {
			error('Constant fields must be non-dimensional', VARIABLE__DIMENSION, CONSTANT_FIELD_DIMENSION)
		}
	}

	@Check
	def constantFieldStorage(Variable v) {
		if (v.isConstant && v.storage !== null) {
			error('Constant fields cannot be tagged', MEMBER__STORAGE, CONSTANT_FIELD_STORAGE)
		}
	}

	@Check
	def constantFieldValue(Variable v) {
		if (v.isConstant && v.value.isNonConstant) {
			error('Constant fields must be declared with a constant value', VARIABLE__VALUE, CONSTANT_FIELD_VALUE)
		}
	}

	@Check
	def variableVoidType(Variable v) {
		if (v.isNonParameter && v.typeOf.isVoid) {
			error('''«TypeSystem::LIB_VOID» is not a valid type for «IF v.isField»fields«ELSE»variables«ENDIF»''',
				VARIABLE__VALUE, VARIABLE_VOID_TYPE)
		}
	}

	@Check
	def variableINesHeaderType(Variable v) {
		if (v.isNonParameter && v.isNonStatic && v.typeOf.isINESHeader) {
			error('''«TypeSystem::LIB_NES_HEADER» is not a valid type for «IF v.isField»non-static fields«ELSE»variables«ENDIF»''',
				VARIABLE__VALUE, VARIABLE_INES_HEADER_TYPE)
		}
	}

	@Check
	def variableDuplicity(Variable v) {
		if (v.isNonField && v.isNonParameter) {
			if (v.searchForDuplicityOn(v.eContainer)) {
				error('''Variable «v.name» is duplicated''', MEMBER__NAME, VARIABLE_DUPLICITY)
			}
		}
	}

	@Check
	def variableNeverUsed(Variable v) {
		if (v.isNonField && v.isNonParameter) {
			if (v.getContainerOfType(Method).getAllContentsOfType(MemberSelect).forall[member != v] &&
				v.getContainerOfType(Method).getAllContentsOfType(MemberRef).forall[member != v]) {
				warning('''Variable «v.name» is never used locally''', MEMBER__NAME, VARIABLE_NEVER_USED)
			}
		}
	}

	@Check
	def parameterVoidType(Variable v) {
		if (v.isParameter && v.type.isVoid) {
			error('''«TypeSystem::LIB_VOID» is not a valid type for parameters''', VARIABLE__TYPE, PARAMETER_VOID_TYPE)
		}
	}

	@Check
	def parameterINesHeaderType(Variable v) {
		if (v.isParameter && v.type.isINESHeader) {
			error('''«TypeSystem::LIB_NES_HEADER» is not a valid type for parameters''', VARIABLE__TYPE,
				PARAMETER_INES_HEADER_TYPE)
		}
	}

	@Check
	def parameterStorageType(Variable v) {
		if (v.isParameter && v.storage?.type != StorageType::ZP) {
			error('''Parameters cannot be tagged as «v.storage.type.literal.substring(1)»''', MEMBER__STORAGE,
				PARAMETER_STORAGE_TYPE)
		}
	}

	@Check
	def parameterDuplicity(Variable v) {
		if (v.isParameter) {
			if (v.getContainerOfType(Method).params.takeWhile[it != v].exists[it.name == v.name]) {
				error('''Parameter «v.name» is duplicated''', MEMBER__NAME, PARAMETER_DUPLICITY)
			}
		}
	}

	@Check
	def parameterOverridenDimension(Variable v) {
		val m = v.eContainer

		if (m instanceof Method) {
			val overriden = m.containerClass.allMethodsTopDown.findFirst[m.isOverrideOf(it)]

			if (overriden !== null) {
				val overridenDimension = overriden.params.get(m.params.indexOf(v)).dimension

				if (v.dimension != overridenDimension) {
					if (overridenDimension.size == 1) {
						error('''Parameter «v.name» must have the same dimension of length «overridenDimension.head» as the overriden parameter''',
							VARIABLE__DIMENSION, PARAMETER_OVERRIDEN_DIMENSION)
					} else {
						error('''Parameter «v.name» must have the same «overridenDimension.map[value?.valueOf].join('x')» dimension of the overriden parameter''',
							VARIABLE__DIMENSION, PARAMETER_OVERRIDEN_DIMENSION)
					}
				}
			}
		}
	}

	@Check
	def methodDuplicity(Method m) {
		val duplicated = m.containerClass.declaredMethods.takeWhile[it != m].filter [
			it.name == m.name
		].filter [
			it.params.size == m.params.size
		].exists [
			for (i : 0 ..< params.size) {
				val p1 = it.params.get(i)
				val p2 = m.params.get(i)

				if (p1.type.isNotEquals(p2.type)) {
					return false
				}

				if (p1.dimensionOf.size != p2.dimensionOf.size) {
					return false
				}
			}

			true
		]

		if (duplicated) {
			error('''Method «m.name» is duplicated''', MEMBER__NAME, METHOD_DUPLICITY)
		}
	}

	@Check
	def methodDimensionalVoid(Method m) {
		if (m.typeOf.isVoid && m.dimensionOf.isNotEmpty) {
			error('''«TypeSystem::LIB_VOID» methods must return a non-dimensional value''', MEMBER__NAME,
				METHOD_DIMENSIONAL_VOID)
		}
	}

	@Check
	def methodStorageType(Method m) {
		if (m.storage?.type != StorageType::PRGROM && m.storage?.type != StorageType::INLINE) {
			error('''Methods cannot be tagged as «m.storage.type.literal.substring(0)»''', MEMBER__STORAGE,
				METHOD_STORAGE_TYPE)
		}
	}

	@Check
	def methodOverridenType(Method m) {
		val overriden = m.containerClass.allMethodsTopDown.findFirst[m.isOverrideOf(it)]

		if (overriden !== null && m.typeOf.isNonSubclassOf(overriden.typeOf)) {
			error('''Method «m.name» must return the same «overriden.typeOf.name» type or a subtype returned by the overriden method''',
				MEMBER__NAME, METHOD_OVERRIDEN_TYPE)
		}
	}

	@Check
	def methodOverridenDimension(Method m) {
		val overriden = m.containerClass.allMethodsTopDown.findFirst[m.isOverrideOf(it)]

		if (overriden !== null) {
			val methodDimension = m.dimensionOf
			val overridenDimension = overriden.dimensionOf

			if (methodDimension != overridenDimension) {
				if (overridenDimension.isEmpty) {
					error('''Method «m.name» must return a non-dimensional value as the overriden method''',
						MEMBER__NAME, METHOD_OVERRIDEN_DIMENSION)
				} else if (overridenDimension.size == 1) {
					error('''Method «m.name» must return the same dimension of length «overridenDimension.head» as returned by the overriden method''',
						MEMBER__NAME, METHOD_OVERRIDEN_DIMENSION)
				} else {
					error('''Method «m.name» must return the same «overridenDimension.join('x')» dimension returned by the overriden method''',
						MEMBER__NAME, METHOD_OVERRIDEN_DIMENSION)
				}
			}
		}
	}

	@Check
	def returnUnboundedDimension(ReturnStatement ret) {
		if (ret.value?.isUnbounded) {
			error('Methods must return bounded dimensional values', RETURN_STATEMENT__VALUE, RETURN_UNBOUNDED_DIMENSION)
		}
	}

	@Check
	def returnInconsistentDimension(ReturnStatement ret) {
		val inconsistent = ret.getContainerOfType(Method).getAllContentsOfType(ReturnStatement).takeWhile [
			it != ret
		].exists [
			it?.value.dimensionOf != ret?.value.dimensionOf
		]

		if (inconsistent) {
			error('All returned values in a method must have the same dimension', RETURN_STATEMENT__VALUE,
				RETURN_INCONSISTENT_DIMENSION)
		}
	}

	@Check
	def statementUnreachable(Statement statement) {
		val block = statement.eContainer

		if (block instanceof Block) {
			if (block.statements.takeWhile[it != statement].exists[unconditionalBreak]) {
				warning('Dead code', statement, null, STATEMENT_UNREACHABLE)
			}
		}
	}

	@Check
	def ifConditionType(IfStatement ifStatement) {
		if (ifStatement.condition.typeOf.isNonBoolean) {
			error('''Ifs condition must be a «TypeSystem::LIB_BOOL» expression''', IF_STATEMENT__CONDITION,
				IF_CONDITION_TYPE)
		}
	}

	@Check
	def ifConstantCondition(IfStatement ifStatement) {
		if (ifStatement.condition.isConstant) {
			val condition = ifStatement.condition.valueOf

			if (condition instanceof Boolean) {
				warning('''If's condition always evaluate to «ifStatement.condition.valueOf»''',
					IF_STATEMENT__CONDITION, IF_CONSTANT_CONDITION)

				if (condition) {
					var nextElse = ifStatement.^else

					while (nextElse !== null) {
						if (nextElse.body !== null) {
							warning('Dead code', nextElse.body, null, IF_CONSTANT_CONDITION)
						} else if (nextElse.^if !== null) {
							warning('Dead code', nextElse.^if.body, null, IF_CONSTANT_CONDITION)
						}

						nextElse = nextElse.^if?.^else
					}
				} else {
					warning('Dead code', ifStatement.body, null, IF_CONSTANT_CONDITION)
				}
			}
		}
	}

	@Check
	def ifEmptyBody(IfStatement ifStatement) {
		if (ifStatement.body.statements.isEmpty) {
			warning('Useless if statement', IF_STATEMENT__NAME, IF_EMPTY_BODY)
		}
	}

	@Check
	def elseEmptyBody(ElseStatement elseStatement) {
		if (elseStatement.body?.statements?.isEmpty) {
			warning('Useless else statement', ELSE_STATEMENT__NAME, ELSE_EMPTY_BODY)
		}
	}

	private def boolean searchForDuplicityOn(Variable v, EObject container) {
		if (container === null) {
			return false
		}

		return switch (container) {
			Block:
				container.statements.takeWhile [
					it != v && !it.getAllContentsOfType(Variable).contains(v)
				].filter(Variable).exists[it.name == v.name]
			ForStatement:
				container.variables.takeWhile[it != v].filter(Variable).exists[it.name == v.name]
			Method:
				container.params.exists[it.name == v.name]
			default:
				false
		} || v.searchForDuplicityOn(container.eContainer)
	}
	
	private def unconditionalBreak(Statement s) {
		s.isBreakContinueOrReturn || (s instanceof IfStatement && (s as IfStatement).unconditionalBreak)
	}

	private def Boolean unconditionalBreak(IfStatement ifStatement) {
		if (ifStatement === null) {
			null
		} else if (ifStatement.condition.isConstant) {
			val condition = ifStatement.condition.valueOf

			if (condition instanceof Boolean) {
				if (condition) {
					ifStatement.body.statements.exists[isBreakContinueOrReturn]
				} else {
					ifStatement.^else.unconditionalBreak ?: false
				}
			} else {
				false
			}
		} else {
			ifStatement.body.statements.exists[isBreakContinueOrReturn] &&
				(ifStatement.^else.unconditionalBreak ?: true)
		}
	}

	private def Boolean unconditionalBreak(ElseStatement elseStatement) {
		if (elseStatement === null) {
			null
		} else if (elseStatement.body !== null) {
			elseStatement.body.statements.exists[isBreakContinueOrReturn]
		} else {
			elseStatement.^if.unconditionalBreak
		}
	}

	private def isBreakContinueOrReturn(Statement s) {
		s instanceof ReturnStatement || s instanceof BreakStatement || s instanceof ContinueStatement
	}

}
