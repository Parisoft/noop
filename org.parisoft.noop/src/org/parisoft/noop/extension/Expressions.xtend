package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.stream.Collectors
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.generator.NoopInstance
import org.parisoft.noop.generator.StackData
import org.parisoft.noop.generator.StorageData
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
		containerName + '.new' + instance.typeOf.name + 'Array@' + instance.hashCode.toHexString
	}

	def asmTmpVarName(NewInstance instance, String containerName) {
		containerName + '.new' + instance.typeOf.name + '@' + instance.hashCode.toHexString
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

	def List<MemChunk> alloc(Expression expression, StackData data) {
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

				if (expression.type.isNESHeader) {
					data.header = expression
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
					expression.type.alloc(data)

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
				} else if ((expression.member as Variable).isConstant) {
					data.constants += expression.member as Variable
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
				} else if ((expression.member as Variable).isStatic && expression.typeOf.isPrimitive && expression.dimensionOf.isEmpty) {
					data.constants += expression.member as Variable
				}

				return chunks
			}
			default:
				newArrayList
		}
	}

	def String compile(Expression expression, StorageData data) {
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
					«data.index.compile(new StorageData => [register = 'X'])»
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
					«data.index.compile(new StorageData => [register = 'Y'])»
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
			NewInstance: '''
				«IF data === null»
					«val constructor = expression.asmConstructorName»
					«val receiver = expression.asmReceiverName»
					«constructor»:
						LDA #«expression.type.asmName»
						STA («receiver»)
						
					«FOR field : expression.fieldsInitializedOnContructor»
						«field.compile(new StorageData => [
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
						«field.value.compile(new StorageData => [
							indirect = receiver									
							index = NoopFactory::eINSTANCE.createMemberRef => [member = field.variable]
							type = field.variable.typeOf
							container = constructor
						])»
					«ENDFOR»
				«ELSE»
					«val constructor = expression.asmConstructorName»
					«val receiver = expression.asmReceiverName»
					«IF data.absolute !== null && data.index !== null»
						«data.index.compile(new StorageData => [register = 'A'])»
							CLC
							ADC #<(«data.absolute»)
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
						«data.index.compile(new StorageData => [register = 'Y'])»
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
						«field.value.compile(new StorageData => [
							indirect = receiver									
							index = NoopFactory::eINSTANCE.createMemberRef => [member = field.variable]
							type = field.variable.typeOf
							container = constructor
						])»
					«ENDFOR»
				«ENDIF»	
			'''
			MemberSelection: '''
				TODO: expression.indexes
				«val member = expression.member»
				«val receiver = expression.receiver»
				«IF member instanceof Variable»
					TODO: data.indirect|absolute = receiver.member
				«ELSEIF member instanceof Method»
					«val method = member as Method»
					«IF method.isNonStatic»
						«receiver.compile(new StorageData => [
							indirect = method.asmReceiverName
							type = receiver.typeOf
							copy = false
						])»
					«ENDIF»
					«FOR i : 0..< expression.args.size»
						«val param = method.params.get(i)»
						«val arg = expression.args.get(i)»
						«arg.compile(new StorageData => [
							container = method.asmName
							type = param.type
							
							if (param.type.isPrimitive && param.type.dimensionOf.isEmpty) {
								absolute = param.asmName
								copy = true
							} else {
								indirect = param.asmName
								copy = false
							}
						])»
					«ENDFOR»
					«noop»
						JSR «method.asmName»
					«IF member.typeOf.isNonVoid»
						TODO: data.indirect|absolute = member.return
					«ENDIF»
				«ENDIF»				
			'''
			MemberRef: '''
				«val member = expression.member»
				«val refIsIndexed = expression.indexes.isNotEmpty»
				«IF member instanceof Variable»
					«val varAsIndirect = if (member.isField) {
						'''«data.container».receiver'''
					} else if (member.isParameter && (member.type.isNonPrimitive || member.dimensionOf.isNotEmpty)) {
						member.asmName
					}»
					«IF varAsIndirect !== null»
						«IF data.absolute !== null»
							«IF data.isIndexed»
								«data.index.compile(new StorageData => [register = 'X'])»
							«ENDIF»
							«IF refIsIndexed»
								«expression.loadIndexIntoRegiter('Y')»
							«ELSE»
								«noop»
									LDY #«IF member.isField»«member.asmOffsetName»«ELSE»$00«ENDIF»
							«ENDIF»
							«FOR i : 0..< data.type.sizeOf»
								«noop»
									«IF i > 0»
										INY
									«ENDIF»
									LDA («varAsIndirect»), Y
									STA «data.absolute» + «i»«IF data.isIndexed», X«ENDIF»
							«ENDFOR»
						«ELSEIF data.indirect !== null && data.isCopy»
							«IF data.isIndexed»
								«data.index.compile(new StorageData => [register = 'Y'])»
							«ELSE»
								«noop»
									LDY #$00
							«ENDIF»
							«IF refIsIndexed»
								«expression.loadIndexIntoRegiter('X')»
							«ELSE»
								«noop»
									LDX #«IF member.isField»«member.asmOffsetName»«ELSE»$00«ENDIF»
							«ENDIF»
							«FOR i : 0..< data.type.sizeOf»
								«noop»
									«IF i > 0»
										INX
										INY
									«ENDIF»
									LDA («varAsIndirect», X)
									STA («data.indirect»), Y
							«ENDFOR»
						«ELSEIF data.indirect !== null»
							«IF refIsIndexed || member.isField»
								«IF refIsIndexed»
									«expression.loadIndexIntoRegiter('A')»
								«ELSE»
									«noop»
										LDA #«member.asmOffsetName»
								«ENDIF»
								«noop»
									CLC
									ADC «varAsIndirect» + 0
									STA «data.indirect» + 0
									LDA #$00
									ADC «varAsIndirect» + 1
									STA «data.indirect» + 1
							«ELSE» 
								«noop»
									LDA «varAsIndirect» + 0
									STA «data.indirect» + 0
									LDA «varAsIndirect» + 1
									STA «data.indirect» + 1
							«ENDIF»
						«ELSEIF data.register !== null»
							«IF refIsIndexed»
								«IF data.register == 'Y'»
									«expression.loadIndexIntoRegiter('X')»
										LDY («varAsIndirect», X)
								«ELSE»
									«expression.loadIndexIntoRegiter('Y')»
										LD«data.register» («varAsIndirect»), Y
								«ENDIF»
							«ELSEIF member.isField»
								«IF data.register == 'Y'»
									«noop»
										LDX #«member.asmOffsetName»
										LDY («varAsIndirect», X)
								«ELSE»
									«noop»
										LDY #«member.asmOffsetName»
										LD«data.register» («varAsIndirect»), Y
								«ENDIF»
							«ELSE»
								«noop»
									LD«data.register» («varAsIndirect»)
							«ENDIF»
						«ENDIF»
					«ELSE»
						«val varAsAbsolute = if (member.isConstant) {
							member.asmConstantName
						} else {
							member.asmName
						}»
						«IF data.absolute !== null»
							«IF data.isIndexed»
								«data.index.compile(new StorageData => [
									container = data.container
									type = data.index.typeOf
									register = 'X'
								])»
							«ENDIF»
							«IF refIsIndexed»
								«expression.loadIndexIntoRegiter('Y')»
							«ENDIF»
							«FOR i : 0..< data.type.sizeOf»
								«noop»
									LDA «varAsAbsolute» + «i»«IF refIsIndexed», Y«ENDIF»
									STA «data.absolute» + «i»«IF data.isIndexed», X«ENDIF»
							«ENDFOR»
						«ELSEIF data.indirect !== null && data.isCopy»
							«IF data.isIndexed»
								«data.index.compile(new StorageData => [register = 'Y'])»
							«ELSE»
								«noop»
									LDY #$00
							«ENDIF»
							«IF refIsIndexed»
								«expression.loadIndexIntoRegiter('X')»
							«ENDIF»
							«FOR i : 0..< data.type.sizeOf»
								«noop»
									«IF i > 0»
										INY
									«ENDIF»
									LDA «varAsAbsolute» + «i»«IF refIsIndexed», X«ENDIF»
									STA («data.indirect»), Y
							«ENDFOR»
						«ELSEIF data.indirect !== null»
							«IF refIsIndexed»
								«expression.loadIndexIntoRegiter('A')»
									CLC
									ADC #<(«varAsAbsolute»)
									STA «data.indirect» + 0
									LDA #$00
									ADC #>(«varAsAbsolute»)
									STA «data.indirect» + 1
							«ELSE»
								«noop»
									LDA #<(«varAsAbsolute»)
									STA «data.indirect» + 0
									LDA #>(«varAsAbsolute»)
									STA «data.indirect» + 1
							«ENDIF»
						«ELSEIF data.register !== null»
							«IF refIsIndexed»
								«IF data.register == 'Y'»
									«expression.loadIndexIntoRegiter('X')»
										LDY «varAsAbsolute», X
								«ELSE»
									«expression.loadIndexIntoRegiter('Y')»
										LD«data.register» «varAsAbsolute», Y
								«ENDIF»
							«ELSE»
								«noop»
									LD«data.register» «varAsAbsolute»
							«ENDIF»
						«ENDIF»
					«ENDIF»
				«ELSEIF member instanceof Method»
					«val method = member as Method»
					«val methodName = method.asmName»
					«val outerReceiver = '''«data.container».receiver'''»
					«val innerReceiver = method.asmReceiverName»
						LDA «outerReceiver» + 0
						STA «innerReceiver» + 0
						LDA «outerReceiver» + 1
						STA «innerReceiver» + 1
					«FOR i : 0..< expression.args.size»
						«val param = method.params.get(i)»
						«val arg = expression.args.get(i)»
						«arg.compile(new StorageData => [
							container = methodName
							type = param.type
							
							if (param.type.isPrimitive && param.type.dimensionOf.isEmpty) {
								absolute = param.asmName
								copy = true
							} else {
								indirect = param.asmName
								copy = false
							}
						])»
						«val dimension = arg.dimensionOf»
						«FOR dim : 0..< dimension.size»
							«noop»
								LDA #«dimension.get(dim).toHex»
								STA «param.asmLenName(methodName, dim)»
						«ENDFOR»
					«ENDFOR»
					«noop»
						JSR «method.asmName»
					«IF member.typeOf.isNonVoid»
						«val retAsIndirect = method.asmReturnName»
						«IF data.absolute !== null»
							«IF data.isIndexed»
								«data.index.compile(new StorageData => [register = 'X'])»
							«ENDIF»
							«noop»
								LDY #$00
							«FOR i : 0..< data.type.sizeOf»
								«noop»
									«IF i > 0»
										INY
									«ENDIF»
									LDA («retAsIndirect»), Y
									STA «data.absolute» + «i»«IF data.isIndexed», X«ENDIF»
							«ENDFOR»
						«ELSEIF data.indirect !== null && data.isCopy»
							«IF data.isIndexed»
								«data.index.compile(new StorageData => [register = 'Y'])»
							«ELSE»
								«noop»
									LDY #$00
							«ENDIF»
							«noop»
								LDX #$0
							«FOR i : 0..< data.type.sizeOf»
								«noop»
									«IF i > 0»
										INX
										INY
									«ENDIF»
									LDA («retAsIndirect», X)
									STA («data.indirect»), Y
							«ENDFOR»
						«ELSEIF data.indirect !== null»
							«noop»
								LDA «retAsIndirect» + 0
								STA «data.indirect» + 0
								LDA «retAsIndirect» + 1
								STA «data.indirect» + 1
						«ELSEIF data.register !== null»
							«noop»
								LD«data.register» («retAsIndirect»)
						«ENDIF»
					«ENDIF»
				«ENDIF»
			'''
			default:
				''
		}
	}

	private def loadIndexIntoRegiter(MemberRef ref, String reg) '''
		«val variable = ref.member as Variable»
		«val dimension = variable.dimensionOf»
		«val sizeOfVar = variable.typeOf.sizeOf»
		«IF dimension.size === 1 && sizeOfVar === 1»
			«val index = ref.indexes.head»
			«IF variable.isField»
				«index.value.compile(new StorageData => [register = 'A'])»
					ADC #«variable.asmOffsetName»
					«IF reg != 'A'»
						TA«reg»
					«ENDIF»
			«ELSE»
				«index.value.compile(new StorageData => [register = reg])»
			«ENDIF»
		«ELSE»
			«noop»
				LDA «Members::TEMP_VAR_NAME1»
				PHA
				LDA «Members::TEMP_VAR_NAME2»
				PHA
			«FOR i : 0..< ref.indexes.size»
				«val index = ref.indexes.get(i)»
				«index.value.compile(new StorageData => [register = 'A'])»
					«FOR len : (i + 1)..< dimension.size»
						STA «Members::TEMP_VAR_NAME1»
						LDA «IF variable.isParameter»«variable.asmLenName(len)»«ELSE»#«dimension.get(len).toHex»«ENDIF»
						STA «Members::TEMP_VAR_NAME2»
						LDA #$00
						mult8x8to8
					«ENDFOR»
					«IF (i + 1) < ref.indexes.size»
						PHA
					«ENDIF»
			«ENDFOR»
			«FOR i : 1..< ref.indexes.size»
				«noop»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					ADC «Members::TEMP_VAR_NAME1»
			«ENDFOR»
			«noop»
				«IF sizeOfVar > 1»
					STA «Members::TEMP_VAR_NAME1»
					LDA #«sizeOfVar.toHex»
					STA «Members::TEMP_VAR_NAME2»
					LDA #$00
					mult8x8to8
				«ENDIF»
				«IF variable.isField»
					ADC #«variable.asmOffsetName»
				«ENDIF»
				«IF reg != 'A'»
					TA«reg»
				«ENDIF»
				PLA
				STA «Members::TEMP_VAR_NAME2»
				PLA
				STA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def void noop() {
	}

}
