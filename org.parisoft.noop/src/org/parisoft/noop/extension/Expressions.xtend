package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.io.File
import java.util.List
import java.util.concurrent.ConcurrentHashMap
import java.util.stream.Collectors
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.CompileContext.Mode
import org.parisoft.noop.generator.CompileContext.Operation
import org.parisoft.noop.generator.MemChunk
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
import org.parisoft.noop.noop.ComplementExpression
import org.parisoft.noop.noop.DecExpression
import org.parisoft.noop.noop.DifferExpression
import org.parisoft.noop.noop.DivExpression
import org.parisoft.noop.noop.EqualsExpression
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.GeExpression
import org.parisoft.noop.noop.GtExpression
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.IncExpression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.InstanceOfExpression
import org.parisoft.noop.noop.LShiftExpression
import org.parisoft.noop.noop.LeExpression
import org.parisoft.noop.noop.LtExpression
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.ModExpression
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
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.SubExpression
import org.parisoft.noop.noop.Super
import org.parisoft.noop.noop.This
import org.parisoft.noop.noop.Variable

import static org.parisoft.noop.^extension.Cache.*

import static extension java.lang.Integer.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.BXorExpression
import org.parisoft.noop.generator.process.AST
import org.parisoft.noop.generator.process.NodeRefClass
import org.parisoft.noop.generator.process.NodeVar
import org.parisoft.noop.generator.process.NodeNew

class Expressions {

	@Inject extension Files
	@Inject extension Datas
	@Inject extension Values
	@Inject extension Classes
	@Inject extension Members
	@Inject extension Methods
	@Inject extension Variables
	@Inject extension Operations
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Collections

	static val recursions = ConcurrentHashMap::<Statement>newKeySet

	def getMember(AssignmentExpression assignment) {
		val left = assignment.left

		if (left instanceof MemberRef) {
			left.member
		} else if (left instanceof MemberSelect) {
			left.member
		}
	}

	def getFieldsInitializedOnContructor(NewInstance instance) {
		instance.type.allFieldsTopDown.filter[nonStatic]
	}

	def getMultiplyMethod(Expression left, Expression right) {
		mulMethods.get(left, right, [
			try {
				val value = right.valueOf
				val const = if (value instanceof Integer) {
						NoopFactory::eINSTANCE.createByteLiteral => [it.value = value]
					} else {
						NoopFactory::eINSTANCE.createStringLiteral => [it.value = value.toString]
					}
				new MethodReference => [args = newArrayList(left, const)]
			} catch (NonConstantExpressionException exception) {
				val value = left.valueOf
				val const = if (value instanceof Integer) {
						NoopFactory::eINSTANCE.createByteLiteral => [it.value = value]
					} else {
						NoopFactory::eINSTANCE.createStringLiteral => [it.value = value.toString]
					}
				new MethodReference => [args = newArrayList(right, const)]
			}
		])
	}

	def getMultiplyMethod(Expression left, Expression right, NoopClass type) {
		try {
			left.getMultiplyMethod(right)
		} catch (NonConstantExpressionException exception) {
			val typeSize = type.sizeOf
			val mul = if (!(typeSize instanceof Integer) || typeSize as Integer > 1) {
					val lhsSize = left.sizeOf
					val rhsSize = right.sizeOf
					val anySizeNonInt = !(lhsSize instanceof Integer) || !(rhsSize instanceof Integer)

					val lhsType = if (anySizeNonInt || (left.sizeOf as Integer) < (right.sizeOf as Integer)) {
							if (left.typeOf.isSigned) {
								left.typeOf.toIntClass
							} else {
								left.typeOf.toUIntClass
							}
						} else {
							left.typeOf
						}

					val rhsType = if (anySizeNonInt || (left.sizeOf as Integer) > (right.sizeOf as Integer)) {
							if (right.typeOf.isSigned) {
								right.typeOf.toIntClass
							} else {
								right.typeOf.toUIntClass
							}
						} else {
							right.typeOf
						}

					if (lhsType.isSigned && rhsType.isUnsigned) {
						new MethodReference => [
							method = type.toMathClass().declaredMethods.findFirst [
								name == '''«Members::STATIC_PREFIX»multiply'''.toString && params.isNotEmpty &&
									params.head.type.isEquals(rhsType) && params.last.type.isEquals(lhsType)
							]
							args = newArrayList(right, left)
						]
					} else {
						new MethodReference => [
							method = type.toMathClass().declaredMethods.findFirst [
								name == '''«Members::STATIC_PREFIX»multiply'''.toString && params.isNotEmpty &&
									params.head.type.isEquals(lhsType) && params.last.type.isEquals(rhsType)
							]
							args = newArrayList(left, right)
						]
					}
				} else {
					new MethodReference => [
						method = type.toMathClass().declaredMethods.findFirst [
							name == '''«Members::STATIC_PREFIX»multiply8Bit'''.toString
						]
						args = newArrayList(left, right)
					]
				}

			mulMethods.put(left, right, mul)

			mul
		}
	}

	def getDivideMethod(Expression left, Expression right) {
		divMethods.get(left, right, [
			if (left.sizeOf == 1) {
				val const = NoopFactory::eINSTANCE.createByteLiteral => [value = right.valueOf as Integer]
				new MethodReference => [args = newArrayList(left, const)]
			} else {
				throw new NonConstantExpressionException(left)
			}
		])
	}

	def getDivideMethod(Expression left, Expression right, NoopClass type) {
		try {
			left.getDivideMethod(right)
		} catch (NonConstantExpressionException exception) {
			val lhsType = if ((left.sizeOf as Integer) < (right.sizeOf as Integer)) {
					if (left.typeOf.isSigned) {
						left.typeOf.toIntClass
					} else {
						left.typeOf.toUIntClass
					}
				} else {
					left.typeOf
				}

			val rhsType = right.typeOf

			val div = if ((lhsType.sizeOf as Integer) > 1 || (lhsType.isUnsigned && rhsType.isSigned)) {
					new MethodReference => [
						method = type.toMathClass().declaredMethods.findFirst [
							name == '''«Members::STATIC_PREFIX»divide'''.toString && params.isNotEmpty &&
								params.head.type.isEquals(lhsType) && params.last.type.isEquals(rhsType)
						]
						args = newArrayList(left, right)
					]
				} else {
					new MethodReference => [
						method = type.toMathClass().declaredMethods.findFirst [
							name == '''«Members::STATIC_PREFIX»divide8Bit'''.toString && params.isNotEmpty &&
								params.head.type.isEquals(lhsType) && params.last.type.isEquals(rhsType)
						]
						args = newArrayList(left, right)
					]
				}

			divMethods.put(left, right, div)

			div
		}
	}

	def getModuloMethod(Expression left, Expression right) {
		modMethods.get(left, right, [
			if (left.sizeOf == 1) {
				val const = NoopFactory::eINSTANCE.createByteLiteral => [value = right.valueOf as Integer]
				new MethodReference => [args = newArrayList(left, const)]
			} else {
				throw new NonConstantExpressionException(left)
			}
		])
	}

	def getModuloMethod(Expression left, Expression right, NoopClass type) {
		try {
			left.getModuloMethod(right)
		} catch (NonConstantExpressionException exception) {
			val lhsType = if ((left.sizeOf as Integer) < (right.sizeOf as Integer)) {
					if (left.typeOf.isSigned) {
						left.typeOf.toIntClass
					} else {
						left.typeOf.toUIntClass
					}
				} else {
					left.typeOf
				}

			val rhsType = right.typeOf

			val mod = new MethodReference => [
				method = type.toMathClass().declaredMethods.findFirst [
					name == '''«Members::STATIC_PREFIX»modulo'''.toString && params.isNotEmpty &&
						params.head.type.isEquals(lhsType) && params.last.type.isEquals(rhsType)
				]
				args = newArrayList(left, right)
			]

			modMethods.put(left, right, mod)

			mod
		}
	}

	def getModuloVariable(Expression expression) {
		expression.toMathClass.declaredFields.findFirst[name == '''«Members::STATIC_PREFIX»mod'''.toString]
	}

	def getLengthExpression(Expression expression) {
		switch (expression) {
			CastExpression: {
				val size = expression.type.sizeOf
				val dim = expression.dimensionOf.reduce[d1, d2|d1 * d2]

				if (size instanceof Integer) {
					NoopFactory::eINSTANCE.createByteLiteral => [value = size * dim]
				} else if (dim > 1) {
					NoopFactory::eINSTANCE.createStringLiteral => [value = '''(«size» * «dim»)''']
				} else {
					NoopFactory::eINSTANCE.createStringLiteral => [value = size.toString]
				}
			}
			MemberSelect:
				expression.member.getLengthExpression(expression.indexes)
			MemberRef:
				expression.member.getLengthExpression(expression.indexes)
		}
	}

	def isMethodInvocation(Expression expression) {
		switch (expression) {
			MulExpression:
				try {
					expression.left.getMultiplyMethod(expression.right).method !== null
				} catch (NonConstantExpressionException e) {
					true
				}
			DivExpression:
				try {
					expression.left.getDivideMethod(expression.right).method !== null
				} catch (NonConstantExpressionException e) {
					true
				}
			ModExpression:
				try {
					expression.left.getModuloMethod(expression.right).method !== null
				} catch (NonConstantExpressionException e) {
					true
				}
			MemberSelect:
				expression.member instanceof Method && (expression.member as Method).isNonNativeArray
			MemberRef:
				expression.member instanceof Method && (expression.member as Method).isNonNativeArray
		}
	}

	def boolean isComplexMemberArrayReference(Expression expression) {
		switch (expression) {
			AssignmentExpression:
				expression.left.isComplexMemberArrayReference
			MemberSelect:
				if (expression.member.isIndexMulDivModExpression(expression.indexes)) {
					val container = expression.eContainer
					val member = if (container instanceof MemberSelect) {
							container.member
						} else if (container instanceof MemberRef) {
							container.member
						}

					if (member instanceof Method) {
						return member.isNonNativeArray
					}

					true
				}
			MemberRef:
				if (expression.member.isIndexMulDivModExpression(expression.indexes)) {
					val container = expression.eContainer
					val member = if (container instanceof MemberSelect) {
							container.member
						} else if (container instanceof MemberRef) {
							container.member
						}

					if (member instanceof Method) {
						return member.isNonNativeArray
					}

					true
				}
		}
	}

	def boolean containsMethodInvocation(Expression expression) {
		expression.isMethodInvocation || expression.isComplexMemberArrayReference ||
			expression.eAllContents.filter(Expression).exists [
				methodInvocation || complexMemberArrayReference
			]
	}

	def isConstant(Expression expression) {
		try {
			expression.valueOf !== null
		} catch (NonConstantExpressionException exception) {
			false
		}
	}

	def isNonConstant(Expression expression) {
		!expression.isConstant
	}

	def isThisOrSuper(Expression expression) {
		expression instanceof This || expression instanceof Super
	}

	def isSuper(Expression expression) {
		expression instanceof Super
	}

	def isNonThisNorSuper(Expression expression) {
		!expression.isThisOrSuper
	}

	def isNonSuper(Expression expression) {
		!expression.isSuper
	}

	def boolean isUnbounded(Expression expression) {
		expression.dimensionOf.isNotEmpty && switch (expression) {
			AssignmentExpression:
				expression.left.isUnbounded
			MemberSelect:
				expression.member.isUnbounded
			MemberRef:
				expression.member.isUnbounded
			default:
				false
		}
	}

	def isOnMemberSelectionOrReference(Expression expression) {
		val container = expression.eContainer
		container !== null && (container instanceof MemberSelect || container instanceof MemberRef ||
			container instanceof ReturnStatement)
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

	def isRecursive(MemberRef ref) {
		val containerMethod = ref.getContainerOfType(Method)

		if (containerMethod !== null) {
			ref.invokes(containerMethod)
		}
	}

	def isRecursive(MemberSelect select) {
		val containerMethod = select.getContainerOfType(Method)

		if (containerMethod !== null) {
			select.invokes(containerMethod)
		}
	}

	def checkRecursion(MemberRef ref, CompileContext ctx) {
		if (ref.isRecursive) {
			ctx.recursiveVars = ref.getContainerOfType(Method).getOverriddenVariablesOnRecursion(ref)
		}
	}

	def checkRecursion(MemberSelect select, CompileContext ctx) {
		if (select.isRecursive) {
			ctx.recursiveVars = select.getContainerOfType(Method).getOverriddenVariablesOnRecursion(select)
		}
	}

	def boolean invokes(Statement statement, Method method) {
		if (recursions.add(statement)) {
			try {
				switch (statement) {
					MemberSelect:
						if (statement.member instanceof Method) {
							statement.member == method || (statement.member as Method).body.statements.exists [
								it.invokes(method)
							]
						}
					MemberRef:
						if (statement.member instanceof Method) {
							statement.member == method || (statement.member as Method).body.statements.exists [
								it.invokes(method)
							]
						}
					IfStatement:
						statement.condition.invokes(method) || statement.body.statements.exists [
							it.invokes(method)
						] || statement.^else?.^if?.invokes(method) || statement.^else?.body?.statements?.exists [
							it.invokes(method)
						]
					default:
						statement.eAllContentsAsList.filter(Statement).exists[it.invokes(method)]
				}
			} finally {
				recursions.remove(statement)
			}
		}
	}

	def boolean containsMulDivMod(Expression expression) {
		switch (expression) {
			OrExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			AndExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			EqualsExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			DifferExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			GtExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			GeExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			LtExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			LeExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			AddExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			SubExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			MulExpression:
				true
			DivExpression:
				true
			ModExpression:
				true
			BOrExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			BXorExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			BAndExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			LShiftExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			RShiftExpression:
				expression.left.containsMulDivMod || expression.right.containsMulDivMod
			ComplementExpression:
				expression.right.containsMulDivMod
			NotExpression:
				expression.right.containsMulDivMod
			SigNegExpression:
				expression.right.containsMulDivMod
			SigPosExpression:
				expression.right.containsMulDivMod
			DecExpression:
				expression.right.containsMulDivMod
			IncExpression:
				expression.right.containsMulDivMod
			CastExpression:
				expression.left.containsMulDivMod
			default:
				false
		}
	}

	def nameOf(This thisExpression) {
		thisExpression.getContainerOfType(Method)?.nameOfReceiver
	}

	def nameOf(Super superExpression) {
		superExpression.getContainerOfType(Method)?.nameOfReceiver
	}

	def nameOfTmpVar(Expression instance, String containerName) {
		'''«containerName».tmp«instance.typeOf.name»@«instance.hashCode.toHexString»'''.toString
	}

	def nameOfElement(List<Index> indexes, String containerName) {
		'''«containerName».ref@«indexes.hashCode.toHexString»'''.toString
	}

	def nameOfTmp(ArrayLiteral array, String containerName) {
		'''«containerName».tmp«array.typeOf.name»Array@«array.hashCode.toHexString»'''.toString
	}

	def nameOfTmpArray(NewInstance instance, String containerName) {
		'''«containerName».tmp«instance.typeOf.name»Array@«instance.hashCode.toHexString»'''.toString
	}

	def nameOfConstructor(NewInstance instance) {
		'''«instance.type.name».new'''.toString
	}

	def nameOfReceiver(NewInstance instance) {
		'''«instance.nameOfConstructor».rcv'''.toString
	}

	def toFile(StringLiteral string) {
		new File(string.eResource.URI.resFolder, string.value.substring(Members::FILE_SCHEMA.length))
	}

	def NoopClass typeOf(Expression expression) {
		if (expression === null) {
			expression.toVoidClass
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
			InstanceOfExpression:
				expression.toBoolClass
			AddExpression:
				expression.typeOfValueOrInt
			SubExpression:
				expression.typeOfValueOrInt
			MulExpression:
				expression.typeOfValueOrMul(expression.left, expression.right)
			DivExpression:
				expression.typeOfValueOrDiv(expression.left, expression.right)
			ModExpression:
				expression.left.typeOf
			BOrExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			BXorExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			BAndExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			LShiftExpression:
				expression.typeOfValueOrInt
			RShiftExpression:
				expression.typeOfValueOrMerge(expression.left, expression.right)
			ComplementExpression:
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
			val leftSize = leftType.sizeOf as Integer
			val rightSize = rightType.sizeOf as Integer

			if (leftSize > rightSize) {
				leftType
			} else if (leftSize < rightSize) {
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

	private def typeOfValueOrMul(Expression expression, Expression left, Expression right) {
		try {
			expression.typeOfValue
		} catch (Exception e) {
			if (left.typeOf.isSigned || right.typeOf.isSigned) {
				expression.toIntClass
			} else {
				expression.toUIntClass
			}
		}
	}

	private def typeOfValueOrDiv(Expression expression, Expression left, Expression right) {
		try {
			expression.typeOfValue
		} catch (Exception exception) {
			val lhsType = left.typeOf
			val rhsType = right.typeOf

			if (rhsType.isUnsigned) {
				lhsType
			} else if (lhsType.isSigned && (lhsType.sizeOf as Integer) <= (rhsType.sizeOf as Integer)) {
				rhsType
			} else {
				lhsType.toIntClass
			}
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
					if (expression.left.typeOf.isNumeric && expression.right.typeOf.isNumeric) {
						(expression.left.valueOf as Integer) * (expression.right.valueOf as Integer)
					} else {
						val left = expression.left
						val right = expression.right
						val leftValue = if(left instanceof StringLiteral) left.value else left.valueOf
						val rightValue = if(right instanceof StringLiteral) right.value else right.valueOf
						'''(«leftValue» * «rightValue»)'''
					}
				DivExpression:
					(expression.left.valueOf as Integer) / (expression.right.valueOf as Integer)
				ModExpression:
					(expression.left.valueOf as Integer) % (expression.right.valueOf as Integer)
				BOrExpression:
					(expression.left.valueOf as Integer).bitwiseOr(expression.right.valueOf as Integer)
				BXorExpression:
					(expression.left.valueOf as Integer).bitwiseXor(expression.right.valueOf as Integer)
				BAndExpression:
					(expression.left.valueOf as Integer).bitwiseAnd(expression.right.valueOf as Integer)
				LShiftExpression:
					(expression.left.valueOf as Integer) << (expression.right.valueOf as Integer)
				RShiftExpression:
					(expression.left.valueOf as Integer) >> (expression.right.valueOf as Integer)
				ComplementExpression:
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
					if (expression.isFileInclude) {
						expression.toFile
					} else {
						expression.value.chars.boxed.collect(Collectors::toList)
					}
				NewInstance:
					if (expression.type.isPrimitive && expression.dimension.isEmpty) {
						expression.type.defaultValueOf
					} else {
						expression.type
					}
				MemberSelect: {
					val member = expression.member
					val receiver = expression.receiver

					if (member instanceof Method && (member as Method).isArrayLength && receiver instanceof MemberRef &&
						(receiver as MemberRef).member.isBounded) {
						expression.receiver.dimensionOf.head
					} else {
						expression.member.valueOf
					}
				}
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

	def List<Integer> dimensionOf(Expression expression) {
		switch (expression) {
			AssignmentExpression:
				expression.left.dimensionOf
			StringLiteral:
				if (expression.isFileInclude) {
					newArrayList(expression.toFile.length as int)
				} else {
					expression.valueOf.dimensionOf
				}
			ArrayLiteral:
				expression.valueOf.dimensionOf
			CastExpression:
				expression.dimension.map[value.valueOf as Integer]
			MemberSelect:
				expression.member.dimensionOf.drop(expression.indexes.size).toList
			MemberRef:
				expression.member.dimensionOf.drop(expression.indexes.size).toList
			NewInstance:
				expression.dimension.map[value.valueOf as Integer]
			default:
				emptyList
		}
	}

	def sizeOf(Expression expression) {
		expression.typeOf.sizeOf
	}

	def fullSizeOf(Expression expression) {
		val size = expression.sizeOf
		val dim = expression.dimensionOf.reduce[d1, d2|d1 * d2] ?: 1

		if (size instanceof Integer) {
			size * dim
		} else if (dim > 1) {
			'''(«size» * «dim»)'''
		} else {
			size
		}
	}

	def void preProcess(Expression expression, AST ast) {
		switch (expression) {
			AssignmentExpression: {
				val left = if (expression.assignment === AssignmentType::ASSIGN) {
						expression.left
					} else {
						copies.computeIfAbsent(expression.left, [expression.left.copy]) as Expression
					}
				val right = if (expression.assignment === AssignmentType::ASSIGN) {
						expression.right
					} else {
						copies.computeIfAbsent(expression.right, [expression.right.copy]) as Expression
					}

				val method = if (expression.assignment === AssignmentType::MUL_ASSIGN) {
						getMultiplyMethod(expression.left, expression.right, expression.left.typeOf).method
					} else if (expression.assignment === AssignmentType::DIV_ASSIGN) {
						getDivideMethod(expression.left, expression.right, expression.left.typeOf).method
					} else if (expression.assignment === AssignmentType::MOD_ASSIGN) {
						getModuloMethod(expression.left, expression.right, expression.left.typeOf).method
					}

				if (method !== null) {
					method.preProcess(ast)
				} else if (expression.assignment === AssignmentType::DIV_ASSIGN ||
					expression.assignment === AssignmentType::MOD_ASSIGN) {
					expression.moduloVariable.preProcess(ast)
				}

				if (expression.assignment === AssignmentType::ASSIGN && left.dimensionOf.isNotEmpty) {
					left.lengthExpression?.preProcess(ast)
					right.lengthExpression?.preProcess(ast)
				}

				left.preProcess(ast)

				if (right.containsMulDivMod) {
					try {
						right.preProcess(ast => [types.put(left.typeOf)])
					} finally {
						ast.types.pop
					}
				} else {
					right.preProcess(ast)
				}
			}
			OrExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			AndExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			EqualsExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			DifferExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			GtExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			GeExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			LtExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			LeExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			InstanceOfExpression: {
				expression.left.preProcess(ast)
				
				if (expression.type.isNonPrimitive) {
					ast.append(new NodeRefClass => [className = expression.type.fullName])
				}
			}
			AddExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			SubExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			MulExpression: {
				val method = getMultiplyMethod(expression.left, expression.right, ast.types.head ?: expression.typeOf).
					method

				if (method !== null) {
					method.preProcessInvocation(newArrayList(expression.left, expression.right), emptyList, ast)
				} else {
					expression.left.preProcess(ast)
					expression.right.preProcess(ast)
				}
			}
			DivExpression: {
				val method = getDivideMethod(expression.left, expression.right, ast.types.head ?: expression.typeOf).
					method

				if (method !== null) {
					method.preProcessInvocation(newArrayList(expression.left, expression.right), emptyList, ast)
				} else {
					expression.left.preProcess(ast)
					expression.right.preProcess(ast)
				}
			}
			ModExpression: {
				val method = getModuloMethod(expression.left, expression.right, ast.types.head ?: expression.typeOf).
					method

				if (method !== null) {
					method.preProcessInvocation(newArrayList(expression.left, expression.right), emptyList, ast)
				} else {
					expression.left.preProcess(ast)
					expression.right.preProcess(ast)
				}
			}
			BOrExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			BXorExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			BAndExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			LShiftExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			RShiftExpression: {
				expression.left.preProcess(ast)
				expression.right.preProcess(ast)
			}
			ComplementExpression:
				expression.right.preProcess(ast)
			NotExpression:
				expression.right.preProcess(ast)
			SigNegExpression:
				expression.right.preProcess(ast)
			SigPosExpression:
				expression.right.preProcess(ast)
			DecExpression:
				expression.right.preProcess(ast)
			IncExpression:
				expression.right.preProcess(ast)
			CastExpression: {
				if (expression.type.isNonPrimitive) {
					ast.append(new NodeRefClass => [className = expression.type.fullName])
				}

				if (expression.left.containsMulDivMod) {
					try {
						expression.left.preProcess(ast => [types.put(expression.type)])
					} finally {
						ast.types.pop
					}
				} else {
					expression.left.preProcess(ast)
				}
			}
			ArrayLiteral: {
				if (expression.typeOf.isNonPrimitive) {
					ast.append(new NodeRefClass => [className = expression.typeOf.fullName])
				}

				expression.eAllContentsAsList.filter [
					it instanceof MemberSelect || it instanceof MemberRef || it instanceof NewInstance
				].forEach [
					(it as Expression).preProcess(ast)
				]

				if (expression.isOnMemberSelectionOrReference) {
					ast.append(new NodeVar => [
						varName = expression.nameOfTmp(ast.container)
						type = expression.typeOf.fullName
						qty = expression.dimensionOf.reduce[d1, d2|d1 * d2] ?: 1
						tmp = true
					])
				}
			}
			NewInstance: {
				if (expression.isOnMemberSelectionOrReference) {
					if (expression.dimension.isEmpty && expression.type.isNonPrimitive) {
						ast.append(new NodeVar => [
							varName = expression.nameOfTmpVar(ast.container)
							type = expression.typeOf.fullName
							tmp = true
						])
					} else if (expression.dimension.isNotEmpty) {
						ast.append(new NodeVar => [
							varName = expression.nameOfTmpArray(ast.container)
							type = expression.typeOf.fullName
							qty = expression.dimensionOf.reduce[d1, d2|d1 * d2] ?: 1
							tmp = true
						])
					}
				}

				if (expression.type.isNonPrimitive) {
					if (expression.type.superClass !== null) {
						(NoopFactory::eINSTANCE.createNewInstance => [type = expression.type.superClass]).
							preProcess(ast)
					}

					ast.append(new NodeRefClass => [className = expression.type.fullName])
					ast.append(new NodeNew => [type = expression.type.fullName])

					val constructorName = expression.nameOfConstructor
					val container = ast.container
					ast.container = constructorName

					ast.append(new NodeVar => [
						varName = expression.nameOfReceiver
						ptr = true
					])

					expression.type.members.filter(Variable).filter[nonStatic].forEach[value.preProcess(ast)]

					ast.container = container

					if (expression.constructor !== null) {
						expression.constructor.fields.forEach[value.preProcess(ast)]
					}
				}
			}
			MemberSelect: {
				val member = expression.member
				val receiver = expression.receiver

				if (member.isStatic && member.typeOf.isNonPrimitive && receiver instanceof NewInstance) {
					ast.append(new NodeRefClass => [className = (receiver as NewInstance).type.fullName])
				}

				if (member instanceof Variable) {
					if (member.isROM) {
						member.preProcessRomReference(expression.indexes, ast)
					} else if (member.isConstant) {
						member.preProcessConstantReference(ast)
					} else if (member.isStatic) {
						member.preProcessStaticReference(expression.indexes, ast)
					} else {
						member.preProcessReference(receiver, expression.indexes, ast)
					}
				} else if (member instanceof Method) {
					if (member.isStatic) {
						member.preProcessInvocation(expression.args, expression.indexes, ast)
					} else {
						member.preProcessInvocation(receiver, expression.args, expression.indexes, ast)
					}
				}
			}
			MemberRef: {
				val member = expression.member

				if (member instanceof Variable) {
					if (member.isField && member.isNonStatic) {
						member.preProcessPointerReference('''«ast.container».rcv''', expression.indexes, ast)
					} else if (member.isParameter && member.isPointer) {
						member.preProcessPointerReference(member.nameOf, expression.indexes, ast)
					} else if (member.isROM) {
						member.preProcessRomReference(expression.indexes, ast)
					} else if (member.isConstant) {
						member.preProcessConstantReference(ast)
					} else if (member.isStatic) {
						member.preProcessStaticReference(expression.indexes, ast)
					} else {
						member.preProcessLocalReference(expression.indexes, ast)
					}
				} else if (member instanceof Method) {
					member.preProcessInvocation(expression.args, expression.indexes, ast)
				}
			}
		}
	}

	def void prepare(Expression expression, AllocContext ctx) {
		if (prepared.add(expression)) {
			switch (expression) {
				AssignmentExpression: {
					val method = if (expression.assignment === AssignmentType::MUL_ASSIGN) {
							getMultiplyMethod(expression.left, expression.right, expression.left.typeOf).method
						} else if (expression.assignment === AssignmentType::DIV_ASSIGN) {
							getDivideMethod(expression.left, expression.right, expression.left.typeOf).method
						} else if (expression.assignment === AssignmentType::MOD_ASSIGN) {
							getModuloMethod(expression.left, expression.right, expression.left.typeOf).method
						}

					if (method !== null) {
						method.prepare(ctx)
					} else if (expression.assignment === AssignmentType::DIV_ASSIGN ||
						expression.assignment === AssignmentType::MOD_ASSIGN) {
						expression.moduloVariable.prepare(ctx)
					}

					if (expression.assignment === AssignmentType::ASSIGN && expression.left.dimensionOf.isNotEmpty) {
						expression.left.lengthExpression?.prepare(ctx)
						expression.right.lengthExpression?.prepare(ctx)
					}

					expression.left.prepare(ctx)

					if (expression.right.containsMulDivMod) {
						try {
							expression.right.prepare(ctx => [types.put(expression.left.typeOf)])
						} finally {
							ctx.types.pop
						}
					} else {
						expression.right.prepare(ctx)
					}
				}
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
				InstanceOfExpression: {
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
					getMultiplyMethod(expression.left, expression.right, ctx.types.head ?: expression.typeOf).method?.
						prepare(ctx)
					expression.left.prepare(ctx)
					expression.right.prepare(ctx)
				}
				DivExpression: {
					val div = getDivideMethod(expression.left, expression.right, ctx.types.head ?: expression.typeOf).
						method

					if (div !== null) {
						div.prepare(ctx)
					} else {
						expression.moduloVariable.prepare(ctx)
					}

					expression.left.prepare(ctx)
					expression.right.prepare(ctx)
				}
				ModExpression: {
					val mod = getModuloMethod(expression.left, expression.right, ctx.types.head ?: expression.typeOf).
						method

					if (mod !== null) {
						mod.prepare(ctx)
					} else {
						expression.moduloVariable.prepare(ctx)
					}

					expression.left.prepare(ctx)
					expression.right.prepare(ctx)
				}
				BOrExpression: {
					expression.left.prepare(ctx)
					expression.right.prepare(ctx)
				}
				BXorExpression: {
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
				ComplementExpression:
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

					if (expression.left.containsMulDivMod) {
						try {
							expression.left.prepare(ctx => [types.put(expression.type)])
						} finally {
							ctx.types.pop
						}
					} else {
						expression.left.prepare(ctx)
					}
				}
				ArrayLiteral: {
					expression.typeOf.prepare(ctx)
					expression.eAllContentsAsList.filter [
						it instanceof MemberSelect || it instanceof MemberRef || it instanceof NewInstance
					].forEach [
						(it as Expression).prepare(ctx)
					]
				}
				NewInstance: {
					expression.type.prepare(ctx)

					if (expression.type.isNonPrimitive) {
						expression.fieldsInitializedOnContructor.forEach[prepare(ctx)]

						if (expression.constructor !== null) {
							expression.constructor.fields.forEach[value.prepare(ctx)]
						}
					}
				}
				MemberSelect: {
					val member = expression.member

					if (member instanceof Variable) {
						member.prepareReference(expression.receiver, expression.indexes, ctx)
					} else if (member instanceof Method) {
						member.prepareInvocation(expression.receiver, expression.args, expression.indexes, ctx)
					}
				}
				MemberRef: {
					val member = expression.member

					if (member instanceof Variable) {
						member.prepareReference(expression.indexes, ctx)
					} else if (member instanceof Method) {
						member.prepareInvocation(expression.args, expression.indexes, ctx)
					}
				}
			}
		}
	}

	def List<MemChunk> alloc(Expression expression, AllocContext ctx) {
		allocated.get(expression, [
			switch (expression) {
				AssignmentExpression: {
					val chunks = newArrayList
					val left = if (expression.assignment === AssignmentType::ASSIGN) {
							expression.left
						} else {
							copies.computeIfAbsent(expression.left, [expression.left.copy]) as Expression
						}
					val right = if (expression.assignment === AssignmentType::ASSIGN) {
							expression.right
						} else {
							copies.computeIfAbsent(expression.right, [expression.right.copy]) as Expression
						}

					if (expression.assignment === AssignmentType::MUL_ASSIGN) {
						chunks += getMultiplyMethod(left, right, left.typeOf).method?.alloc(ctx) ?: emptyList
					} else if (expression.assignment === AssignmentType::DIV_ASSIGN) {
						chunks += getDivideMethod(left, right, left.typeOf).method?.alloc(ctx) ?: emptyList
					} else if (expression.assignment === AssignmentType::MOD_ASSIGN) {
						chunks += getModuloMethod(left, right, left.typeOf).method?.alloc(ctx) ?: emptyList
					} else if (expression.assignment === AssignmentType::ASSIGN && left.dimensionOf.isNotEmpty) {
						chunks += left.lengthExpression?.alloc(ctx) ?: emptyList
						chunks += right.lengthExpression?.alloc(ctx) ?: emptyList
					}

					chunks += left.alloc(ctx)

					if (right.containsMulDivMod) {
						try {
							chunks += right.alloc(ctx => [types.put(left.typeOf)])
						} finally {
							ctx.types.pop
						}
					} else {
						chunks += right.alloc(ctx)
					}

					return chunks
				}
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
				InstanceOfExpression:
					expression.left.alloc(ctx)
				AddExpression:
					(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
				SubExpression:
					(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
				MulExpression: {
					val method = getMultiplyMethod(expression.left, expression.right,
						ctx.types.head ?: expression.typeOf).method

					if (method !== null) {
						method.allocInvocation(newArrayList(expression.left, expression.right), emptyList, ctx)
					} else {
						(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
					}
				}
				DivExpression: {
					val method = getDivideMethod(expression.left, expression.right,
						ctx.types.head ?: expression.typeOf).method

					if (method !== null) {
						method.allocInvocation(newArrayList(expression.left, expression.right), emptyList, ctx)
					} else {
						(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
					}
				}
				ModExpression: {
					val method = getModuloMethod(expression.left, expression.right,
						ctx.types.head ?: expression.typeOf).method

					if (method !== null) {
						method.allocInvocation(newArrayList(expression.left, expression.right), emptyList, ctx)
					} else {
						(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
					}
				}
				BOrExpression:
					(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
				BXorExpression:
					(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
				BAndExpression:
					(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
				LShiftExpression:
					(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
				RShiftExpression:
					(expression.left.alloc(ctx) + expression.right.alloc(ctx)).toList
				ComplementExpression:
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
				CastExpression: {
					expression.type.alloc(ctx)

					if (expression.left.containsMulDivMod) {
						try {
							expression.left.alloc(ctx => [types.put(expression.type)])
						} finally {
							ctx.types.pop
						}
					} else {
						expression.left.alloc(ctx)
					}
				}
				ArrayLiteral: {
					val chunks = expression.values.map[alloc(ctx)].flatten.toList

					if (expression.isOnMemberSelectionOrReference) {
						chunks += ctx.computeTmp(expression.nameOfTmp(ctx.container), expression.fullSizeOf as Integer)
					}

					return chunks
				}
				NewInstance: {
					val chunks = newArrayList

					if (expression.isOnMemberSelectionOrReference) {
						if (expression.dimension.isEmpty && expression.type.isNonPrimitive) {
							chunks +=
								ctx.computeTmp(expression.nameOfTmpVar(ctx.container), expression.sizeOf as Integer)
						} else if (expression.dimension.isNotEmpty) {
							chunks +=
								ctx.computeTmp(expression.nameOfTmpArray(ctx.container),
									expression.fullSizeOf as Integer)
						}
					}

					if (expression.type.isNonPrimitive) {
						expression.type.alloc(ctx)

						val snapshot = ctx.snapshot
						val constructorName = expression.nameOfConstructor

						ctx.container = constructorName

						chunks += ctx.computePtr(expression.nameOfReceiver)
						chunks += expression.fieldsInitializedOnContructor.map[value.alloc(ctx)].flatten.toList
						chunks.disoverlap(constructorName)

						ctx.restoreTo(snapshot)
						ctx.constructors.put(expression.type.nameOf, expression)

						if (expression.constructor !== null) {
							chunks += expression.constructor.fields.map[variable.value.alloc(ctx)].flatten.toList
						}
					}

					return chunks
				}
				MemberSelect: {
					val chunks = newArrayList
					val member = expression.member
					val receiver = expression.receiver

					if (member.isStatic && receiver instanceof NewInstance) {
						(receiver as NewInstance).type.alloc(ctx)
					}

					if (member instanceof Variable) {
						if (member.isROM) {
							chunks += member.allocRomReference(expression.indexes, ctx)
						} else if (member.isConstant) {
							chunks += member.allocConstantReference(ctx)
						} else if (member.isStatic) {
							chunks += member.allocStaticReference(expression.indexes, ctx)
						} else {
							chunks += member.allocReference(receiver, expression.indexes, ctx)
						}
					} else if (member instanceof Method) {
						if (member.isStatic) {
							chunks += member.allocInvocation(expression.args, expression.indexes, ctx)
						} else {
							chunks += member.allocInvocation(receiver, expression.args, expression.indexes, ctx)
						}
					}

					return chunks
				}
				MemberRef: {
					val chunks = newArrayList
					val member = expression.member

					if (member instanceof Variable) {
						if (member.isField && member.isNonStatic) {
							chunks += member.allocPointerReference('''«ctx.container».rcv''', expression.indexes, ctx)
						} else if (member.isParameter &&
							(member.type.isNonPrimitive || member.dimensionOf.isNotEmpty)) {
							chunks += member.allocPointerReference(member.nameOf, expression.indexes, ctx)
						} else if (member.isROM) {
							chunks += member.allocRomReference(expression.indexes, ctx)
						} else if (member.isConstant) {
							chunks += member.allocConstantReference(ctx)
						} else if (member.isStatic) {
							chunks += member.allocStaticReference(expression.indexes, ctx)
						} else {
							chunks += member.allocLocalReference(expression.indexes, ctx)
						}
					} else if (member instanceof Method) {
						chunks += member.allocInvocation(expression.args, expression.indexes, ctx)
					}

					return chunks
				}
				default:
					newArrayList
			}
		])
	}

	def String compile(Expression expression, CompileContext ctx) {
		try {
			val value = new CompileContext => [
				container = ctx?.container
				operation = ctx?.operation
				type = expression.typeOf
				immediate = expression.compileConstant
			]
			value.resolveTo(ctx)?.toString
		} catch (NonConstantExpressionException e) {
			switch (expression) {
				AssignmentExpression: '''
					«val left = if (expression.assignment === AssignmentType::ASSIGN) {
							expression.left
						} else {
							copies.get(expression.left) as Expression
						}»
					«val right = if (expression.assignment === AssignmentType::ASSIGN) {
							expression.right
						} else {
							copies.get(expression.right) as Expression
						}»
					«val ref = new CompileContext => [
						container = ctx.container
						operation = ctx.operation
						type = left.typeOf
						mode = Mode::REFERENCE
					]»
					«val refCompiled = left.compile(ref)»
					«IF expression.assignment === AssignmentType::ASSIGN»
						«refCompiled»
						«right.compile(ref => [
							mode = Mode::COPY
							lengthExpression = left.lengthExpression
						])»
					«ELSEIF expression.assignment === AssignmentType::ADD_ASSIGN»
						«val add = NoopFactory::eINSTANCE.createAddExpression => [
							it.left = left
							it.right = right
						]»
						«add.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::SUB_ASSIGN»
						«val sub = NoopFactory::eINSTANCE.createSubExpression => [
							it.left = left
							it.right = right
						]»
						«sub.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::MUL_ASSIGN»
						«val mul = NoopFactory::eINSTANCE.createMulExpression => [
							it.left = left
							it.right = right
						]»
						«mul.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::DIV_ASSIGN»
						«val div = NoopFactory::eINSTANCE.createDivExpression => [
							it.left = left
							it.right = right
						]»
						«div.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::MOD_ASSIGN»
						«val mod = NoopFactory::eINSTANCE.createModExpression => [
							it.left = left
							it.right = right
						]»
						«mod.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BOR_ASSIGN»
						«val bor = NoopFactory::eINSTANCE.createBOrExpression => [
							it.left = left
							it.right = right
						]»
						«bor.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::XOR_ASSIGN»
						«val xor = NoopFactory::eINSTANCE.createBXorExpression => [
							it.left = left
							it.right = right
						]»
						«xor.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BAN_ASSIGN»
						«val ban = NoopFactory::eINSTANCE.createBAndExpression => [
							it.left = left
							it.right = right
						]»
						«ban.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BLS_ASSIGN»
						«val bls = NoopFactory::eINSTANCE.createLShiftExpression => [
							it.left = left
							it.right = right
						]»
						«bls.compile(ref => [mode = Mode::COPY])»
					«ELSEIF expression.assignment === AssignmentType::BRS_ASSIGN»
						«val brs = NoopFactory::eINSTANCE.createRShiftExpression => [
							it.left = left
							it.right = right
						]»
						«brs.compile(ref => [mode = Mode::COPY])»
					«ENDIF»
					«IF ctx.mode != Mode::COPY || ctx.absolute !== null || ctx.indirect !== null || ctx.register !== null || ctx.relative !== null»
						«left.compile(ctx)»
					«ENDIF»
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
				MulExpression: '''«Operation::MULTIPLICATION.compileMultiplication(expression.left, expression.right, ctx)»'''
				DivExpression: '''«Operation::DIVISION.compileMultiplication(expression.left, expression.right, ctx)»'''
				ModExpression: '''«Operation::MODULO.compileMultiplication(expression.left, expression.right, ctx)»'''
				BOrExpression: '''«Operation::BIT_OR.compileBinary(expression.left, expression.right, ctx)»'''
				BXorExpression: '''«Operation::BIT_XOR.compileBinary(expression.left, expression.right, ctx)»'''
				BAndExpression: '''«Operation::BIT_AND.compileBinary(expression.left, expression.right, ctx)»'''
				LShiftExpression: '''«Operation::BIT_SHIFT_LEFT.compileMultiplication(expression.left, expression.right, ctx)»'''
				RShiftExpression: '''«Operation::BIT_SHIFT_RIGHT.compileMultiplication(expression.left, expression.right, ctx)»'''
				ComplementExpression: '''«Operation::BIT_EXCLUSIVE_OR.compileUnary(expression.right, ctx)»'''
				NotExpression: '''«expression.right.compileNot(ctx)»'''
				SigNegExpression: '''«Operation::SIGNUM.compileUnary(expression.right, ctx)»'''
				SigPosExpression: '''«expression.right.compile(ctx)»'''
				DecExpression: '''«Operation::DECREMENT.compileInc(expression.right, ctx)»'''
				IncExpression: '''«Operation::INCREMENT.compileInc(expression.right, ctx)»'''
				CastExpression: '''«expression.left.compile(ctx)»'''
				InstanceOfExpression: '''
					«val subClasses = newArrayList(expression.type) + expression.type.subClasses»
					«val leftClass = new CompileContext => [
						container = ctx.container
						operation = ctx.operation
						accLoaded = ctx.isAccLoaded
						type = expression.type.toByteClass
						register = 'A'
					]»
					«expression.left.compile(leftClass)»
					«val comparisonIsFalse = labelForComparisonIsFalse»
					«val comparisonIsTrue = labelForComparisonIsTrue»
					«val comparisonEnd = labelForComparisonEnd»
					«FOR subClass : subClasses»
						«noop»
							CMP #«subClass.nameOf»
							BEQ +«IF ctx.relative !== null»«ctx.relative»«ELSE»«comparisonIsTrue»«ENDIF»
					«ENDFOR»
					«IF ctx.relative === null»
						+«comparisonIsFalse»:
							LDA #«Members::FALSE»
							JMP +«comparisonEnd»
						+«comparisonIsTrue»:
							LDA #«Members::TRUE»
						+«comparisonEnd»:
						«leftClass.resolveTo(ctx)»
					«ENDIF»
				'''
				ByteLiteral: '''
					«val src = new CompileContext => [
						type = expression.typeOf
						immediate = expression.value.toHex.toString
					]»
					«src.resolveTo(ctx)»
				'''
				BoolLiteral: '''
					«val boolAsByte = NoopFactory::eINSTANCE.createByteLiteral => [value = if (expression.value) 1 else 0]»
					«boolAsByte.compile(ctx)»
				'''
				StringLiteral: '''
					«IF ctx.db !== null»
						«IF ctx.db != '+'»
							«ctx.db»:
						«ENDIF»
						«IF expression.isFileInclude»
							«val filepath = expression.toFile.absolutePath»
								«IF expression.isAsmFile || expression.isIncFile»
									.include "«filepath»"
								«ELSE»
									.incbin "«filepath»"
								«ENDIF»
						«ELSE»
							«FOR chunk : expression.value.toBytes.chunked»
								«noop»
									.db «(chunk as List<?>).map[it as Integer].join(', ', [toHex])»
							«ENDFOR»
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
						«val chunks = expression.values.flat.chunked»
						«val db = if (expression.sizeOf as Integer > 1) '.dw' else '.db'»
						«FOR chunk : chunks»
							«IF chunk instanceof List<?>»
								«noop»
									«db» «chunk.map[it as Integer].join(', ', [toHex])»
							«ELSE»
								«(chunk as StringLiteral).compile(new CompileContext => [it.db = '+'])»
							«ENDIF»
						«ENDFOR»
					«ELSE»
						«val tmp = if (expression.isOnMemberSelectionOrReference) {	
								new CompileContext => [	
									container = ctx.container
									operation = ctx.operation
									absolute = expression.nameOfTmp(ctx.container)
									type = ctx.type]
							} else {
								ctx.clone
							}
						»
						«val elements = expression.flatList»
						«FOR i : 0 ..< elements.size»
							«val dst = tmp.clone»
							«IF i > 0»
								«IF dst.absolute !== null»
									«dst.absolute = '''«dst.absolute» + («i» * «expression.sizeOf»)'''»
								«ELSEIF dst.indirect !== null && dst.index.startsWith('#')»
									«dst.index = '''«dst.index» + («i» * «expression.sizeOf»)'''»
								«ELSEIF dst.indirect !== null && dst.isIndexed»
									«ctx.pushAccIfOperating»
										CLC
										LDA «dst.index»
										ADC #«expression.sizeOf»
										STA «dst.index»
									«ctx.pullAccIfOperating»
								«ELSEIF dst.indirect !== null»
									«dst.index = '''#(«i» * «expression.sizeOf»)'''»
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
							LDA #«expression.type.nameOf»
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
						«val length = expression.dimensionOf.reduce[d1, d2| d1 * d2]»
						«IF ctx.db !== null»
							«ctx.db»:
								.dsb («length» * «ctx.sizeOf»)
						«ELSE»
							«IF expression.type.isPrimitive»
								«(new CompileContext => [immediate = '0']).copyTo(ctx)»
							«ELSE»
								«val constructor = expression.copy => [dimension.clear]»
								«constructor.compile(ctx)»
							«ENDIF»
							«ctx.fillArray(length)»
						«ENDIF»
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
					«IF member instanceof Variable»
						«IF member.isROM»
							«member.compileRomReference(expression.indexes, ctx)»
						«ELSEIF member.isConstant»
							«member.compileConstantReference(ctx)»
						«ELSEIF member.isStatic»
							«member.compileStaticReference(expression.indexes, ctx)»
						«ELSE»
							«member.compileReference(receiver, expression.indexes, ctx)»
						«ENDIF»
					«ELSEIF member instanceof Method»
						«expression.checkRecursion(ctx)»
						«val method = member as Method»
						«IF method.isStatic»
							«method.compileInvocation(expression.args, expression.indexes, ctx)»
						«ELSE»
							«method.compileInvocation(receiver, expression.args, expression.indexes, ctx)»
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
						«ELSEIF member.isROM»
							«member.compileRomReference(expression.indexes, ctx)»
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
						«expression.checkRecursion(ctx)»
						«IF method.isStatic»
							«method.compileInvocation(expression.args, expression.indexes, ctx)»
						«ELSE»
							«method.compileInvocation(null, expression.args, expression.indexes, ctx)»
						«ENDIF»
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
				ModExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» % «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				BOrExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» | «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				BXorExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» ^ «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				BAndExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» & «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				LShiftExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» << «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				RShiftExpression: '''«IF wrapped»(«ENDIF»«expression.left.compileConstant» >> «expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
				ComplementExpression: '''«IF wrapped»(«ENDIF»~«expression.right.compileConstant»«IF wrapped»)«ENDIF»'''
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
					if (expression.type.isPrimitive && expression.dimension.isEmpty) {
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
				accLoaded = ctx.accLoaded
				type = expression.typeOf
				operation = incOperation
				mode = Mode::OPERATE
			]»
		«expression.compile(inc)»
		«expression.compile(ctx)»
	'''

	private def compileBinary(Operation binaryOperation, Expression left, Expression right, CompileContext ctx) '''
		«val ctxSize = try { ctx.sizeOf as Integer } catch(Exception e) {2}»
		«val leftSize = try { left.sizeOf as Integer } catch(Exception e) {2}»
		«val accType = if (ctxSize > leftSize || binaryOperation.isComparison || binaryOperation.isDivision) left.typeOf else ctx.type»
		«val lda = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			type = accType
			register = 'A'
			mode = Mode::COPY
		]»
		«val opr = new CompileContext => [
			container = ctx.container
			operation = binaryOperation
			relative = ctx.relative
			type = accType
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
			i = 0
				.rept «ctx.type.sizeOf»
				STA «Members::TEMP_VAR_NAME2» + i
				PLA
				i = i + 1
				.endr
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

	private def compileMultiplication(Operation operation, Expression left, Expression right, CompileContext ctx) {
		switch (operation) {
			case MULTIPLICATION: {
				val mult = getMultiplyMethod(left, right, ctx.type)

				if (mult.method !== null) {
					mult.method.compileInvocation(mult.args, null, ctx)
				} else {
					operation.compileBinary(mult.args.head, mult.args.last, ctx)
				}
			}
			case DIVISION: {
				val div = getDivideMethod(left, right, ctx.type)

				if (div.method !== null) {
					div.method.compileInvocation(div.args, null, ctx)
				} else {
					operation.compileBinary(div.args.head, div.args.last, ctx)
				}
			}
			case MODULO: {
				val mod = getModuloMethod(left, right, ctx.type)

				if (mod.method !== null) {
					mod.method.compileInvocation(mod.args, null, ctx)
				} else {
					operation.compileBinary(mod.args.head, mod.args.last, ctx)
				}
			}
			default:
				try {
					val const = NoopFactory::eINSTANCE.createByteLiteral => [value = left.valueOf as Integer]
					operation.compileBinary(const, right, ctx)
				} catch (NonConstantExpressionException exception) {
					try {
						val const = NoopFactory::eINSTANCE.createByteLiteral => [value = right.valueOf as Integer]
						operation.compileBinary(left, const, ctx)
					} catch (NonConstantExpressionException exception2) {
						operation.compileBinary(left, right, ctx)
					}
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
			accLoaded = true
			mode = Mode::OPERATE
		]»
		«IF ctx.operation !== null && ctx.isAccLoaded»
			«ctx.accLoaded = false»
				PHA
		«ENDIF» 
		«expr.compile(lda)»
		«acc.operate»
		«IF ctx.mode === Mode::OPERATE»
			«FOR i : 0 ..< ctx.sizeOf as Integer»
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
				expr.right.compile(ctx)
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

	private def List<?> flat(List<Expression> list) {
		val flatten = <Object>newArrayList

		for (expr : list) {
			switch (expr) {
				ByteLiteral: flatten += expr.value
				BoolLiteral: flatten += if(expr.value) 1 else 0
				ArrayLiteral: flatten += expr.values.flat
				StringLiteral: flatten += expr
				default: flatten += expr.valueOf
			}
		}

		flatten
	}

	private def List<?> chunked(List<?> list) {
		val chunks = <Object>newArrayList
		var List<Integer> last

		for (value : list) {
			if (value instanceof Integer) {
				if (last === null || last.size == 32) {
					last = <Integer>newArrayList
					chunks.add(last)
				}

				last += value
			} else {
				last = null
				chunks += value
			}
		}

		chunks
	}

	private def void noop() {
	}

	static class MethodReference {
		@Accessors var Method method
		@Accessors var List<Expression> args
	}
}
