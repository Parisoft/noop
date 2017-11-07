package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.stream.Collectors
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.CompileContext.Mode
import org.parisoft.noop.generator.CompileContext.Operation
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.generator.NoopInstance
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.AssignmentType
import org.parisoft.noop.noop.BAndExpression
import org.parisoft.noop.noop.BOrExpression
import org.parisoft.noop.noop.BoolLiteral
import org.parisoft.noop.noop.ByteLiteral
import org.parisoft.noop.noop.CastExpression
import org.parisoft.noop.noop.DecExpression
import org.parisoft.noop.noop.DifferExpression
import org.parisoft.noop.noop.DivExpression
import org.parisoft.noop.noop.EorExpression
import org.parisoft.noop.noop.EqualsExpression
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.GeExpression
import org.parisoft.noop.noop.GtExpression
import org.parisoft.noop.noop.IncExpression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.InheritsExpression
import org.parisoft.noop.noop.LShiftExpression
import org.parisoft.noop.noop.LeExpression
import org.parisoft.noop.noop.LtExpression
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.MulExpression
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.NotExpression
import org.parisoft.noop.noop.OrExpression
import org.parisoft.noop.noop.RShiftExpression
import org.parisoft.noop.noop.SigNegExpression
import org.parisoft.noop.noop.SigPosExpression
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.SubExpression
import org.parisoft.noop.noop.Super
import org.parisoft.noop.noop.This
import org.parisoft.noop.noop.Variable

import static extension java.lang.Integer.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.MemberSelect
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import java.io.File
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.AllocContext

class Expressions {

	@Inject extension Files
	@Inject extension Datas
	@Inject extension Values
	@Inject extension Classes
	@Inject extension Members
	@Inject extension Operations
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Collections

	def isMethodInvocation(MemberSelect selection) {
		try {
			selection.member instanceof Method
		} catch (Error e) {
			false
		}
	}

	def isMethodInvocation(MemberRef ref) {
		try {
			ref.member instanceof Method
		} catch (Error e) {
			false
		}
	}

	def isOnMemberSelectionOrReference(Expression expression) {
		val container = expression.eContainer
		container !== null && (container instanceof MemberSelect || container instanceof MemberRef)
	}

	def isFileInclude(StringLiteral string) {
		string.value.toLowerCase.startsWith(Members::FILE_SCHEMA)
	}

	def isAsmFile(StringLiteral string) {
		string.isFileInclude && string.value.toLowerCase.endsWith(Members::FILE_ASM_EXTENSION)
	}

	def isIncFile(StringLiteral string) {
		string.isFileInclude && string.value.toLowerCase.endsWith(Members::FILE_INC_EXTENSION)
	}

	def isDmcFile(StringLiteral string) {
		string.isFileInclude && string.value.toLowerCase.endsWith(Members::FILE_DMC_EXTENSION)
	}

	def nameOfTmp(List<Index> indexes, String containerName) {
		'''«containerName».idx@«indexes.hashCode.toHexString»'''.toString
	}

	def nameOfTmp(ArrayLiteral array, String containerName) {
		'''«containerName».tmp«array.typeOf.name»Array@«array.hashCode.toHexString»'''.toString
	}

	def nameOfTmpArray(NewInstance instance, String containerName) {
		'''«containerName».tmp«instance.typeOf.name»Array@«instance.hashCode.toHexString»'''.toString
	}

	def nameOfTmpVar(NewInstance instance, String containerName) {
		'''«containerName».tmp«instance.typeOf.name»@«instance.hashCode.toHexString»'''.toString
	}

	def nameOfConstructor(NewInstance instance) {
		'''«instance.type.name».new'''.toString
	}

	def nameOfReceiver(NewInstance instance) {
		'''«instance.nameOfConstructor».rcv'''.toString
	}

	def fieldsInitializedOnContructor(NewInstance instance) {
		instance.type.allFieldsTopDown.filter[nonStatic]
	}

	def NoopClass typeOf(Expression expression) {
		if (expression === null) {
			return TypeSystem::TYPE_VOID
		}

		switch (expression) {
			AssignmentExpression:
				expression.left.typeOf
			OrExpression:
				expression.toBoolClass
			AndExpression:
				expression.toBoolClass
			EqualsExpression:
				expression.toBoolClass
			DifferExpression:
				expression.toBoolClass
			GtExpression:
				expression.toBoolClass
			GeExpression:
				expression.toBoolClass
			LtExpression:
				expression.toBoolClass
			LeExpression:
				expression.toBoolClass
			InheritsExpression:
				expression.toBoolClass
			AddExpression:
				expression.typeOfValueOrInt
			SubExpression:
				expression.typeOfValueOrInt
			MulExpression:
				expression.typeOfValueOrInt
			DivExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			BOrExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			BAndExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			LShiftExpression:
				expression.typeOfValueOrInt
			RShiftExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			EorExpression:
				expression.right.typeOf
			NotExpression:
				expression.toBoolClass
			SigNegExpression:
				expression.typeOfValueOrInt
			SigPosExpression:
				expression.right.typeOf
			DecExpression:
				expression.typeOfValueOrInt
			IncExpression:
				expression.typeOfValueOrInt
			CastExpression:
				expression.type
			ByteLiteral:
				if (expression.value > TypeSystem::MAX_INT) {
					expression.toUIntClass
				} else if (expression.value > TypeSystem::MAX_BYTE) {
					expression.toIntClass
				} else if (expression.value > TypeSystem::MAX_SBYTE) {
					expression.toByteClass
				} else if (expression.value < TypeSystem::MIN_SBYTE) {
					expression.toIntClass
				} else if (expression.value < TypeSystem::MIN_BYTE) {
					expression.toSByteClass
				} else {
					expression.toByteClass
				}
			BoolLiteral:
				expression.toBoolClass
			ArrayLiteral:
				if (expression.values.isEmpty) {
					expression.toObjectClass
				} else {
					expression.values.map[typeOf].merge
				}
			StringLiteral:
				expression.toByteClass
			This:
				expression.containerClass
			Super:
				expression.containerClass.superClassOrObject
			NewInstance:
				expression.type
			MemberSelect:
				expression.member.typeOf
			MemberRef:
				expression.member.typeOf
		}
	}

	private def typeOfValue(Expression expression) {
		val value = expression.valueOf as Integer

		if (value > TypeSystem::MAX_INT) {
			expression.toUIntClass
		} else if (value > TypeSystem::MAX_BYTE) {
			expression.toIntClass
		} else if (value > TypeSystem::MAX_SBYTE) {
			expression.toByteClass
		} else if (value < TypeSystem::MIN_SBYTE) {
			expression.toIntClass
		} else if (value < TypeSystem::MIN_BYTE) {
			expression.toSByteClass
		} else {
			expression.toByteClass
		}
	}

	private def typeOfValueOrMerge(Expression expression, Expression left, Expression right) {
		try {
			expression.typeOfValue
		} catch (Exception e) {
			val leftType = left.typeOf
			val rightType = right.typeOf

			if (leftType.rawSizeOf > rightType.rawSizeOf) {
				leftType
			} else if (leftType.rawSizeOf < rightType.rawSizeOf) {
				rightType
			} else if (leftType.isSigned) {
				leftType
			} else {
				rightType
			}
		}
	}

	private def typeOfValueOrInt(Expression expression) {
		try {
			expression.typeOfValue
		} catch (Exception e) {
			expression.toIntClass
		}
	}

	def Object valueOf(Expression expression) {
		try {
			switch (expression) {
				OrExpression:
					(expression.left.valueOf as Boolean) || (expression.right.valueOf as Boolean)
				AndExpression:
					(expression.left.valueOf as Boolean) && (expression.right.valueOf as Boolean)
				EqualsExpression:
					if (expression.left.typeOf.isNumeric) {
						expression.right.typeOf.isNumeric && expression.left.valueOf === expression.right.valueOf
					} else if (expression.left.typeOf.isBoolean) {
						expression.right.typeOf.isBoolean && expression.left.valueOf === expression.right.valueOf
					} else {
						throw new NonConstantExpressionException(expression)
					}
				DifferExpression:
					if (expression.left.typeOf.isNumeric) {
						!expression.right.typeOf.isNumeric || expression.left.valueOf !== expression.right.valueOf
					} else if (expression.left.typeOf.isBoolean) {
						!expression.right.typeOf.isBoolean || expression.left.valueOf !== expression.right.valueOf
					} else {
						throw new NonConstantExpressionException(expression)
					}
				GtExpression:
					(expression.left.valueOf as Integer) > (expression.right.valueOf as Integer)
				GeExpression:
					(expression.left.valueOf as Integer) >= (expression.right.valueOf as Integer)
				LtExpression:
					(expression.left.valueOf as Integer) < (expression.right.valueOf as Integer)
				LeExpression:
					(expression.left.valueOf as Integer) <= (expression.right.valueOf as Integer)
				AddExpression:
					(expression.left.valueOf as Integer) + (expression.right.valueOf as Integer)
				SubExpression:
					(expression.left.valueOf as Integer) - (expression.right.valueOf as Integer)
				MulExpression:
					(expression.left.valueOf as Integer) * (expression.right.valueOf as Integer)
				DivExpression:
					(expression.left.valueOf as Integer) / (expression.right.valueOf as Integer)
				BOrExpression:
					(expression.left.valueOf as Integer).bitwiseOr(expression.right.valueOf as Integer)
				BAndExpression:
					(expression.left.valueOf as Integer).bitwiseAnd(expression.right.valueOf as Integer)
				LShiftExpression:
					(expression.left.valueOf as Integer) << (expression.right.valueOf as Integer)
				RShiftExpression:
					(expression.left.valueOf as Integer) >> (expression.right.valueOf as Integer)
				EorExpression:
					(expression.right.valueOf as Integer).bitwiseNot
				NotExpression:
					!(expression.right.valueOf as Boolean)
				SigNegExpression:
					-(expression.right.valueOf as Integer)
				SigPosExpression:
					(expression.right.valueOf as Integer)
				CastExpression:
					expression.left.valueOf
				ByteLiteral:
					expression.value
				BoolLiteral:
					expression.value
				ArrayLiteral:
					expression.values.map[valueOf]
				StringLiteral:
					expression.value.chars.boxed.collect(Collectors::toList)
				NewInstance:
					if (expression.constructor !== null) {
						new NoopInstance(expression.type.name, expression.type.allFieldsBottomUp,
							expression.constructor)
					} else {
						expression.type.defaultValueOf
					}
				MemberSelect:
					expression.member.valueOf
				MemberRef:
					expression.member.valueOf
				default:
					throw new NonConstantExpressionException(expression)
			}
		} catch (NonConstantMemberException e) {
			throw new NonConstantExpressionException(expression)
		} catch (ClassCastException e) {
			throw new InvalidExpressionException(expression)
		}
	}

	def dimensionOf(Expression expression) {
		switch (expression) {
			StringLiteral:
				expression.valueOf.dimensionOf
			ArrayLiteral:
				expression.valueOf.dimensionOf
			MemberSelect:
				expression.member.dimensionOf.subListFrom(expression.indexes.size)
			MemberRef:
				expression.member.dimensionOf.subListFrom(expression.indexes.size)
			NewInstance:
				expression.dimension.map[value.valueOf as Integer]
			default:
				emptyList
		}
	}

	def sizeOf(Expression expression) {
		expression.typeOf.sizeOf
	}

	def fullSizeOf(ArrayLiteral array) {
		array.sizeOf * (array.dimensionOf.reduce[d1, d2|d1 * d2] ?: 1)
	}

	def fullSizeOf(NewInstance instance) {
		instance.sizeOf * (instance.dimensionOf.reduce[d1, d2|d1 * d2] ?: 1)
	}

	def void prepare(Expression expression, AllocContext ctx) {
		switch (expression) {
			AssignmentExpression:
				expression.right.prepare(ctx)
			OrExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			AndExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			EqualsExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			DifferExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			GtExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			GeExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			LtExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			LeExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			InheritsExpression: {
				expression.left.prepare(ctx)
				expression.type.prepare(ctx)
			}
			AddExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			SubExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			MulExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			DivExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			BOrExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			BAndExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			LShiftExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			RShiftExpression: {
				expression.left.prepare(ctx)
				expression.right.prepare(ctx)
			}
			EorExpression:
				expression.right.prepare(ctx)
			NotExpression:
				expression.right.prepare(ctx)
			SigNegExpression:
				expression.right.prepare(ctx)
			SigPosExpression:
				expression.right.prepare(ctx)
			DecExpression:
				expression.right.prepare(ctx)
			IncExpression:
				expression.right.prepare(ctx)
			CastExpression: {
				expression.type.prepare(ctx)
				expression.left.prepare(ctx)
			}
			ArrayLiteral:
				expression.typeOf.prepare(ctx)
			NewInstance:
				if (expression.type.isINESHeader) {
					ctx.header = expression
				} else {
					expression.type.prepare(ctx)

					if (expression.type.isNonPrimitive) {
						expression.fieldsInitializedOnContructor.forEach[prepare(ctx)]
					}
				}
			MemberSelect: {
				expression.receiver.prepare(ctx)

				if (expression.member instanceof Variable) {
					(expression.member as Variable).prepare(ctx)
				} else if (expression.member instanceof Method) {
					expression.args.forEach[prepare(ctx)]
					(expression.member as Method).prepare(ctx)
				}

				expression.indexes.forEach[value.prepare(ctx)]
			}
			MemberRef: {
				if (expression.member instanceof Variable) {
					(expression.member as Variable).prepare(ctx)
				} else if (expression.member instanceof Method) {
					expression.args.forEach[prepare(ctx)]
					(expression.member as Method).prepare(ctx)
				}

				expression.indexes.forEach[value.prepare(ctx)]
			}
		}
	}

	def List<MemChunk> alloc(Expression expression, AllocContext ctx) {
		switch (expression) {
			AssignmentExpression:
				expression.right.alloc(ctx)
			OrExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			AndExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			EqualsExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			DifferExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			GtExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			GeExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			LtExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			LeExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			InheritsExpression:
				expression.left.alloc(ctx)
			AddExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			SubExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			MulExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			DivExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			BOrExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			BAndExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			LShiftExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			RShiftExpression:
				(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
			EorExpression:
				expression.right.alloc(ctx)
			NotExpression:
				expression.right.alloc(ctx)
			SigNegExpression:
				expression.right.alloc(ctx)
			SigPosExpression:
				expression.right.alloc(ctx)
			DecExpression:
				expression.right.alloc(ctx)
			IncExpression:
				expression.right.alloc(ctx)
			CastExpression:
				expression.left.alloc(ctx)
			ArrayLiteral: {
				val chunks = expression.values.map[alloc(ctx)].flatten.toList

				if (expression.isOnMemberSelectionOrReference) {
					chunks += ctx.computeTmp(expression.nameOfTmp(ctx.container), expression.fullSizeOf)
				}

				return chunks
			}
			NewInstance: {
				val chunks = newArrayList

				if (expression.type.isINESHeader) {
					return chunks
				}

				if (expression.isOnMemberSelectionOrReference) {
					if (expression.dimension.isEmpty && expression.type.isNonPrimitive) {
						chunks += ctx.computeTmp(expression.nameOfTmpVar(ctx.container), expression.sizeOf)
					} else if (expression.dimension.isNotEmpty) {
						chunks += ctx.computeTmp(expression.nameOfTmpArray(ctx.container), expression.fullSizeOf)
					}
				}

				if (expression.type.isNonPrimitive) {
					val snapshot = ctx.snapshot
					val constructorName = expression.nameOfConstructor

					ctx.container = constructorName

					chunks += ctx.computePtr(expression.nameOfReceiver)
					chunks += expression.fieldsInitializedOnContructor.map[value.alloc(ctx)].flatten
					chunks.disoverlap(constructorName)

					ctx.restoreTo(snapshot)
					ctx.constructors += expression

					if (expression.constructor !== null) {
						chunks += expression.constructor.fields.map[variable.value.alloc(ctx)].flatten
					}
				}

				return chunks
			}
			MemberSelect: {
				val snapshot = ctx.snapshot
				val chunks = newArrayList

				if (expression.isMethodInvocation) {
					val method = expression.member as Method

					if (method.isDispose) {
						expression.receiver.dispose(ctx)
						return chunks
					}

					val methodChunks = method.alloc(ctx)

					if (method.isNonStatic) {
						chunks += expression.receiver.alloc(ctx)
					}

					chunks += expression.args.map[alloc(ctx)].flatten
					chunks += methodChunks
				} else if (expression.member instanceof Variable) {
					val variable = expression.member as Variable

					if (variable.isNonStatic) {
						chunks += expression.receiver.alloc(ctx)
					}

					if (expression.indexes.isNotEmpty) {
						chunks += expression.indexes.map[value.alloc(ctx)].flatten
						chunks += ctx.computeTmp(expression.indexes.nameOfTmp(ctx.container), 1)
					}

					chunks += variable.alloc(ctx)
				}

				chunks.disoverlap(ctx.container)

				ctx.restoreTo(snapshot)

				return chunks
			}
			MemberRef: {
				val snapshot = ctx.snapshot
				val chunks = newArrayList

				if (expression.isMethodInvocation) {
					val methodChunks = (expression.member as Method).alloc(ctx)
					chunks += expression.args.map[alloc(ctx)].flatten
					chunks += methodChunks
				}

				if (expression.indexes.isNotEmpty) {
					chunks += expression.indexes.map[value.alloc(ctx)].flatten
					chunks += ctx.computeTmp(expression.indexes.nameOfTmp(ctx.container), 1)
				}

				chunks.disoverlap(ctx.container)

				ctx.restoreTo(snapshot)

				return chunks
			}
			default:
				newArrayList
		}
	}

	def dispose(Expression expression, AllocContext ctx) {
		if (expression instanceof MemberRef) {
			expression.member.dispose(ctx)
		}
	}

	def String compile(Expression expression, CompileContext ctx) {
		try {
			val value = new CompileContext => [
				container = ctx?.container
				operation = ctx?.operation
				type = ctx?.type
				immediate = expression.compileConstant
			]
			value.resolveTo(ctx)?.toString
		} catch (NonConstantExpressionException e) {
			switch (expression) {
				AssignmentExpression: '''
					«val ref = new CompileContext => [
						container = ctx.container
						operation = ctx.operation
						type = expression.left.typeOf
						mode = Mode::REFERENCE
					]»
					«expression.left.compile(ref)»
					«IF expression.assignment === AssignmentType::ASSIGN»
						«expression.right.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::ADD_ASSIGN»
						«val add = NoopFactory::eINSTANCE.createAddExpression => [
							left = expression.left
							right = expression.right
						]»
						«add.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::SUB_ASSIGN»
						«val sub = NoopFactory::eINSTANCE.createSubExpression => [
							left = expression.left
							right = expression.right
						]»
						«sub.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::MUL_ASSIGN»
						«val mul = NoopFactory::eINSTANCE.createMulExpression => [
							left = expression.left
							right = expression.right
						]»
						«mul.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::DIV_ASSIGN»
						«val div = NoopFactory::eINSTANCE.createDivExpression => [
							left = expression.left
							right = expression.right
						]»
						«div.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BOR_ASSIGN»
						«val bor = NoopFactory::eINSTANCE.createBOrExpression => [
							left = expression.left
							right = expression.right
						]»
						«bor.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BAN_ASSIGN»
						«val ban = NoopFactory::eINSTANCE.createBAndExpression => [
							left = expression.left
							right = expression.right
						]»
						«ban.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BLS_ASSIGN»
						«val bls = NoopFactory::eINSTANCE.createLShiftExpression => [
							left = expression.left
							right = expression.right
						]»
						«bls.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BRS_ASSIGN»
						«val brs = NoopFactory::eINSTANCE.createRShiftExpression => [
							left = expression.left
							right = expression.right
						]»
						«brs.compile(ref => [mode = Mode::COPY])»
					«ENDIF»
					«ref.resolveTo(ctx)»
				'''
				OrExpression: '''«expression.left.compileOr(expression.right, ctx)»'''
				AndExpression: '''«expression.left.compileAnd(expression.right, ctx)»'''
				EqualsExpression: '''«Operation::COMPARE_EQ.compileBinary(expression.left, expression.right, ctx)»'''
				DifferExpression: '''«Operation::COMPARE_NE.compileBinary(expression.left, expression.right, ctx)»'''
				LtExpression: '''«Operation::COMPARE_LT.compileBinary(expression.left, expression.right, ctx)»'''
				LeExpression: '''«Operation::COMPARE_GE.compileBinary(expression.right, expression.left, ctx)»'''
				GtExpression: '''«Operation::COMPARE_LT.compileBinary(expression.right, expression.left, ctx)»'''
				GeExpression: '''«Operation::COMPARE_GE.compileBinary(expression.left, expression.right, ctx)»'''
				AddExpression: '''«Operation::ADDITION.compileBinary(expression.left, expression.right, ctx)»'''
				SubExpression: '''«Operation::SUBTRACTION.compileBinary(expression.left, expression.right, ctx)»'''
				MulExpression: '''«expression.left.compileMultiplication(expression.right, ctx)»'''
				DivExpression: '''«expression.left.compileDivision(expression.right, ctx)»'''
				BOrExpression: '''«Operation::BIT_OR.compileBinary(expression.left, expression.right, ctx)»'''
				BAndExpression: '''«Operation::BIT_AND.compileBinary(expression.left, expression.right, ctx)»'''
				LShiftExpression: '''«Operation::BIT_SHIFT_LEFT.compileBinary(expression.left, expression.right, ctx)»'''
				RShiftExpression: '''«Operation::BIT_SHIFT_RIGHT.compileBinary(expression.left, expression.right, ctx)»'''
				EorExpression: '''«Operation::BIT_EXCLUSIVE_OR.compileUnary(expression.right, ctx)»'''
				NotExpression: '''«expression.right.compileNot(ctx)»'''
				SigNegExpression: '''«Operation::SIGNUM.compileUnary(expression.right, ctx)»'''
				SigPosExpression: '''«expression.right.compile(ctx)»'''
				DecExpression: '''«Operation::DECREMENT.compileInc(expression.right, ctx)»'''
				IncExpression: '''«Operation::INCREMENT.compileInc(expression.right, ctx)»'''
				CastExpression: '''«expression.left.compile(ctx)»'''
				InheritsExpression: ''';TODO: inherits'''
				ByteLiteral: '''
					«IF ctx.db !== null»
						«val bytes = expression.valueOf.toBytes»
						«ctx.relative»:
							«IF ctx.sizeOf == 1»
								.db «bytes.head.toHex»
							«ELSE»
								.db «bytes.join(' ', [toHex])»
							«ENDIF»
					«ELSE»
						«val src = new CompileContext => [
						type = expression.typeOf
						immediate = expression.value.toHex.toString
					]»
						«src.resolveTo(ctx)»
					«ENDIF»
				'''
				BoolLiteral: '''
					«val boolAsByte = NoopFactory::eINSTANCE.createByteLiteral => [value = if (expression.value) 1 else 0]»
					«boolAsByte.compile(ctx)»
				'''
				StringLiteral: '''
					«IF ctx.db !== null»
						«ctx.db»:
							«IF expression.value.toLowerCase.startsWith(Members::FILE_SCHEMA)»
								«val filepath = new File(expression.eResource.URI.resFolder, expression.value.substring(Members::FILE_SCHEMA.length)).absolutePath»
								«IF expression.isAsmFile || expression.isIncFile»
									.include "«filepath»"
								«ELSE»
									.incbin "«filepath»"
								«ENDIF»
							«ELSE»
								.db «expression.value.toBytes.join(', ', [toHex])»
							«ENDIF»
					«ELSEIF ctx.absolute !== null»
						«ctx.pushAccIfOperating»
						«val bytes = expression.value.bytes.map[intValue]»
							«IF ctx.isIndexed»
								LDX «ctx.index»
							«ENDIF»
							«FOR i : 0 ..< bytes.size»
								LDA #«bytes.get(i).toHex»
								STA «ctx.absolute»«IF i > 0» + «i»«ENDIF»«IF ctx.isIndexed», X«ENDIF»
							«ENDFOR»
						«ctx.pullAccIfOperating»
					«ELSEIF ctx.indirect !== null»
						«ctx.pushAccIfOperating»
						«val bytes = expression.value.bytes.map[intValue]»
							«IF ctx.isIndexed»
								LDY «ctx.index»
							«ELSE»
								LDY #$00
							«ENDIF»
							«FOR i : 0 ..< bytes.size»
								«IF i > 0»
									INY
								«ENDIF»
								LDA #«bytes.get(i).toHex»
								STA («ctx.indirect»), Y
							«ENDFOR»
						«ctx.pullAccIfOperating»
					«ENDIF»
				'''
				ArrayLiteral: '''
					«IF ctx.db !== null»
						«ctx.db»:
						«val bytes = expression.valueOf.toBytes»
						«val chunks = (bytes.size / 32).max(1) + if (bytes.size > 32 && bytes.size % 32 != 0) 1 else 0»
							«FOR i : 0..< chunks»
								«val from = i * 32»
								«val to = (from + 32).min(bytes.size)»
								.db «bytes.subList(from, to).join(', ', [toHex])»
							«ENDFOR»
					«ELSE»
						«val tmp = if (expression.isOnMemberSelectionOrReference) {
									new CompileContext => [
											container = ctx.container
											operation = ctx.operation
											absolute = expression.nameOfTmp(ctx.container)
											type = ctx.type
										]
									} else {
										ctx.clone
									}
						»
						«val elements = expression.flatList»
						«FOR i : 0 ..< elements.size»
							«val dst = tmp.clone»
							«IF i > 0»
								«IF dst.absolute !== null»
									«dst.absolute = '''«dst.absolute» + «i * expression.sizeOf»'''»
								«ELSEIF dst.indirect !== null && dst.index.startsWith('#')»
									«dst.index = '''«dst.index» + «i * expression.sizeOf»'''»
								«ELSEIF dst.indirect !== null && dst.isIndexed»
									«ctx.pushAccIfOperating»
										CLC
										LDA «dst.index»
										ADC #«expression.sizeOf.toHex»
										STA «dst.index»
									«ctx.pullAccIfOperating»
								«ELSEIF dst.indirect !== null»
									«dst.index = '''#«(i * expression.sizeOf).toHex»'''»
								«ENDIF»
							«ENDIF»
							«elements.get(i).compile(dst)»
						«ENDFOR»
						«IF expression.isOnMemberSelectionOrReference && ctx.mode === Mode::POINT»
							«ctx.pointTo(tmp)»
						«ENDIF»
					«ENDIF»
				'''
				This: '''
					«expression.compileSelfReference(ctx)»
				'''
				Super: '''
					«expression.compileSelfReference(ctx)»
				'''
				NewInstance: '''
					«IF ctx === null»
						«val constructor = expression.nameOfConstructor»
						«val receiver = expression.nameOfReceiver»
						«constructor»:
							LDY #$00
							LDA #«expression.type.asmName»
							STA («receiver»), Y
						«FOR field : expression.fieldsInitializedOnContructor»
							«field.compile(new CompileContext => [
								container = constructor
								indirect = receiver
							])»
						«ENDFOR»
						«noop»
							RTS
					«ELSEIF expression.dimension.isNotEmpty»
						;TODO: compile array constructor call
					«ELSEIF expression.type.isPrimitive»
						«val defaultByte = NoopFactory::eINSTANCE.createByteLiteral => [value = 0]»
						«defaultByte.compile(ctx)»
					«ELSE»
						«val constructor = expression.nameOfConstructor»
						«val receiver = new CompileContext => [
							operation = ctx.operation
							indirect = expression.nameOfReceiver
						]»
						«IF expression.isOnMemberSelectionOrReference»
							«val tmp = new CompileContext => [
								operation = ctx.operation
								absolute = expression.nameOfTmpVar(ctx.container)
							]»
							«IF ctx.mode === Mode::POINT»
								«ctx.pointTo(tmp)»
							«ELSEIF ctx.mode == Mode::REFERENCE»
								«tmp.referenceInto(ctx)»
							«ENDIF»
							«receiver.pointTo(tmp)»
						«ELSE»
							«receiver.pointTo(ctx)»
						«ENDIF»
						«ctx.pushAccIfOperating»
							JSR «constructor»
						«FOR field : expression.constructor?.fields ?: emptyList»
							«field.value.compile(new CompileContext => [
								container = constructor
								operation = ctx.operation
								indirect = receiver.indirect									
								index = '''#«field.variable.nameOfOffset»'''
								type = field.variable.typeOf
							])»
						«ENDFOR»
						«ctx.pullAccIfOperating»
					«ENDIF»	
				'''
				MemberSelect: '''
					«val member = expression.member»
					«val receiver = expression.receiver»
					«IF member.isStatic»
						«IF !(receiver instanceof NewInstance)»
							«receiver.compile(new CompileContext => [
								container = ctx.container
								operation = ctx.operation
							])»
						«ENDIF»
						«IF member instanceof Variable»
							«IF member.isConstant»
								«member.compileConstantReference(ctx)»
							«ELSE»
								«member.compileStaticReference(expression.indexes, ctx)»
							«ENDIF»
						«ELSEIF member instanceof Method»
							«val method = member as Method»
							«method.compileInvocation(expression.args, ctx)»
						«ENDIF»
					«ELSE»
						«IF member instanceof Variable»
							«val rcv = new CompileContext => [
								container = ctx.container
								operation = ctx.operation
								type = receiver.typeOf
								mode = Mode::REFERENCE
							]»
							«receiver.compile(rcv)»
							«IF rcv.absolute !== null»
								«member.compileAbsoluteReference(rcv, expression.indexes, ctx)»
							«ELSEIF rcv.indirect !== null»
								«member.compileIndirectReference(rcv, expression.indexes, ctx)»
							«ENDIF»
						«ELSEIF member instanceof Method»
							«val method = member as Method»
							«receiver.compile(new CompileContext => [
								container = ctx.container
								operation = ctx.operation
								indirect = method.nameOfReceiver
								type = receiver.typeOf
								mode = Mode::POINT
							])»
							«method.compileInvocation(expression.args, ctx)»
						«ENDIF»
					«ENDIF»
				'''
				MemberRef: '''
					«val member = expression.member»
					«IF member instanceof Variable»
						«IF member.isField && member.isNonStatic»
							«member.compilePointerReference('''«ctx.container».rcv''', expression.indexes, ctx)»
						«ELSEIF member.isParameter && (member.type.isNonPrimitive || member.dimensionOf.isNotEmpty)»
							«member.compilePointerReference(member.nameOf, expression.indexes, ctx)»
						«ELSEIF member.isConstant»
							«member.compileConstantReference(ctx)»
						«ELSEIF member.isStatic»
							«member.compileStaticReference(expression.indexes, ctx)»
						«ELSE»
							«member.compileLocalReference(expression.indexes, ctx)»
						«ENDIF»
					«ELSEIF member instanceof Method»
						«val method = member as Method»
						«IF method.isNonStatic»
							«val outerReceiver = new CompileContext => [
								operation = ctx.operation
								indirect = '''«ctx.container».rcv'''
							]»
							«val innerReceiver = new CompileContext => [
								operation = ctx.operation
								indirect = method.nameOfReceiver
							]»
							«innerReceiver.pointTo(outerReceiver)»
						«ENDIF»
						«method.compileInvocation(expression.args, ctx)»
					«ENDIF»					
				'''
				default:
					''
			}
		}
	}

	def String compileConstant(Expression expression) {
		val text = NodeModelUtils.findActualNodeFor(expression)?.text?.trim ?: ''
		val wrapped = text.startsWith('(') && text.endsWith(')')

		try {
			switch (expression) {
				OrExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» || «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				AndExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» && «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				EqualsExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» == «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				DifferExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» != «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				GtExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» > «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				GeExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» >= «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				LtExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» < «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				LeExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» <= «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				AddExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» + «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				SubExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» - «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				MulExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» * «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				DivExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» / «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				BOrExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» | «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				BAndExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» & «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				LShiftExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» << «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				RShiftExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» >> «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				EorExpression: '''«IF wrapped»(«ENDIF»~«expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				NotExpression: '''«IF wrapped»(«ENDIF»!«expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				SigNegExpression: '''«IF wrapped»(«ENDIF»-«expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				SigPosExpression: '''«IF wrapped»(«ENDIF»+«expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				CastExpression:
					expression.left.compileConstant
				ByteLiteral:
					expression.value.toString
				BoolLiteral:
					expression.value.toString.toUpperCase
				NewInstance:
					if (expression.type.isPrimitive) {
						expression.type.defaultValueOf.toString.toUpperCase
					} else {
						throw new NonConstantExpressionException(expression)
					}
				MemberSelect:
					expression.member.compileConstant
				MemberRef:
					expression.member.compileConstant
				default:
					throw new NonConstantExpressionException(expression)
			}
		} catch (NonConstantMemberException e) {
			throw new NonConstantExpressionException(expression)
		} catch (ClassCastException e) {
			throw new InvalidExpressionException(expression)
		}
	}

	private def compileInc(Operation incOperation, Expression expression, CompileContext ctx) '''
		«val inc = new CompileContext => [
				container = ctx.container
				type = expression.typeOf
				operation = incOperation
				mode = Mode::OPERATE
			]»
		«expression.compile(inc)»
		«expression.compile(ctx)»
	'''

	private def compileBinary(Operation binaryOperation, Expression left, Expression right, CompileContext ctx) '''
		«val lda = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			type = if (binaryOperation.isComparisonOrMultiplication) left.typeOf else ctx.type //if (ctx.type.isBoolean) left.typeOf else ctx.type
			register = 'A'
			mode = Mode::COPY
		]»
		«val opr = new CompileContext => [
			container = ctx.container
			operation = binaryOperation
			relative = ctx.relative
			type = if (binaryOperation.isComparisonOrMultiplication) left.typeOf else ctx.type //if (ctx.type.isBoolean) left.typeOf else ctx.type
			opType = ctx.type
			accLoaded = true
			mode = Mode::OPERATE
		]»
		«IF ctx.operation !== null && ctx.isAccLoaded»
			«ctx.accLoaded = false»
				PHA
		«ENDIF»
		«left.compile(lda)»
		«right.compile(opr)»
		«IF ctx.mode === Mode::OPERATE»
			«ctx.accLoaded = true»
				«FOR i : 0..< lda.sizeOf»
					STA «Members::TEMP_VAR_NAME2»«IF i > 0» + «i»«ENDIF»
					PLA
				«ENDFOR»
			«val tmp = new CompileContext => [
				container = ctx.container
				type = lda.type
				opType = ctx.type
				absolute = Members::TEMP_VAR_NAME2
			]»
			«ctx.operateOn(tmp)»
		«ELSEIF ctx.mode === Mode::COPY && ctx.relative === null»
			«val res = new CompileContext => [
				container = ctx.container
				type = ctx.type
				register = 'A'
			]»
			«res.copyTo(ctx)»
		«ENDIF»
	'''

	private def compileMultiplication(Expression left, Expression right, CompileContext ctx) {
		try {
			val const = NoopFactory::eINSTANCE.createByteLiteral => [value = left.valueOf as Integer]
			Operation::MULTIPLICATION.compileBinary(const, right, ctx)
		} catch (NonConstantExpressionException exception) {
			try {
				val const = NoopFactory::eINSTANCE.createByteLiteral => [value = right.valueOf as Integer]
				Operation::MULTIPLICATION.compileBinary(left, const, ctx)
			} catch (NonConstantExpressionException exception2) {
				Operation::MULTIPLICATION.compileBinary(left, right, ctx)
			}
		}
	}
	
	private def compileDivision(Expression left, Expression right, CompileContext ctx) {
		try {
			val const = NoopFactory::eINSTANCE.createByteLiteral => [value = left.valueOf as Integer]
			Operation::DIVISION.compileBinary(const, right, ctx)
		} catch (NonConstantExpressionException exception) {
			try {
				val const = NoopFactory::eINSTANCE.createByteLiteral => [value = right.valueOf as Integer]
				Operation::DIVISION.compileBinary(left, const, ctx)
			} catch (NonConstantExpressionException exception2) {
				Operation::DIVISION.compileBinary(left, right, ctx)
			}
		}
	}

	private def compileOr(Expression left, Expression right, CompileContext ctx) '''
		«val lctx = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			relative = ctx.relative ?: '''orIsTrue@«right.hashCode.toHexString»'''
			type = if (ctx.type.isBoolean) left.typeOf else ctx.type
		]»
		«val rctx = new CompileContext => [
			container = ctx.container
			relative = ctx.relative ?: '''orIsTrue@«right.hashCode.toHexString»'''
			type = if (ctx.type.isBoolean) left.typeOf else ctx.type
		]»
		«left.compile(lctx)»
		«right.compile(rctx)»
		«IF ctx.relative === null»
			+orIsFalse@«right.hashCode.toHexString»:
				LDA #«Members::FALSE»
				JMP +orEnd
			+orIsTrue@«right.hashCode.toHexString»:
				LDA #«Members::TRUE»
			+orEnd:
			«IF ctx.mode === Mode::COPY»
				«val res = new CompileContext => [
					container = ctx.container
					type = ctx.type
					register = 'A'
				]»
				«res.copyTo(ctx)»
			«ENDIF»
		«ENDIF»
	'''

	private def CharSequence compileAnd(Expression left, Expression right, CompileContext ctx) '''
		«val lctx = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			relative = '''andIsFalse@«right.hashCode.toHexString»'''
			type = if (ctx.type.isBoolean) left.typeOf else ctx.type
		]»
		«val rctx = new CompileContext => [
			container = ctx.container
			relative = ctx.relative ?: '''andIsTue@«right.hashCode.toHexString»'''
			type = if (ctx.type.isBoolean) left.typeOf else ctx.type
		]»
		«left.compileNot(lctx)»
		«right.compile(rctx)»
		+andIsFalse@«right.hashCode.toHexString»:
		«IF ctx.relative === null»
			«noop»
				LDA #«Members::FALSE»
				JMP +andEnd
			+andIsTue@«right.hashCode.toHexString»:
				LDA #«Members::TRUE»
			+andEnd:
			«IF ctx.mode === Mode::COPY»
				«val res = new CompileContext => [
					container = ctx.container
					type = ctx.type
					register = 'A'
				]»
				«res.copyTo(ctx)»
			«ENDIF»
		«ENDIF»
	'''

	private def compileUnary(Operation unaryOperation, Expression expr, CompileContext ctx) '''
		«val lda = new CompileContext => [
			container = ctx.container
			type = ctx.type
			register = 'A'
			mode = Mode::COPY
		]»
		«val acc = new CompileContext => [
			container = ctx.container
			relative = ctx.relative
			type = ctx.type
			operation = unaryOperation
			mode = Mode::OPERATE
		]»
		«IF ctx.operation !== null && ctx.isAccLoaded»
			«ctx.accLoaded = false»
				PHA
		«ENDIF» 
		«expr.compile(lda)»
		«acc.operate»
		«IF ctx.mode === Mode::OPERATE»
			«FOR i : 0 ..< ctx.sizeOf»
				«ctx.accLoaded = true»
					STA «Members::TEMP_VAR_NAME2»«IF i > 0» + «i»«ENDIF»
					PLA
			«ENDFOR»
			«val tmp = new CompileContext => [
					container = ctx.container
					type = ctx.type
					opType = ctx.type
					absolute = Members::TEMP_VAR_NAME2
				]»
			«ctx.operateOn(tmp)»
		«ELSEIF ctx.mode === Mode::COPY && ctx.relative === null»
			«val res = new CompileContext => [
				container = ctx.container
				type = ctx.type
				register = 'A'
			]»
			«res.copyTo(ctx)»
		«ENDIF»
	'''

	private def compileNot(Expression expr, CompileContext ctx) {
		switch (expr) {
			OrExpression:
				compileAnd(NoopFactory::eINSTANCE.createNotExpression => [
					right = expr.left
				], NoopFactory::eINSTANCE.createNotExpression => [
					right = expr.right
				], ctx)
			AndExpression:
				compileOr(NoopFactory::eINSTANCE.createNotExpression => [
					right = expr.left
				], NoopFactory::eINSTANCE.createNotExpression => [
					right = expr.right
				], ctx)
			EqualsExpression:
				Operation::COMPARE_NE.compileBinary(expr.left, expr.right, ctx)
			DifferExpression:
				Operation::COMPARE_EQ.compileBinary(expr.left, expr.right, ctx)
			LtExpression:
				Operation::COMPARE_GE.compileBinary(expr.left, expr.right, ctx)
			LeExpression:
				Operation::COMPARE_LT.compileBinary(expr.right, expr.left, ctx)
			GtExpression:
				Operation::COMPARE_GE.compileBinary(expr.right, expr.left, ctx)
			GeExpression:
				Operation::COMPARE_LT.compileBinary(expr.left, expr.right, ctx)
			NotExpression:
				expr.compile(ctx)
			default:
				Operation::NEGATION.compileUnary(expr, ctx)
		}
	}

	private def compileSelfReference(Expression expression, CompileContext ctx) '''
		«val method = expression.getContainerOfType(Method)»
		«val instance = new CompileContext => [
			container = method.nameOf
			operation = ctx.operation
			type = expression.typeOf
			indirect = method.nameOfReceiver
		]»
		«IF ctx.mode === Mode::COPY»
			«instance.copyTo(ctx)»
		«ELSEIF ctx.mode === Mode::POINT»
			«ctx.pointTo(instance)»
		«ELSEIF ctx.mode === Mode::REFERENCE»
			«instance.referenceInto(ctx)»
		«ENDIF»
	'''

	private def void noop() {
	}

}
