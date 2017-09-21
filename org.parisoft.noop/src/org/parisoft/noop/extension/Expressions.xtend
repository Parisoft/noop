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

	@Inject extension Datas
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

	def nameOfTmpReceiver(Expression expression, String containerName) {
		'''«containerName».tmp«expression.typeOf.name»Rcv@«expression.hashCode.toHexString» '''.toString
	}

	def nameOfTmp(ArrayLiteral array, String containerName) {
		'''«containerName».tmp«array.typeOf.name»Array@«array.hashCode.toHexString» '''.toString
	}

	def nameOfTmpArray(NewInstance instance, String containerName) {
		'''«containerName».tmp«instance.typeOf.name»Array@«instance.hashCode.toHexString» '''.toString
	}

	def nameOfTmpVar(NewInstance instance, String containerName) {
		'''«containerName».tmp«instance.typeOf.name»@«instance.hashCode.toHexString» '''.toString
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
				IncExpression:
					(expression.right.valueOf as Integer) + 1
				DecExpression:
					(expression.right.valueOf as Integer) - 1
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

					if (expression.type.isNonPrimitive) {
						expression.fieldsInitializedOnContructor.forEach[prepare(data)]
					}
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
					data.variables.computeIfAbsent(expression.nameOfTmp(data.container), [newArrayList(data.chunkForVar(it, expression.fullSizeOf))])
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
						chunks += data.variables.computeIfAbsent(expression.nameOfTmpVar(data.container), [
							newArrayList(data.chunkForVar(it, expression.sizeOf))
						])
					} else if (expression.dimension.isNotEmpty) {
						chunks += data.variables.computeIfAbsent(expression.nameOfTmpArray(data.container), [
							newArrayList(data.chunkForVar(it, expression.fullSizeOf))
						])
					}
				}

				if (expression.type.isNonPrimitive) {
					val snapshot = data.snapshot
					val constructorName = expression.nameOfConstructor

					data.container = constructorName

					chunks += data.pointers.computeIfAbsent(expression.nameOfReceiver, [newArrayList(data.chunkForPtr(it))])
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

				if (expression.isInstanceOf || expression.isCast) {
					chunks += expression.receiver.alloc(data)
				} else if (expression.isMethodInvocation) {
					val method = expression.member as Method

					chunks += method.alloc(data)
					chunks += expression.args.map[alloc(data)].flatten

					if (method.isNonStatic) {
						chunks += expression.receiver.alloc(data)
					}
				} else if (expression.member instanceof Variable) {
					val variable = expression.member as Variable

					chunks += variable.alloc(data)

					if (variable.isNonStatic) {
						chunks += expression.receiver.alloc(data)
						chunks += data.pointers.computeIfAbsent(expression.receiver.nameOfTmpReceiver(data.container), [
							newArrayList(data.chunkForPtr(it))
						])
					}

					if (expression.indexes.isNotEmpty) {
						chunks += data.variables.computeIfAbsent(expression.member.nameOfTmpIndex(expression.indexes, data.container), [
							newArrayList(data.chunkForVar(it, 1))
						])
					}
				}

				data.restoreTo(snapshot)

				return chunks
			}
			MemberRef: {
				val chunks = newArrayList

				if (expression.isMethodInvocation) {
					val snapshot = data.snapshot

					chunks += (expression.member as Method).alloc(data)
					chunks += expression.args.map[alloc(data)].flatten

					data.restoreTo(snapshot)
				} else if (expression.indexes.isNotEmpty) {
					chunks += data.variables.computeIfAbsent(expression.member.nameOfTmpIndex(expression.indexes, data.container), [
						newArrayList(data.chunkForVar(it, 1))
					])
				}

				return chunks
			}
			default:
				newArrayList
		}
	}

	def String compile(Expression expression, CompileData data) {
		switch (expression) {
			BOrExpression: '''
				;TODO «expression.left» | «expression.right» 
			'''
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
					«IF data.copy»
						«src.copyTo(data)»
					«ELSE»
						«data.pointTo(src)»
					«ENDIF»
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
				«ELSE»
					;TODO compile «expression»
				«ENDIF»
			'''
			ArrayLiteral: '''
				«IF data.relative !== null»
					«data.relative»:
						.db «expression.valueOf.toBytes.join(', ', [toHex])»
				«ELSE»
					;TODO compile «expression»
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
					«val defaultByte = NoopFactory::eINSTANCE.createByteLiteral => [value = 0]»
					«defaultByte.compile(data)»
				«ELSE»
					«val constructor = expression.nameOfConstructor»
					«val receiver = new CompileData => [indirect = expression.nameOfReceiver]»
					«IF expression.isOnMemberSelectionOrReference»
						«val tmp = new CompileData => [absolute = expression.nameOfTmpVar(constructor)]»
						«IF data.isPointer»
							«data.pointTo(tmp)»
						«ENDIF»
						«receiver.pointTo(tmp)»
					«ELSE»
						«receiver.pointTo(data)»
					«ENDIF»
					«noop»
						JSR «constructor»
					«FOR field : expression.constructor?.fields ?: emptyList»
						«field.value.compile(new CompileData => [
							indirect = receiver.indirect									
							index = '''#«field.variable.nameOfOffset»'''
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
				«ELSEIF member.isStatic»
					«IF !(receiver instanceof NewInstance)»
						«receiver.compile(new CompileData => [container = data.container])»
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
						«val rcv = expression.nameOfTmpReceiver(data.container)»
						«receiver.compile(new CompileData => [
							container = data.container
							type = receiver.typeOf
							indirect = rcv
							copy = false
						])»
						«member.compileIndirectReference(rcv, expression.indexes, data)»
					«ELSEIF member instanceof Method»
						«val method = member as Method»
						«receiver.compile(new CompileData => [
							container = data.container
							type = receiver.typeOf
							indirect = method.nameOfReceiver
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
						«member.compileIndirectReference('''«data.container».rcv''', expression.indexes, data)»
					«ELSEIF member.isParameter && (member.type.isNonPrimitive || member.dimensionOf.isNotEmpty)»
						«member.compileIndirectReference(member.nameOf, expression.indexes, data)»
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

	private def compileSelfReference(Expression expression, CompileData data) '''
		«val method = expression.getContainerOfType(Method)»
		«val instance = new CompileData => [
			container = method.nameOf
			type = expression.typeOf
			indirect = method.nameOfReceiver
		]»
		«IF data.isCopy»
			«instance.copyTo(data)»
		«ELSE»
			«data.pointTo(instance)»
		«ENDIF»
	'''

	private def void noop() {
	}

}
