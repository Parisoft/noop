package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.stream.Collectors
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.CompileData
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

class Expressions {

	static val FILE_URI = 'file://'

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Values
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

	def asmName(ArrayLiteral array, String containerName) {
		containerName + '.' + array.typeOf.name.toFirstLower + 'Array@' + array.hashCode.toHexString
	}

	def asmTmpArrayName(NewInstance instance, String containerName) {
		containerName + '.tmp' + instance.typeOf.name + 'Array@' + instance.hashCode.toHexString
	}

	def asmTmpVarName(NewInstance instance, String containerName) {
		containerName + '.tmp' + instance.typeOf.name + '@' + instance.hashCode.toHexString
	}

	def asmConstructorName(NewInstance instance) {
		'''«instance.type.name».new'''.toString
	}

	def asmReceiverName(NewInstance instance) {
		'''«instance.asmConstructorName».receiver'''.toString
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
			MemberSelection:
				if (expression.isInstanceOf) {
					expression.toBoolClass
				} else if (expression.isCast) {
					expression.type
				} else {
					expression.member.typeOf
				}
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
			AddExpression:
				expression.typeOfValueOrInt
			SubExpression:
				expression.typeOfValueOrInt
			MulExpression:
				expression.typeOfValueOrInt
			DivExpression:
				expression.typeOfValueOrInt
			BOrExpression:
				expression.typeOfValueOrInt
			BAndExpression:
				expression.typeOfValueOrInt
			LShiftExpression:
				expression.typeOfValueOrInt
			RShiftExpression:
				expression.typeOfValueOrInt
			EorExpression:
				expression.typeOfValueOrInt
			NotExpression:
				expression.toBoolClass
			SigNegExpression:
				expression.typeOfValueOrInt
			SigPosExpression:
				expression.typeOfValueOrInt
			DecExpression:
				expression.toIntClass
			IncExpression:
				expression.toIntClass
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
					expression.values.map[it.typeOf].merge
				}
			StringLiteral:
				expression.toByteClass
			This:
				expression.containingClass
			Super:
				expression.containingClass.superClassOrObject
			NewInstance:
				expression.type
			MemberRef:
				expression.member.typeOf
		}
	}

	private def typeOfValueOrInt(Expression expression) {
		try {
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
		} catch (Exception e) {
			expression.toIntClass
		}
	}

	def Object valueOf(Expression expression) {
		try {
			switch (expression) {
				AssignmentExpression:
					expression.right.valueOf
				MemberSelection:
					if (expression.isInstanceOf) {
						throw new NonConstantExpressionException(expression)
					} else if (expression.isCast) {
						expression.receiver.valueOf
					} else {
						expression.member.valueOf
					}
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
				ByteLiteral:
					expression.value
				BoolLiteral:
					expression.value
				ArrayLiteral:
					expression.values.map[it.valueOf]
				StringLiteral:
					expression.value.chars.boxed.collect(Collectors.toList)
				NewInstance:
					if (expression.constructor !== null) {
						new NoopInstance(expression.type.name, expression.type.allFieldsBottomUp, expression.constructor)
					} else {
						expression.type.defaultValueOf
					}
				MemberRef:
					expression.member.valueOf
				default:
//				DecExpression:
//				IncExpression:
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
				if (expression.isInstanceOf || expression.isCast) {
					emptyList
				} else {
					expression.member.dimensionOf.subListFrom(expression.indexes.size)
				}
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
			ArrayLiteral:
				expression.typeOf.prepare(data)
			NewInstance:
				if (expression.type.isINESHeader) {
					data.header = expression
				} else {
					expression.type.prepare(data)
				}
			MemberSelection: {
				expression.receiver.prepare(data)

				if (expression.isInstanceOf || expression.isCast) {
					expression.type.prepare(data)
				} else if (expression.member instanceof Variable) {
					(expression.member as Variable).prepare(data)
				} else if (expression.member instanceof Method) {
					(expression.member as Method).prepare(data)
				}
			}
			MemberRef:
				if (expression.member instanceof Variable) {
					(expression.member as Variable).prepare(data)
				} else if (expression.member instanceof Method) {
					(expression.member as Method).prepare(data)
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
			ArrayLiteral:
				if (expression.isOnMemberSelectionOrReference) {
					data.variables.computeIfAbsent(expression.asmName(data.container), [newArrayList(data.chunkForVar(it, expression.fullSizeOf))])
				} else {
					newArrayList
				}
			NewInstance: {
				val chunks = newArrayList

				if (expression.type.isINESHeader) {
					return chunks
				}

				if (expression.isOnMemberSelectionOrReference) {
					if (expression.dimension.isEmpty && expression.type.isNonPrimitive) {
						chunks += data.variables.computeIfAbsent(expression.asmTmpVarName(data.container), [
							newArrayList(data.chunkForVar(it, expression.sizeOf))
						])
					} else if (expression.dimension.isNotEmpty) {
						chunks += data.variables.computeIfAbsent(expression.asmTmpArrayName(data.container), [
							newArrayList(data.chunkForVar(it, expression.fullSizeOf))
						])
					}
				}

				if (expression.dimension.isEmpty && expression.type.isNonPrimitive) {
					val snapshot = data.snapshot
					val constructorName = expression.asmConstructorName

					data.container = constructorName

					chunks += data.pointers.computeIfAbsent(expression.asmReceiverName, [newArrayList(data.chunkForPtr(it))])
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
				val chunks = newArrayList

				if (expression.isInstanceOf || expression.isCast) {
					val snapshot = data.snapshot

					chunks += expression.receiver.alloc(data)

					data.restoreTo(snapshot)
				} else if (expression.isMethodInvocation) {
					val snapshot = data.snapshot

					chunks += (expression.member as Method).alloc(data)
					chunks += expression.receiver.alloc(data)
					chunks += expression.args.map[alloc(data)].flatten

					data.restoreTo(snapshot)
				}

				return chunks
			}
			MemberRef: {
				val chunks = newArrayList

				if (expression.isMethodInvocation) {
					val snapshot = data.snapshot

					chunks += (expression.member as Method).alloc(data)
					chunks += expression.args.map[alloc(data)].flatten

					data.restoreTo(snapshot)
				}

				return chunks
			}
			default:
				newArrayList
		}
	}

	def String compile(Expression expression, CompileData data) {
		switch (expression) {
			ByteLiteral: '''
				«val bytes = expression.valueOf.toBytes»
				«IF data.relative !== null»
					«data.relative»:
						«IF data.type.sizeOf == 1»
							.db «bytes.head.toHex»
						«ELSE»
							.db «bytes.join(' ', [toHex])»
						«ENDIF»
				«ELSEIF data.absolute !== null && data.index !== null»
					«noop»
						LDX «data.index»
						LDA #«bytes.head.toHex»
						STA «data.absolute», X
						«IF data.type.sizeOf > 1»
							INX
							LDA #«bytes.last.toHex»
							STA «data.absolute», X
						«ENDIF»
				«ELSEIF data.absolute !== null»
					«noop»
						LDA #«bytes.head.toHex»
						STA «data.absolute»
						«IF data.type.sizeOf > 1»
							LDA #«bytes.last.toHex»
							STA «data.absolute» + 1
						«ENDIF»
				«ELSEIF data.indirect !== null && data.index !== null»
					«noop»
						LDY «data.index»
						LDA #«bytes.head.toHex»
						STA («data.indirect»), Y
						«IF data.type.sizeOf > 1»
							INY
							LDA #«bytes.last.toHex»
							STA («data.indirect»), Y
						«ENDIF»
				«ELSEIF data.indirect !== null»
					«noop»
						LDA #«bytes.head.toHex»
						STA («data.indirect»)
						«IF data.type.sizeOf > 1»
							LDY #$01
							LDA #«bytes.last.toHex»
							STA («data.indirect»), Y
						«ENDIF»
				«ELSEIF data.getRegister !== null»
					«noop»
						LD«data.getRegister» «bytes.head.toHex»
				«ENDIF»
			'''
			BoolLiteral:
				(NoopFactory::eINSTANCE.createByteLiteral => [value = if (expression.value) 1 else 0]).compile(data)
			StringLiteral: '''
				«IF data.relative !== null»
					«data.relative»:
						«IF expression.value.startsWith(FILE_URI)»
							.incbin "«expression.value.substring(FILE_URI.length)»"
						«ELSE»
							.db «expression.value.toBytes.join(', ', [toHex])»
						«ENDIF»
				«ENDIF»
			'''
			ArrayLiteral: '''
				«IF data.relative !== null»
					«data.relative»:
						.db «expression.valueOf.toBytes.join(', ', [toHex])»
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
					«val constructor = expression.asmConstructorName»
					«val receiver = expression.asmReceiverName»
					«constructor»:
						LDA #«expression.type.asmName»
						STA («receiver»)
						
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
					«(NoopFactory::eINSTANCE.createByteLiteral => [value = 0]).compile(data)»
				«ELSEIF expression.isOnMemberSelectionOrReference»
					«val constructor = expression.asmConstructorName»
					«val receiver = expression.asmReceiverName»
					«val tmp = expression.asmTmpVarName(constructor)»
						LDA #<(«tmp»)
						STA «receiver» + 0
						LDA #>(«tmp»)
						STA «receiver» + 1
						JSR «constructor»
						«IF data.indirect !== null»
							LDA «receiver» + 0
							STA «data.indirect» + 0
							LDA «receiver» + 1
							STA «data.indirect» + 1
						«ENDIF»
					«FOR field : expression.constructor?.fields ?: emptyList»
						«field.value.compile(new CompileData => [
							indirect = receiver									
							index = '''#«field.variable.asmOffsetName»'''
							type = field.variable.typeOf
							container = constructor
						])»
					«ENDFOR»
				«ELSE»
					«val constructor = expression.asmConstructorName»
					«val receiver = expression.asmReceiverName»
					«IF data.absolute !== null && data.index !== null»
						«noop»
							CLC
							LDA #<(«data.absolute»)
							ADC «data.index»
							STA «receiver» + 0
							LDA #>(«data.absolute»)
							ADC #$00
							STA «receiver» + 1
					«ELSEIF data.absolute !== null»
						«noop»
							LDA #<(«data.absolute»)
							STA «receiver» + 0
							LDA #>(«data.absolute»)
							STA «receiver» + 1
					«ELSEIF data.indirect !== null && data.index !== null»
						«noop»
							LDY «data.index»
							LDA («data.indirect»), Y
							STA «receiver» + 0
							INY
							LDA («data.indirect»), Y
							STA «receiver» + 1
					«ELSEIF data.indirect !== null»
						«noop»
							LDA «data.indirect» + 0
							STA «receiver» + 0
							LDA «data.indirect» + 1
							STA «receiver» + 1
					«ENDIF»
					«noop»
						JSR «constructor»
					«FOR field : expression.constructor?.fields ?: emptyList»
						«field.value.compile(new CompileData => [
							indirect = receiver									
							index = '''#«field.variable.asmOffsetName»'''
							type = field.variable.typeOf
							container = constructor
						])»
					«ENDFOR»
				«ENDIF»	
			'''
			MemberSelection: '''
				«val member = expression.member»
				«val receiver = expression.receiver»
				«IF expression.isInstanceOf»
					«receiver.compile(data)»
					;TODO: «receiver.typeOf.name».instanceOf(«expression.type»)
				«ELSEIF expression.isCast»
					«receiver.compile(data)»
					;TODO: «receiver.typeOf.name».cast(«expression.type»)
				«ELSEIF member.isStatic»
					«IF !(receiver instanceof NewInstance)»
						«receiver.compile(new CompileData => [container = data.container])»
					«ENDIF»
					«IF member instanceof Variable»
						«IF member.isConstant»
							«member.compileConstantReference(member.asmConstantName, expression.indexes, data)»
						«ELSE»
							«member.compileAbsoluteReference(member.asmStaticName, expression.indexes, data)»
						«ENDIF»
					«ELSEIF member instanceof Method»
						«val method = member as Method»
						«method.compileInvocation(expression.args, data)»
					«ENDIF»
				«ELSE»
					«IF member instanceof Variable»
						«val receiverAsIndirect = Members::TEMP_VAR_NAME1»
						«receiver.compile(new CompileData => [
							container = data.container
							type = receiver.typeOf
							indirect = receiverAsIndirect
							copy = false 
						])»
						«member.compileIndirectReference(receiverAsIndirect, expression.indexes, data)»
					«ELSEIF member instanceof Method»
						«val method = member as Method»
						«receiver.compile(new CompileData => [
							container = data.container
							type = receiver.typeOf
							indirect = method.asmReceiverName
							copy = false 
						])»
						«method.compileInvocation(expression.args, data)»
					«ENDIF»
				«ENDIF»				
			'''
			MemberRef: '''
				«val member = expression.member»
				«IF member instanceof Variable»
					«IF member.isField && member.isNonStatic»
						«member.compileIndirectReference('''«data.container».receiver''', expression.indexes, data)»
					«ELSEIF member.isParameter && (member.type.isNonPrimitive || member.dimensionOf.isNotEmpty)»
						«member.compileIndirectReference(member.asmName, expression.indexes, data)»
					«ELSEIF member.isConstant»
						«member.compileConstantReference(member.asmConstantName, expression.indexes, data)»
					«ELSEIF member.isStatic»
						«member.compileAbsoluteReference(member.asmStaticName, expression.indexes, data)»
					«ELSE»
						«member.compileAbsoluteReference(member.asmName, expression.indexes, data)»
					«ENDIF»
				«ELSEIF member instanceof Method»
					«val method = member as Method»
					«IF method.isNonStatic»
						«val outerReceiver = '''«data.container».receiver'''»
						«val innerReceiver = method.asmReceiverName»
							LDA «outerReceiver» + 0
							STA «innerReceiver» + 0
							LDA «outerReceiver» + 1
							STA «innerReceiver» + 1
						«method.compileInvocation(expression.args, data)»
					«ENDIF»
				«ENDIF»					
			'''
			default:
				''
		}
	}

	private def compileSelfReference(Expression expression, CompileData data) '''
		«val refAsIndirect = expression.getContainerOfType(Method).asmReceiverName»
		«IF data.absolute !== null»
			«IF data.isIndexed»
				«noop»
					LDX «data.index»
			«ENDIF»
			«val sizeOfData = data.type.sizeOf»
			«IF sizeOfData > 1»
				«noop»
					LDY #$00
			«ENDIF»
			«FOR i : 0..< sizeOfData»
				«noop»
					«IF i > 0»
						INY
					«ENDIF»
					LDA («refAsIndirect»), Y
					STA «data.absolute»«IF i > 0» + «i»«ENDIF»«IF data.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSEIF data.indirect !== null && data.isCopy»
			«IF data.isIndexed»
				«noop»
					LDY «data.index»
			«ELSE»
				«noop»
					LDY #$00
			«ENDIF»
			«val sizeOfData = data.type.sizeOf»
			«IF sizeOfData > 1»
				«noop»
					LDX #$00
			«ENDIF»
			«FOR i : 0..< sizeOfData»
				«noop»
					«IF i > 0»
						INX
						INY
					«ENDIF»
					LDA («refAsIndirect», X)
					STA («data.indirect»), Y
			«ENDFOR»
		«ELSEIF data.indirect !== null»
			«noop»
				LDA «refAsIndirect» + 0
				STA «data.indirect» + 0
				LDA «refAsIndirect» + 1
				STA «data.indirect» + 1
		«ENDIF»
	'''

	private def void noop() {
	}

}
