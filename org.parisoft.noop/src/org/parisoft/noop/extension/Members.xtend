package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.ArrayList
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.process.AST
import org.parisoft.noop.generator.process.NodeVar
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable

import static org.parisoft.noop.^extension.Cache.*

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

class Members {

	public static val STATIC_PREFIX = '$'
	public static val PRIVATE_PREFIX = '_'
	public static val TEMP_VAR_NAME1 = 'rash'
	public static val TEMP_VAR_NAME2 = 'zitz'
	public static val TEMP_VAR_NAME3 = 'pimp'
	public static val FT_DPCM_OFF = 'FT_DPCM_OFF'
	public static val FT_DPCM_PTR = 'FT_DPCM_PTR'
	public static val TRUE = 'TRUE'
	public static val FALSE = 'FALSE'
	public static val FILE_SCHEMA = 'file://'
	public static val FILE_ASM_EXTENSION = '.asm'
	public static val FILE_INC_EXTENSION = '.inc'
	public static val FILE_DMC_EXTENSION = '.dmc'
	public static val MATH_MOD = '''«TypeSystem::LIB_MATH».«STATIC_PREFIX»mod'''
	public static val METHOD_ARRAY_LENGTH = 'length'

	@Inject extension Datas
	@Inject extension Classes
	@Inject extension Methods
	@Inject extension Variables
	@Inject extension TypeSystem
	@Inject extension Expressions
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	def Expression getLengthExpression(Member member, List<Index> indices) {
		if (member.isBounded) {
			val size = member.typeOf.sizeOf
			val dim = member.dimensionOf.drop(indices.size).reduce[d1, d2|d1 * d2] ?: 1

			if (size instanceof Integer) {
				NoopFactory::eINSTANCE.createByteLiteral => [value = size * dim]
			} else if (dim > 1) {
				NoopFactory::eINSTANCE.createStringLiteral => [value = '''(«size» * «dim»)''']
			} else {
				NoopFactory::eINSTANCE.createStringLiteral => [value = size.toString]
			}
		} else if (member instanceof Variable) {
			val allIndices = new ArrayList<List<Expression>>

			for (i : indices.size ..< member.dimensionOf.size) {
				val list = new ArrayList<Expression>

				for (j : 0 ..< i) {
					list += NoopFactory::eINSTANCE.createByteLiteral => [value = 0]
				}

				allIndices.add(list)
			}

			val tSize = member.typeOf.sizeOf
			val size = if (tSize instanceof Integer) {
					NoopFactory::eINSTANCE.createByteLiteral => [value = tSize]
				} else {
					NoopFactory::eINSTANCE.createStringLiteral => [value = tSize.toString]
				}
			val arrayLengthMethod = member.typeOf.allMethodsTopDown.findFirst[arrayLength]
			val length = allIndices.map [ list |
				NoopFactory::eINSTANCE.createMemberSelect => [
					it.member = arrayLengthMethod
					it.receiver = NoopFactory::eINSTANCE.createMemberRef => [
						it.member = member
						it.indices += list.map[aByte|NoopFactory::eINSTANCE.createIndex => [value = aByte]]
					]
				]
			].reduce [ Expression len1, len2 |
				val mul = NoopFactory.eINSTANCE.createMulExpression => [
					left = len1
					right = len2
				]

				mul
			]

			NoopFactory::eINSTANCE.createMulExpression => [
				left = size
				right = length
			]
		}
	}

	def isField(Member member) {
		member instanceof Variable && (member as Variable).isField
	}

	def isAccessibleFrom(Member member, EObject context) {
		if (context instanceof MemberSelect) {
			val receiverClass = context.receiver.typeOf
			receiverClass.isSubclassOf(member.containerClass) &&
				(member.isPublic || context.containerClass.isSubclassOf(receiverClass))
		} else {
			context.containerClass.isSubclassOf(member.containerClass)
		}
	}

	def isNonAccessibleFrom(Member member, EObject context) {
		!member.isAccessibleFrom(context)
	}

	def isStatic(Member member) {
		if (member === null || member.name === null) {
			false
		} else {
			member.name.startsWith(STATIC_PREFIX) || (member.name.startsWith(PRIVATE_PREFIX) &&
				member.name.charAt(1) === STATIC_PREFIX.charAt(0))
		}
	}

	def isNonStatic(Member member) {
		!member.isStatic
	}

	def isPrivate(Member member) {
		if (member === null || member.name === null) {
			false
		} else {
			member.name.startsWith(PRIVATE_PREFIX) || (member.name.startsWith(STATIC_PREFIX) &&
				member.name.charAt(1) === PRIVATE_PREFIX.charAt(0))
		}
	}

	def isPublic(Member member) {
		!member.isPrivate
	}

	def isROM(Member member) {
		switch (member.storage?.type) {
			case CHRROM: true
			case PRGROM: true
			default: false
		}
	}

	def isNonROM(Member member) {
		!member.isROM
	}

	def isUnbounded(Member member) {
		!member.isBounded
	}

	def isBounded(Member member) {
		switch (member) {
			Variable:
				if (member.dimension.isEmpty) {
					true
				} else {
					member.dimension.forall[value !== null]
				}
			Method:
				true
		}
	}

	def isOverrideOf(Member m1, Member m2) {
		if (m1 instanceof Method && m2 instanceof Method) {
			return (m1 as Method).isOverrideOf(m2 as Method)
		}

		if (m1 instanceof Variable && m2 instanceof Variable) {
			return (m1 as Variable).isOverrideOf(m2 as Variable)
		}

		return false
	}

	def isIrq(Member method) {
		method.storage?.type == StorageType::IRQ
	}

	def isNmi(Member method) {
		method.storage?.type == StorageType::NMI
	}

	def isReset(Member method) {
		method.storage?.type == StorageType::RESET
	}

	def boolean isIndexMulDivModExpression(Member member, List<Index> indices) {
		!member.isIndexImmediate(indices) && member.dimensionOf.size > 1
	}

	def isArrayReference(Member member, List<Index> indices) {
		member.dimensionOf.size > indices?.size
	}

	def NoopClass typeOf(Member member) {
		switch (member) {
			Variable: member.typeOf
			Method: member.typeOf
		}
	}

	def valueOf(Member member) {
		switch (member) {
			Variable: member.valueOf
			Method: throw new NonConstantMemberException
		}
	}

	def List<Integer> dimensionOf(Member member) {
		switch (member) {
			Variable:
				if (member.isParameter) {
					member.dimension.map[value?.valueOf as Integer ?: 1]
				} else {
					member.value.dimensionOf
				}
			Method:
				member.dimensionOf
			default:
				emptyList
		}
	}

	def Object sizeOf(Member member) {
		val size = member.typeOf.sizeOf
		val dim = member.dimensionOf.reduce[d1, d2|d1 * d2] ?: 1

		if (size instanceof Integer) {
			size * dim
		} else if (dim > 1) {
			'''(«size» * «dim»)'''
		} else {
			size
		}
	}

	def nameOf(Member member) {
		member.fullyQualifiedName.toString
	}

	def storageOf(Member member) {
		if (member.isROM || member.isNmi || member.isIrq) {
			member.storage.location?.valueOf as Integer
		} else if (member instanceof Variable) {
			if (member.storage?.type == StorageType::ZP) {
				Datas::PTR_PAGE
			} else {
				Datas::VAR_PAGE
			}
		} else {
			null
		}
	}

	def preProcessIndices(Member member, List<Index> indices, CompileContext ref, AST ast) {
		if (indices.isNotEmpty) {
			val isIndexImmediate = member.isIndexImmediate(indices)
			val isIndexNonImmediate = !isIndexImmediate

			if (isIndexImmediate) {
				indices.forEach[value.preProcess(ast)]
			} else {
				val memberSize = member.sizeOf
				val indexSize = if(member.isBounded && memberSize instanceof Integer &&
						(memberSize as Integer) <= 0xFF) 1 else 2
				val indexType = if(indexSize > 1) member.toUIntClass else member.toByteClass

				try {
					member.getIndexExpression(indices).preProcess(ast => [types.put(indexType)])
				} finally {
					ast.types.pop
				}
			}

			if (isIndexNonImmediate || ref.indirect !== null) {
				ast.append(new NodeVar => [
					varName = indices.nameOfElement(ast.container)
					ptr = true
				])
			}
		}
	}

	def prepareIndices(Member member, List<Index> indices, AllocContext ctx) {
		if (indices.isNotEmpty) {
			if (member.isIndexImmediate(indices)) {
				indices.forEach[value.prepare(ctx)]
			}
		}
	}

	def allocIndices(Member member, List<Index> indices, CompileContext ref, AllocContext ctx) {
		val chunks = newArrayList

		if (indices.isNotEmpty) {
			val indexSize = if(member.isBounded && (member.sizeOf as Integer) <= 0xFF) 1 else 2
			val isIndexImmediate = member.isIndexImmediate(indices)
			val isIndexNonImmediate = !isIndexImmediate

			if (isIndexImmediate) {
				chunks += indices.map[value.alloc(ctx)].flatten
			} else {
				val indexType = if(indexSize > 1) member.toUIntClass else member.toByteClass

				try {
					chunks += member.getIndexExpression(indices).alloc(ctx => [types.put(indexType)])
				} finally {
					ctx.types.pop
				}
			}

			if (isIndexNonImmediate || ref.indirect !== null) {
				chunks += ctx.computePtr(indices.nameOfElement(ctx.container))
			}
		}

		return chunks
	}

	def compileConstant(Member member) {
		switch (member) {
			Variable: member.compileConstant
			Method: throw new NonConstantMemberException
		}
	}
	
	def compileIndices(Member member, List<Index> indices, CompileContext ref) '''
		«IF indices.isNotEmpty»
			«val memberSize = member.sizeOf»
			«val indexSize = if (memberSize instanceof Integer) {
				if (member.isBounded && memberSize <= 0xFF) 1 else 2
			} else {
				null
			}»
			«val isIndexImmediate = member.isIndexImmediate(indices)»
			«val isIndexNonImmediate = !isIndexImmediate»
			«val index = if (isIndexImmediate) {
				var immediate = ''
				val dimension = member.dimensionOf
				
				for (i : 0 ..< indices.size) {
					if (!immediate.isNullOrEmpty) {
						immediate += ' + '
					}
					
					immediate += indices.get(i).value.valueOf.toString
					
					for (j : i + 1 ..< dimension.size) {
						immediate += ''' * «dimension.get(j)»'''
					}
				}

				'''((«immediate») * «member.typeOf.sizeOf»)'''				
			}»
			mustReloadAcc = 0
			«IF isIndexNonImmediate»
				«IF indexSize !== null || member.isUnbounded»
					«val idx = new CompileContext => [
						container = ref.container
						operation = ref.operation
						accLoaded = ref.accLoaded
						type = if (indexSize === null || indexSize > 1) ref.type.toUIntClass else ref.type.toByteClass
						register = 'A'
					]»
					«member.getIndexExpression(indices).compile(idx)»
					«IF ref.isAccLoaded && !idx.isAccLoaded»
						mustReloadAcc = 1
					«ENDIF»
				«ELSE»
					«val idx1 = new CompileContext => [
						container = ref.container
						operation = ref.operation
						accLoaded = ref.accLoaded
						type = ref.type.toByteClass
						register = 'A'
					]»
					«val idx2 = idx1.clone => [
						type = ref.type.toUIntClass
					]»
						.if «memberSize» <= $FF
					«member.getIndexExpression(indices).compile(idx1)»
					«IF ref.isAccLoaded && !idx1.isAccLoaded»
						mustReloadAcc = 1
					«ENDIF»
					«noop»
						.else
					«member.getIndexExpression(indices).compile(idx2)»
					«IF ref.isAccLoaded && !idx2.isAccLoaded»
						mustReloadAcc = 1
					«ENDIF»
					«noop»
						.endif
				«ENDIF»
			«ENDIF»
			«IF isIndexImmediate»
				«IF ref.absolute !== null»
					«ref.absolute = '''«ref.absolute» + #(«index»)'''»
				«ELSEIF ref.indirect !== null»
					«val ptr = indices.nameOfElement(ref.container)»
					«ref.pushAccIfOperating»
						CLC
						LDA «ref.indirect»
						ADC #<«index»
						STA «ptr»
						LDA «ref.indirect» + 1
						ADC #>«index»
						STA «ptr» + 1
					«ref.pullAccIfOperating»
					«ref.indirect = ptr»
				«ENDIF»
			«ELSE»
				«IF ref.absolute !== null»
					«val ptr = indices.nameOfElement(ref.container)»
						CLC
						ADC #<«ref.absolute»
						STA «ptr»
						«IF (indexSize !== null && indexSize > 1) || member.isUnbounded»
							PLA
						«ELSE»
							.if «memberSize» <= $FF
							LDA #0
							.else
							PLA
							.endif
						«ENDIF»
						ADC #>«ref.absolute»
						STA «ptr» + 1
					«ref.absolute = null»
					«ref.indirect = ptr»
				«ELSEIF ref.indirect !== null»
					«val ptr = indices.nameOfElement(ref.container)»
						CLC
						ADC «ref.indirect»
						STA «ptr»
						«IF (indexSize !== null && indexSize > 1) || member.isUnbounded»
							PLA
						«ELSE»
							.if «memberSize» <= $FF
							LDA #0
							.else
							PLA
							.endif
						«ENDIF»
						ADC «ref.indirect» + 1
						STA «ptr» + 1
					«ref.indirect = ptr»
				«ENDIF»
				«noop»
					.if mustReloadAcc == 1
					PLA
					.endif
			«ENDIF»
		«ENDIF»
	'''

	private def getIndexExpression(Member member, List<Index> indices) {
		indexExpressions.get(member, indices, [
			val typeSize = member.typeOf.sizeOf
			val dimension = member.dimensionOf

			if (typeSize instanceof Integer) {
				if (typeSize > 1) {
					val mul = NoopFactory::eINSTANCE.createMulExpression => [
						left = if (member.isBounded)
							indices.sum(dimension, 0)
						else
							indices.sum(dimension, member as Variable, 0)
						right = NoopFactory::eINSTANCE.createByteLiteral => [value = typeSize]
					]
					mul
				} else if (member.isBounded) {
					indices.sum(dimension, 0)
				} else {
					indices.sum(dimension, member as Variable, 0)
				}
			} else {
				val mul = NoopFactory::eINSTANCE.createMulExpression => [
					left = if (member.isBounded)
						indices.sum(dimension, 0)
					else
						indices.sum(dimension, member as Variable, 0)
					right = NoopFactory::eINSTANCE.createStringLiteral => [value = typeSize.toString]
				]
				mul
			}
		])
	}

	private def Expression mult(List<Index> indices, List<Integer> dimension, Variable parameter, int i, int j) {
		if (j < dimension.size) {
			NoopFactory::eINSTANCE.createMulExpression => [
				left = NoopFactory::eINSTANCE.createMemberSelect => [
					receiver = NoopFactory::eINSTANCE.createMemberRef => [
						member = parameter

						for (x : 0 ..< j) {
							it.indices.add(NoopFactory::eINSTANCE.createIndex => [
								value = NoopFactory::eINSTANCE.createByteLiteral => [value = 0]
							])
						}
					]
					member = parameter.type.allMethodsTopDown.findFirst[arrayLength]
				]
				right = indices.mult(dimension, parameter, i, j + 1)
			]
		} else {
			indices.get(i).value.copy
		}
	}

	private def Expression sum(List<Index> indices, List<Integer> dimension, Variable parameter, int i) {
		if (i + 1 < indices.size) {
			NoopFactory::eINSTANCE.createAddExpression => [
				left = indices.mult(dimension, parameter, i, i + 1)
				right = indices.sum(dimension, parameter, i + 1)
			]
		} else {
			indices.mult(dimension, parameter, i, i + 1)
		}
	}

	private def Expression mult(List<Index> indices, List<Integer> dimension, int i, int j) {
		if (j < dimension.size) {
			NoopFactory::eINSTANCE.createMulExpression => [
				left = NoopFactory::eINSTANCE.createByteLiteral => [value = dimension.get(j)]
				right = indices.mult(dimension, i, j + 1)
			]
		} else {
			indices.get(i).value.copy
		}
	}

	private def Expression sum(List<Index> indices, List<Integer> dimension, int i) {
		if (i + 1 < indices.size) {
			NoopFactory::eINSTANCE.createAddExpression => [
				left = indices.mult(dimension, i, i + 1)
				right = indices.sum(dimension, i + 1)
			]
		} else {
			indices.mult(dimension, i, i + 1)
		}
	}

	private def isIndexImmediate(Member member, List<Index> indices) {
		(member.isBounded || member.dimensionOf.size == 1) && indices.forall[value?.isConstant]
	}

	private def void noop() {
	}

}
