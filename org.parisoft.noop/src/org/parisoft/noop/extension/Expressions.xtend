package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import java.util.stream.Collectors
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.MetaData
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
import org.parisoft.noop.noop.ElseStatement
import org.parisoft.noop.noop.EorExpression
import org.parisoft.noop.noop.EqualsExpression
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.ForeverStatement
import org.parisoft.noop.noop.GeExpression
import org.parisoft.noop.noop.GtExpression
import org.parisoft.noop.noop.IfStatement
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
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.SigNegExpression
import org.parisoft.noop.noop.SigPosExpression
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.SubExpression
import org.parisoft.noop.noop.Super
import org.parisoft.noop.noop.This
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.noop.AsmStatement
import org.parisoft.noop.noop.Constructor
import org.parisoft.noop.generator.MemChunk
import java.util.List
import java.util.Collection

class Expressions {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Values
	@Inject extension TypeSystem
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

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
						new NoopInstance(expression.type.name, expression.type.inheritedFields, expression.constructor)
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
					java.util.Collections.emptyList
				} else {
					expression.member.dimensionOf.subListFrom(expression.indexes.size)
				}
			MemberRef:
				expression.member.dimensionOf.subListFrom(expression.indexes.size)
			NewInstance:
				expression.dimension.map[value.valueOf as Integer]
			default:
				java.util.Collections.emptyList
		}
	}

	def sizeOf(Expression expression) {
		expression.typeOf.sizeOf
	}

	def methodName(Constructor constructor) {
		val type = constructor.getContainerOfType(NewInstance).type
		type.name + '.' + type.name + '_' + constructor.field.map[name].join('_')
	}

	def Collection<MemChunk> alloc(Expression expression, MetaData data) {
		switch (expression) {
			AssignmentExpression: {
				expression.right.alloc(data)
			}
			OrExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			AndExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			EqualsExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			DifferExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			GtExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			GeExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			LtExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			LeExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			AddExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			SubExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			MulExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			DivExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			BOrExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			BAndExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			LShiftExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			RShiftExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			EorExpression: {
				expression.right.alloc(data)
			}
			NotExpression: {
				expression.right.alloc(data)
			}
			SigNegExpression: {
				expression.right.alloc(data)
			}
			SigPosExpression: {
				expression.right.alloc(data)
			}
			DecExpression: {
				expression.right.alloc(data)
			}
			IncExpression: {
				expression.right.alloc(data)
			}
			NewInstance: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get

				expression.type.alloc(data)

				if (expression.type.nonSingleton && expression.constructor !== null && expression.constructor.field.isNotEmpty) {
					data.temps.put(expression.constructor.methodName + '.receiver', data.chunkForPointer)
				}

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
			MemberSelection: {
				val member = expression.member

				if (member instanceof Variable) {
					if (member.isConstant && member.nonROM && member.typeOf.isPrimitive) {
						return
					}
				}

				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get
				val method = expression.getContainerOfType(Method)
				val receiver = expression.receiver

				receiver.alloc(data)

				if (receiver instanceof ByteLiteral || receiver instanceof BoolLiteral || receiver instanceof StringLiteral ||
					receiver instanceof ArrayLiteral || receiver instanceof NewInstance) {
					if (method !== null) {
						data.temps.put(method.fullyQualifiedName.toString + '.' + receiver, data.chunkForVar(receiver.sizeOf))
					} else {
						val constructor = expression.getContainerOfType(Constructor)

						if (constructor !== null) {
							data.temps.put(constructor.methodName + '.' + receiver, data.chunkForVar(receiver.sizeOf))
						} else {
							data.temps.put(expression.containingClass.emptyConstructorName + '.' + receiver, data.chunkForVar(receiver.sizeOf))
						}
					}
				}

				if (expression.isMethodInvocation) {
					(member as Method).alloc(data)

					expression.args.reject [
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach[alloc(data)]

					expression.args.filter [
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach [ arg |
						if (method !== null) {
							data.temps.put(method.fullyQualifiedName.toString + '.' + arg, data.chunkForVar(arg.sizeOf))
						} else {
							val constructor = expression.getContainerOfType(Constructor)

							if (constructor !== null) {
								data.temps.put(constructor.methodName + '.' + arg, data.chunkForVar(arg.sizeOf))
							} else {
								data.temps.put(expression.containingClass.emptyConstructorName + '.' + arg, data.chunkForVar(arg.sizeOf))
							}
						}
					]
				}

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
			MemberRef: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get
				val method = expression.getContainerOfType(Method)
				val member = expression.member

				if (expression.isMethodInvocation) {
					(member as Method).alloc(data)

					expression.args.reject [
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach[alloc(data)]

					expression.args.filter [
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach [ arg |
						if (method !== null) {
							data.temps.put(method.fullyQualifiedName.toString + '.' + arg, data.chunkForVar(arg.sizeOf))
						} else {
							val constructor = expression.getContainerOfType(Constructor)

							if (constructor !== null) {
								data.temps.put(constructor.methodName + '.' + arg, data.chunkForVar(arg.sizeOf))
							} else {
								data.temps.put(expression.containingClass.emptyConstructorName + '.' + arg, data.chunkForVar(arg.sizeOf))
							}
						}
					]
				}

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
		}
	}

	def Collection<MemChunk> alloc(Statement statement, MetaData data) {
		switch (statement) {
			Variable: {
				val method = statement.getContainerOfType(Method)

				if (statement.isROM && statement.storage.type == StorageType.PRGROM) {
					data.prgRoms.add(statement)
				} else if (statement.isROM && statement.storage.type == StorageType.CHRROM) {
					data.chrRoms.add(statement)
				} else if (statement.isConstant && statement.typeOf.isPrimitive) {
					data.constants.add(statement)
				} else if (statement.typeOf.isSingleton && statement.typeOf.nonNESHeader) {
					data.singletons.add(statement.typeOf)
				} else if (method !== null) {
					if (statement.isNonParameter) {
						data.variables.get(method).put(statement, data.chunkForVar(statement.sizeOf))
					} else if (statement.dimensionOf.isNotEmpty) {
						val i = new AtomicInteger(0)

						statement.dimensionOf.map [
							statement.fullyQualifiedName.toString + ".len" + i.andIncrement
						].forEach [
							data.temps.put(method.fullyQualifiedName.toString, data.chunkForVar(1))
						]

						data.pointers.get(method).put(statement, data.chunkForPointer)
					} else if (statement.typeOf.isPrimitive) {
						data.variables.get(method).put(statement, data.chunkForVar(statement.sizeOf))
					} else {
						data.pointers.get(method).put(statement, data.chunkForPointer)
					}
				}

				statement.value?.alloc(data)
			}
			IfStatement: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get

				statement.condition.alloc(data)
				statement.body.statements.forEach[alloc(data)]

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)

				statement.^else?.alloc(data)
			}
			ForStatement: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get

				statement.variables.forEach[alloc(data)]
				statement.assignments.forEach[alloc(data)]
				statement.condition?.alloc(data)
				statement.expressions.forEach[alloc(data)]
				statement.body.statements.forEach[alloc(data)]

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
			ForeverStatement: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get

				statement.body.statements.forEach[alloc(data)]

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
			ReturnStatement:
				if (statement.value !== null && statement.getContainerOfType(Method).typeOf.name !== TypeSystem::LIB_VOID) {
					val method = statement.getContainerOfType(Method)
					val returnVar = NoopFactory::eINSTANCE.createVariable => [
						name = statement.fullyQualifiedName.toString
					]

					data.variables.get(method).put(returnVar, data.chunkForVar(method.sizeOf)) // TODO sizeOf must be the max of all possible return types
				}
			Expression:
				statement.alloc(data)
			AsmStatement:
				statement.vars.forEach[alloc(data)]
		}
	}

	def alloc(ElseStatement statement, MetaData data) {
		val prevPtrCounter = data.ptrCounter.get
		val prevVarCounter = data.varCounter.get

		statement.body.statements.forEach[alloc(data)]

		data.ptrCounter.set(prevPtrCounter)
		data.varCounter.set(prevVarCounter)

		statement.^if?.alloc(data)
	}

}
