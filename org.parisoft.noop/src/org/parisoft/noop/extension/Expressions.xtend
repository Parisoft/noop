package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.stream.Collectors
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.CompileData
import org.parisoft.noop.generator.CompileData.Operation
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.generator.NoopInstance
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.BAndExpression
import org.parisoft.noop.noop.BOrExpression
import org.parisoft.noop.noop.BoolLiteral
import org.parisoft.noop.noop.ByteLiteral
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
import org.parisoft.noop.noop.LShiftExpression
import org.parisoft.noop.noop.LeExpression
import org.parisoft.noop.noop.LtExpression
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
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
import org.parisoft.noop.generator.CompileData.Mode
import org.parisoft.noop.noop.CastExpression
import org.parisoft.noop.noop.InheritsExpression
import org.parisoft.noop.noop.AssignmentType

class Expressions {

	static val FILE_URI = 'file://'

	@Inject extension Datas
	@Inject extension Values
	@Inject extension Classes
	@Inject extension Members
	@Inject extension Operations
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Collections

	def isMethodInvocation(MemberSelection selection) {
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
		container !== null && (container instanceof MemberSelection || container instanceof MemberRef)
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
				expression.containingClass
			Super:
				expression.containingClass.superClassOrObject
			NewInstance:
				expression.type
			MemberSelection:
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
				AssignmentExpression:
					expression.right.valueOf
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
				InheritsExpression:
					throw new NonConstantExpressionException(expression)
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
				IncExpression:
					(expression.right.valueOf as Integer) + 1
				DecExpression:
					(expression.right.valueOf as Integer) - 1
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
						new NoopInstance(expression.type.name, expression.type.allFieldsBottomUp, expression.constructor)
					} else {
						expression.type.defaultValueOf
					}
				MemberSelection:
					expression.member.valueOf
				MemberRef:
					expression.member.valueOf
				default:
//			    This: 
//			    Super:
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
			ArrayLiteral:
				expression.valueOf.dimensionOf
			MemberSelection:
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

	def void prepare(Expression expression, AllocData data) {
		switch (expression) {
			AssignmentExpression:
				expression.right.prepare(data)
			OrExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			AndExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			EqualsExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			DifferExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			GtExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			GeExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			LtExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			LeExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			InheritsExpression: {
				expression.left.prepare(data)
				expression.type.prepare(data)
			}
			AddExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			SubExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			MulExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			DivExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			BOrExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			BAndExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			LShiftExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			RShiftExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			EorExpression:
				expression.right.prepare(data)
			NotExpression:
				expression.right.prepare(data)
			SigNegExpression:
				expression.right.prepare(data)
			SigPosExpression:
				expression.right.prepare(data)
			DecExpression:
				expression.right.prepare(data)
			IncExpression:
				expression.right.prepare(data)
			CastExpression:
				expression.type.prepare(data)
			ArrayLiteral:
				expression.typeOf.prepare(data)
			NewInstance:
				if (expression.type.isINESHeader) {
					data.header = expression
				} else {
					expression.type.prepare(data)

					if (expression.type.isNonPrimitive) {
						expression.fieldsInitializedOnContructor.forEach[prepare(data)]
					}
				}
			MemberSelection: {
				expression.receiver.prepare(data)

				if (expression.member instanceof Variable) {
					(expression.member as Variable).prepare(data)
				} else if (expression.member instanceof Method) {
					(expression.member as Method).prepare(data)
				}

				expression.indexes.forEach[value.prepare(data)]
			}
			MemberRef: {
				if (expression.member instanceof Variable) {
					(expression.member as Variable).prepare(data)
				} else if (expression.member instanceof Method) {
					(expression.member as Method).prepare(data)
				}

				expression.indexes.forEach[value.prepare(data)]
			}
		}
	}

	def List<MemChunk> alloc(Expression expression, AllocData data) {
		switch (expression) {
			AssignmentExpression:
				expression.right.alloc(data)
			OrExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			AndExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			EqualsExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			DifferExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			GtExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			GeExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			LtExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			LeExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			InheritsExpression:
				expression.left.alloc(data)
			AddExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			SubExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			MulExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			DivExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			BOrExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			BAndExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			LShiftExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			RShiftExpression:
				(expression.left.alloc(data) + expression.right.alloc(data)).toList
			EorExpression:
				expression.right.alloc(data)
			NotExpression:
				expression.right.alloc(data)
			SigNegExpression:
				expression.right.alloc(data)
			SigPosExpression:
				expression.right.alloc(data)
			DecExpression:
				expression.right.alloc(data)
			IncExpression:
				expression.right.alloc(data)
			CastExpression:
				expression.left.alloc(data)
			ArrayLiteral: {
				val chunks = expression.values.map[alloc(data)].flatten.toList

				if (expression.isOnMemberSelectionOrReference) {
					chunks += data.computeTmp(expression.nameOfTmp(data.container), expression.fullSizeOf)
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
						chunks += data.computeTmp(expression.nameOfTmpVar(data.container), expression.sizeOf)
					} else if (expression.dimension.isNotEmpty) {
						chunks += data.computeTmp(expression.nameOfTmpArray(data.container), expression.fullSizeOf)
					}
				}

				if (expression.type.isNonPrimitive) {
					val snapshot = data.snapshot
					val constructorName = expression.nameOfConstructor

					data.container = constructorName

					chunks += data.computePtr(expression.nameOfReceiver)
					chunks += expression.fieldsInitializedOnContructor.map[value.alloc(data)].flatten
					chunks.disoverlap(constructorName)

					data.restoreTo(snapshot)
					data.constructors += expression

					if (expression.constructor !== null) {
						chunks += expression.constructor.fields.map[variable.value.alloc(data)].flatten
					}
				}

				return chunks
			}
			MemberSelection: {
				val snapshot = data.snapshot
				val chunks = newArrayList

				if (expression.isMethodInvocation) {
					val method = expression.member as Method

					if (method.isDispose) {
						expression.receiver.dispose(data)
						return chunks
					}

					val methodChunks = method.alloc(data)

					if (method.isNonStatic) {
						chunks += expression.receiver.alloc(data)
					}

					chunks += expression.args.map[alloc(data)].flatten
					chunks += methodChunks
				} else if (expression.member instanceof Variable) {
					val variable = expression.member as Variable

					if (variable.isNonStatic) {
						chunks += expression.receiver.alloc(data)
					}

					if (expression.indexes.isNotEmpty) {
						chunks += expression.indexes.map[value.alloc(data)].flatten
						chunks += data.computeTmp(expression.indexes.nameOfTmp(data.container), 1)
					}

					chunks += variable.alloc(data)
				}

				chunks.disoverlap(data.container)

				data.restoreTo(snapshot)

				return chunks
			}
			MemberRef: {
				val snapshot = data.snapshot
				val chunks = newArrayList

				if (expression.isMethodInvocation) {
					val methodChunks = (expression.member as Method).alloc(data)
					chunks += expression.args.map[alloc(data)].flatten
					chunks += methodChunks
				}

				if (expression.indexes.isNotEmpty) {
					chunks += expression.indexes.map[value.alloc(data)].flatten
					chunks += data.computeTmp(expression.indexes.nameOfTmp(data.container), 1)
				}

				chunks.disoverlap(data.container)

				data.restoreTo(snapshot)

				return chunks
			}
			default:
				newArrayList
		}
	}

	def dispose(Expression expression, AllocData data) {
		if (expression instanceof MemberRef) {
			expression.member.dispose(data)
		}
	}

	def String compile(Expression expression, CompileData data) {
		switch (expression) {
			AssignmentExpression: '''
				«val ref = new CompileData => [
					container = data.container
					operation = data.operation
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
				«ref.transferTo(data)»
			'''
			OrExpression: '''«Operation::OR.compileBinary(expression.left, expression.right, data)»'''
			AndExpression: '''«Operation::AND.compileBinary(expression.left, expression.right, data)»'''
			EqualsExpression: '''«Operation::COMPARE_EQ.compileBinary(expression.left, expression.right, data)»'''
			DifferExpression: '''«Operation::COMPARE_NE.compileBinary(expression.left, expression.right, data)»'''
			LtExpression: '''«Operation::COMPARE_LT.compileBinary(expression.left, expression.right, data)»'''
			LeExpression: '''«Operation::COMPARE_GE.compileBinary(expression.right, expression.left, data)»'''
			GtExpression: '''«Operation::COMPARE_LT.compileBinary(expression.right, expression.left, data)»'''
			GeExpression: '''«Operation::COMPARE_GE.compileBinary(expression.left, expression.right, data)»'''
			AddExpression: '''«Operation::ADDITION.compileBinary(expression.left, expression.right, data)»'''
			SubExpression: '''«Operation::SUBTRACTION.compileBinary(expression.left, expression.right, data)»'''
			BOrExpression: '''«Operation::BIT_OR.compileBinary(expression.left, expression.right, data)»'''
			BAndExpression: '''«Operation::BIT_AND.compileBinary(expression.left, expression.right, data)»'''
			LShiftExpression: '''«Operation::BIT_SHIFT_LEFT.compileBinary(expression.left, expression.right, data)»'''
			RShiftExpression: '''«Operation::BIT_SHIFT_RIGHT.compileBinary(expression.left, expression.right, data)»'''
			EorExpression: '''«Operation::BIT_EXCLUSIVE_OR.compileUnary(expression.right, data)»'''
			NotExpression: '''«Operation::NEGATION.compileUnary(expression.right, data)»'''
			SigNegExpression: '''«Operation::SIGNUM.compileUnary(expression.right, data)»'''
			SigPosExpression: '''«expression.right.compile(data)»'''
			DecExpression: '''«Operation::DECREMENT.compileInc(expression.right, data)»'''
			IncExpression: '''«Operation::INCREMENT.compileInc(expression.right, data)»'''
			CastExpression: '''«expression.left.compile(data)»'''
			InheritsExpression: ''';TODO: inherits'''
			ByteLiteral: '''
				«IF data.relative !== null»
					«val bytes = expression.valueOf.toBytes»
					«data.relative»:
						«IF data.sizeOf == 1»
							.db «bytes.head.toHex»
						«ELSE»
							.db «bytes.join(' ', [toHex])»
						«ENDIF»
				«ELSE»
					«val src = new CompileData => [
						type = expression.typeOf
						immediate = expression.value.toHex.toString
					]»
					«src.transferTo(data)»
				«ENDIF»
			'''
			BoolLiteral: '''
				«val boolAsByte = NoopFactory::eINSTANCE.createByteLiteral => [value = if (expression.value) 1 else 0]»
				«boolAsByte.compile(data)»
			'''
			StringLiteral: '''
				«IF data.relative !== null»
					«data.relative»:
						«IF expression.value.startsWith(FILE_URI)»
							.incbin "«expression.value.substring(FILE_URI.length)»"
						«ELSE»
							.db «expression.value.toBytes.join(', ', [toHex])»
						«ENDIF»
				«ELSEIF data.absolute !== null»
					«data.pushAccIfOperating»
					«val bytes = expression.value.bytes»
						«IF data.isIndexed»
							LDX «data.index»
						«ENDIF»
						«FOR i : 0 ..< bytes.size»
							LDA #«bytes.get(i).toHex»
							STA «data.absolute»«IF i > 0» + «i»«ENDIF»«IF data.isIndexed», X«ENDIF»
						«ENDFOR»
					«data.pullAccIfOperating»
				«ELSEIF data.indirect !== null»
					«data.pushAccIfOperating»
					«val bytes = expression.value.bytes»
						«IF data.isIndexed»
							LDY «data.index»
						«ELSE»
							LDY #$00
						«ENDIF»
						«FOR i : 0 ..< bytes.size»
							«IF i > 0»
								INY
							«ENDIF»
							LDA #«bytes.get(i).toHex»
							STA («data.indirect»), Y
						«ENDFOR»
					«data.pullAccIfOperating»
				«ENDIF»
			'''
			ArrayLiteral: '''
				«IF data.relative !== null»
					«data.relative»:
						.db «expression.valueOf.toBytes.join(', ', [toHex])»
				«ELSE»
					«val tmp = if (expression.isOnMemberSelectionOrReference) {
						new CompileData => [
							container = data.container
							operation = data.operation
							absolute = expression.nameOfTmp(data.container)
							type = data.type
						]
					} else {
						data.clone
					}»
					«val elements = expression.flatList»
					«FOR i : 0 ..< elements.size»
						«val dst = tmp.clone»
						«IF i > 0»
							«IF dst.absolute !== null»
								«dst.absolute = '''«dst.absolute» + «i * expression.sizeOf»'''»
							«ELSEIF dst.indirect !== null && dst.index.startsWith('#')»
								«dst.index = '''«dst.index» + «i * expression.sizeOf»'''»
							«ELSEIF dst.indirect !== null && dst.isIndexed»
								«data.pushAccIfOperating»
									CLC
									LDA «dst.index»
									ADC #«expression.sizeOf.byteValue.toHex»
									STA «dst.index»
								«data.pullAccIfOperating»
							«ELSEIF dst.indirect !== null»
								«dst.index = '''#«(i * expression.sizeOf).byteValue.toHex»'''»
							«ENDIF»
						«ENDIF»
						«elements.get(i).compile(dst)»
					«ENDFOR»
					«IF expression.isOnMemberSelectionOrReference && data.mode === Mode::POINT»
						«data.pointTo(tmp)»
					«ENDIF»
				«ENDIF»
			'''
			This: '''
				«expression.compileSelfReference(data)»
			'''
			Super: '''
				«expression.compileSelfReference(data)»
			'''
			NewInstance: '''
				«IF data === null»
					«val constructor = expression.nameOfConstructor»
					«val receiver = expression.nameOfReceiver»
					«constructor»:
						LDY #$00
						LDA #«expression.type.asmName»
						STA («receiver»), Y
					«FOR field : expression.fieldsInitializedOnContructor»
						«field.compile(new CompileData => [
							container = constructor
							indirect = receiver
						])»
					«ENDFOR»
					«noop»
						RTS
				«ELSEIF expression.dimension.isNotEmpty»
					TODO: compile array constructor call
				«ELSEIF expression.type.isPrimitive»
					«val defaultByte = NoopFactory::eINSTANCE.createByteLiteral => [value = 0]»
					«defaultByte.compile(data)»
				«ELSE»
					«data.pushAccIfOperating»
					«val constructor = expression.nameOfConstructor»
					«val receiver = new CompileData => [indirect = expression.nameOfReceiver]»
					«IF expression.isOnMemberSelectionOrReference»
						«val tmp = new CompileData => [absolute = expression.nameOfTmpVar(data.container)]»
						«IF data.mode === Mode::POINT»
							«data.pointTo(tmp)»
						«ELSEIF data.mode == Mode::REFERENCE»
							«tmp.referenceInto(data)»
						«ENDIF»
						«receiver.pointTo(tmp)»
					«ELSE»
						«receiver.pointTo(data)»
					«ENDIF»
					«noop»
						JSR «constructor»
					«FOR field : expression.constructor?.fields ?: emptyList»
						«field.value.compile(new CompileData => [
							container = constructor
							operation = data.operation
							indirect = receiver.indirect									
							index = '''#«field.variable.nameOfOffset»'''
							type = field.variable.typeOf
						])»
					«ENDFOR»
					«data.pullAccIfOperating»
				«ENDIF»	
			'''
			MemberSelection: '''
				«val member = expression.member»
				«val receiver = expression.receiver»
				«IF member.isStatic»
					«IF !(receiver instanceof NewInstance)»
						«receiver.compile(new CompileData => [
							container = data.container
							operation = data.operation
						])»
					«ENDIF»
					«IF member instanceof Variable»
						«IF member.isConstant»
							«member.compileConstantReference(data)»
						«ELSE»
							«member.compileStaticReference(expression.indexes, data)»
						«ENDIF»
					«ELSEIF member instanceof Method»
						«val method = member as Method»
						«method.compileInvocation(expression.args, data)»
					«ENDIF»
				«ELSE»
					«IF member instanceof Variable»
						«val rcv = new CompileData => [
							container = data.container
							operation = data.operation
							type = receiver.typeOf
							mode = Mode::REFERENCE
						]»
						«receiver.compile(rcv)»
						«member.compileIndirectReference(rcv, expression.indexes, data)»
					«ELSEIF member instanceof Method»
						«val method = member as Method»
						«receiver.compile(new CompileData => [
							container = data.container
							operation = data.operation
							indirect = method.nameOfReceiver
							type = receiver.typeOf
							mode = Mode::POINT
						])»
						«method.compileInvocation(expression.args, data)»
					«ENDIF»
				«ENDIF»				
			'''
			MemberRef: '''
				«val member = expression.member»
				«IF member instanceof Variable»
					«IF member.isField && member.isNonStatic»
						«member.compilePointerReference('''«data.container».rcv''', expression.indexes, data)»
					«ELSEIF member.isParameter && (member.type.isNonPrimitive || member.dimensionOf.isNotEmpty)»
						«member.compilePointerReference(member.nameOf, expression.indexes, data)»
					«ELSEIF member.isConstant»
						«member.compileConstantReference(data)»
					«ELSEIF member.isStatic»
						«member.compileStaticReference(expression.indexes, data)»
					«ELSE»
						«member.compileLocalReference(expression.indexes, data)»
					«ENDIF»
				«ELSEIF member instanceof Method»
					«val method = member as Method»
					«IF method.isNonStatic»
						«val outerReceiver = new CompileData => [indirect = '''«data.container».rcv''']»
						«val innerReceiver = new CompileData => [indirect = method.nameOfReceiver]»
						«innerReceiver.pointTo(outerReceiver)»
					«ENDIF»
					«method.compileInvocation(expression.args, data)»
				«ENDIF»					
			'''
			default:
				''
		}
	}

	private def compileInc(Operation incOperation, Expression expression, CompileData data) '''
		«val inc = new CompileData => [
				container = data.container
				type = expression.typeOf
				operation = incOperation
				mode = Mode::OPERATE
			]»
		«expression.compile(inc)»
		«expression.compile(data)»
	'''

	private def compileBinary(Operation binaryOperation, Expression left, Expression right, CompileData data) '''
		«val lda = new CompileData => [
			container = data.container
			operation = data.operation
			type = if (data.type.isBoolean) left.typeOf else data.type
			register = 'A'
			mode = Mode::COPY
		]»
		«val opr = new CompileData => [
			container = data.container
			operation = binaryOperation
			type = if (data.type.isBoolean) left.typeOf else data.type
			mode = Mode::OPERATE
		]»
			«IF data.operation !== null»
				PHA
			«ENDIF»
		«left.compile(lda)»
			«IF binaryOperation === Operation::AND»
				BEQ +skipRightExpression@«right.hashCode.toHex»:
			«ELSEIF binaryOperation === Operation::OR»
				BNE +skipRightExpression@«right.hashCode.toHex»:
			«ENDIF»		
		«right.compile(opr)»
		«IF binaryOperation === Operation::AND || binaryOperation === Operation::OR»
			+skipRightExpression@«right.hashCode.toHex»:
		«ENDIF»
		«IF data.mode === Mode::OPERATE»
			«noop»
				«FOR i : 0..< data.sizeOf»
					STA «Members::TEMP_VAR_NAME2»«IF i > 0» + «i»«ENDIF»
					PLA
				«ENDFOR»
			«val tmp = new CompileData => [
				container = data.container
				type = data.type
				absolute = Members::TEMP_VAR_NAME2
			]»
			«data.operateOn(tmp)»
		«ELSEIF data.mode === Mode::COPY»
			«val res = new CompileData => [
				container = data.container
				type = data.type
				register = 'A'
			]»
			«res.copyTo(data)»
		«ENDIF»
	'''

	private def compileUnary(Operation unaryOperation, Expression right, CompileData data) '''
		«val lda = new CompileData => [
				container = data.container
				type = data.type
				register = 'A'
				mode = Mode::COPY
			]»
		«val acc = new CompileData => [
				container = data.container
				type = data.type
				operation = unaryOperation
				mode = Mode::OPERATE
			]»
			«IF data.operation !== null»
				PHA
			«ENDIF» 
		«right.compile(lda)»
		«acc.operate»
		«IF data.mode === Mode::OPERATE»
			«FOR i : 0 ..< data.sizeOf»
				«noop»
					STA «Members::TEMP_VAR_NAME2»«IF i > 0» + «i»«ENDIF»
					PLA
			«ENDFOR»
			«val tmp = new CompileData => [
					container = data.container
					type = data.type
					absolute = Members::TEMP_VAR_NAME2
				]»
			«data.operateOn(tmp)»
		«ELSEIF data.mode === Mode::COPY»
			«val res = new CompileData => [
					container = data.container
					type = data.type
					register = 'A'
				]»
			«res.copyTo(data)»
		«ENDIF»
	'''

	private def compileSelfReference(Expression expression, CompileData data) '''
		«val method = expression.getContainerOfType(Method)»
		«val instance = new CompileData => [
			container = method.nameOf
			operation = data.operation
			type = expression.typeOf
			indirect = method.nameOfReceiver
		]»
		«IF data.mode === Mode::COPY»
			«instance.copyTo(data)»
		«ELSEIF data.mode === Mode::POINT»
			«data.pointTo(instance)»
		«ELSEIF data.mode === Mode::REFERENCE»
			«instance.referenceInto(data)»
		«ENDIF»
	'''

	private def void noop() {
	}

}
