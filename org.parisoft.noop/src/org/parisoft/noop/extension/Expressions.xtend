package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.stream.Collectors
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.generator.MetaData
import org.parisoft.noop.generator.NoopInstance
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.AsmStatement
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

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*

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

	def isVoid(ReturnStatement ^return) {
		^return === null || ^return.value === null || ^return.method.typeOf.name == TypeSystem.LIB_VOID
	}

	def isNonVoid(ReturnStatement ^return) {
		!^return.isVoid
	}

	def isVariableDefinitionOrAssignment(Expression expression) {
		expression.eContainer instanceof Variable || expression.eContainer instanceof AssignmentExpression
	}

	def getMethod(ReturnStatement ^return) {
		^return.getContainerOfType(Method)
	}

	def asmName(ReturnStatement ^return) {
		^return.getContainerOfType(Method).fullyQualifiedName.toString + '.return'
	}

	def asmName(ArrayLiteral array, String containerName) {
		containerName + '.' + array.typeOf.name.toFirstLower + 'Array@' + Integer.toHexString(array.hashCode)
	}

	def asmArrayName(NewInstance instance, String containerName) {
		containerName + '.new' + instance.typeOf.name + 'Array@' + Integer.toHexString(instance.hashCode)
	}

	def asmVarName(NewInstance instance, String containerName) {
		containerName + '.new' + instance.typeOf.name + '@' + Integer.toHexString(instance.hashCode)
	}

	def asmConstructorName(NewInstance instance) {
		instance.type.name + instance.type.name + Integer.toHexString(instance.constructor?.fields.map[variable].join.hashCode) ?: ''
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

	def List<MemChunk> alloc(Expression expression, MetaData data) {
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
				if (expression.isVariableDefinitionOrAssignment) {
					newArrayList
				} else {
					data.variables.computeIfAbsent(expression.asmName(data.container), [ name |
						newArrayList(data.chunkForVar(name, expression.fullSizeOf))
					])
				}
			NewInstance:
				if (expression.isVariableDefinitionOrAssignment) {
					newArrayList
				} else if (expression.dimension.isNotEmpty) {
					data.variables.computeIfAbsent(expression.asmArrayName(data.container), [ name |
						newArrayList(data.chunkForVar(name, expression.fullSizeOf))
					])
				} else {
					var allChunks = newArrayList 
					
					allChunks += data.variables.computeIfAbsent(expression.asmVarName(data.container), [ name |
						newArrayList(data.chunkForVar(name, expression.sizeOf))
					])

					val constructorName = expression.asmConstructorName
					val constructorArgs = expression.constructor?.fields ?: emptyList
					val snapshot = data.snapshot

					snapshot.container = constructorName

					if (expression.type.isNonSingleton) {
						allChunks += data.pointers.computeIfAbsent(constructorName + '.receiver', [newArrayList(data.chunkForPointer(it))])
					}

					allChunks += expression.type.inheritedFields.map [ field |
						val arg = constructorArgs.findFirst[variable  == field]

						if (arg !== null) {
							val copy = field.copy
							copy.value = arg.value
							copy.alloc(data)
						} else {
							field.alloc(data)
						}
					].flatten

					val innerChunks = allChunks.filter[variable.startsWith(constructorName)].sort
					val outerChunks = allChunks.reject[variable.startsWith(constructorName)].sort

					innerChunks.filter[isZP].disjoint(outerChunks.filter[isZP])
					innerChunks.reject[isZP].disjoint(outerChunks.reject[isZP])

					data.restoreTo(snapshot)

					allChunks
				}
			MemberSelection:
				if (expression.isInstanceOf || expression.isCast) {
					val snapshot = data.snapshot
					val chunks = expression.receiver.alloc(data)

					data.restoreTo(snapshot)

					return chunks
				} else if (expression.isMethodInvocation) {
					val snapshot = data.snapshot
					val chunks = expression.receiver.alloc(data)
					chunks += expression.args.map[alloc(data)].flatten
					chunks += (expression.member as Method).alloc(data)

					data.restoreTo(snapshot)

					return chunks.toList
				} else if ((expression.member as Variable).isConstant && expression.typeOf.isPrimitive) {
					data.constants += expression.member as Variable
					return newArrayList
				} else {
					return newArrayList
				}
			MemberRef: {
				if (expression.isMethodInvocation) {
					val snapshot = data.snapshot
					val chunks = (expression.member as Method).alloc(data) + expression.args.map[alloc(data)].flatten

					data.restoreTo(snapshot)

					return chunks.toList
				} else if ((expression.member as Variable).isConstant && expression.typeOf.isPrimitive) {
					data.constants += expression.member as Variable
					return newArrayList
				} else {
					return newArrayList
				}
			}
			default:
				newArrayList
		}
	}

	def List<MemChunk> alloc(Statement statement, MetaData data) {
		switch (statement) {
			Variable: {
				val name = statement.asmName(data.container)
				val ptrChunks = data.pointers.computeIfAbsent(name, [newArrayList])
				val varChunks = data.variables.computeIfAbsent(name, [newArrayList])
				val allChunks = ptrChunks + varChunks

				if (allChunks.isEmpty) {
					if (statement.isParameter) {
						if (statement.type.isNonPrimitive || statement.dimensionOf.isNotEmpty) {
							ptrChunks += data.chunkForPointer(name)

							for (i : 0 ..< statement.dimensionOf.size) {
								varChunks += data.chunkForVar(name + '.len' + i, 1)
							}

							statement.type.alloc(data)
						} else {
							varChunks += data.chunkForVar(name, statement.sizeOf)
						}
					} else if (statement.isROM) {
						if (statement.storage.type == StorageType.PRGROM) {
							data.prgRoms += statement
						} else if (statement.storage.type == StorageType.CHRROM) {
							data.chrRoms += statement
						}
					} else if (statement.isConstant) {
						val type = statement.typeOf

						if (type.isNESHeader) {
							data.header = statement
						} else if (type.isSingleton) {
							data.singletons += type
						} else if (type.isPrimitive) {
							data.constants += statement
						}
					} else {
						varChunks += data.chunkForVar(name, statement.sizeOf)
						statement.typeOf.alloc(data)
					}
				}

				return (allChunks + statement?.value.alloc(data)).toList
			}
			IfStatement: {
				val snapshot = data.snapshot
				val chunks = statement.condition.alloc(data) + statement.body.statements.map[alloc(data)].flatten

				data.restoreTo(snapshot)
				return (chunks + statement.^else?.alloc(data)).toList
			}
			ForStatement: {
				val snapshot = data.snapshot
				val chunks = statement.variables.map[alloc(data)].flatten.toList
				chunks += statement.assignments.map[alloc(data)].flatten
				chunks += statement.condition?.alloc(data)
				chunks += statement.expressions.map[alloc(data)].flatten
				chunks += statement.body.statements.map[alloc(data)].flatten

				data.restoreTo(snapshot)

				return chunks
			}
			ForeverStatement: {
				val snapshot = data.snapshot
				val chunks = statement.body.statements.map[alloc(data)].flatten

				data.restoreTo(snapshot)

				return chunks.toList
			}
			ReturnStatement:
				if (statement.isNonVoid) {
					if (statement.method.typeOf.isPrimitive) {
						data.variables.compute(statement.asmName, [ name, v |
							newArrayList(data.chunkForVar(name, statement.method.sizeOf))
						])
					} else {
						data.pointers.compute(statement.asmName, [ name, v |
							newArrayList(data.chunkForPointer(name))
						])
					}
				} else {
					newArrayList
				}
			Expression:
				statement.alloc(data)
			AsmStatement:
				statement.vars.map[alloc(data)].flatten.toList
			default:
				newArrayList
		}
	}

	def alloc(ElseStatement statement, MetaData data) {
		val snapshot = data.snapshot
		val chunks = statement.body.statements.map[alloc(data)].flatten

		data.restoreTo(snapshot)

		return chunks + statement.^if?.alloc(data)
	}

}
