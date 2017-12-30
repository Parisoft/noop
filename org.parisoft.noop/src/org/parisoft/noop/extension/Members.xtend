package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.HashSet
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.CompileContext.Mode
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.Variable

import static extension java.lang.Character.*
import static extension java.lang.Integer.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.StorageType

public class Members {

	public static val STATIC_PREFIX = '$'
	public static val PRIVATE_PREFIX = '_'
	public static val TEMP_VAR_NAME1 = 'rash'
	public static val TEMP_VAR_NAME2 = 'zitz'
	public static val TEMP_VAR_NAME3 = 'pimple'
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
	@Inject extension Values
	@Inject extension Classes
	@Inject extension Operations
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Expressions
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	static val running = ThreadLocal.withInitial[new HashSet<Member>]
	static val allocating = ThreadLocal.withInitial[new HashSet<Member>]
	static val preparing = ThreadLocal.withInitial[new HashSet<Member>]

	def getOverriders(Method method) {
		method.containerClass.subClasses.map[declaredMethods.filter[it.isOverrideOf(method)]].filterNull.flatten
	}
	
	def getOverriders(Variable variable) {
		variable.containerClass.subClasses.map[declaredFields.filter[it.isOverrideOf(variable)]].filterNull.flatten
	}
	
	def getOverriddenVariablesOnRecursion(Method method, Expression expression) {
		val statement = method.body.statements.findFirst[
			it == expression || eAllContentsAsList.contains(expression)
		]
		
		val localVars = method.params + method.body.statements.takeWhile[it != statement].map[
			newArrayList(it) + eAllContentsAsList
		].flatten.filter(Variable)
		
		return method.body.statements.dropWhile[it != statement].drop(1).map[
			newArrayList(it) + eAllContentsAsList
		].flatten.filter(MemberRef).map[member].filter(Variable).filter[variable|
			localVars.exists[it == variable]
		].toSet
	}

	def isAccessibleFrom(Member member, EObject context) {
		if (context instanceof MemberSelect) {
			val receiverClass = context.receiver.typeOf
			receiverClass.isSubclassOf(member.containerClass) && (member.isPublic || context.containerClass.isSubclassOf(receiverClass))
		} else {
			context.containerClass.isSubclassOf(member.containerClass)
		} 
	}

	def isStatic(Member member) {
		if (member === null || member.name === null) {
			false
		} else {
			member.name.startsWith(STATIC_PREFIX) || (member.name.startsWith(PRIVATE_PREFIX) &&  member.name.charAt(1) === STATIC_PREFIX.charAt(0))
		}
	}

	def isNonStatic(Member member) {
		!member.isStatic
	}
	
	def isPrivate(Member member) {
		if (member === null || member.name === null) {
			false
		} else {
			member.name.startsWith(PRIVATE_PREFIX) || (member.name.startsWith(STATIC_PREFIX) &&  member.name.charAt(1) === PRIVATE_PREFIX.charAt(0))
		}
	}
	
	def isPublic(Member member) {
		!member.isPrivate
	}

	def isParameter(Variable variable) {
		variable.eContainer instanceof Method
	}

	def isField(Variable variable) {
		variable.eContainer instanceof NoopClass
	}
	
	def isNonField(Variable variable) {
		!variable.isField
	}

	def isNonParameter(Variable variable) {
		!variable.isParameter
	}

	def isConstant(Variable variable) {
		variable.isStatic && variable.name.chars.skip(1).allMatch[val c = it as char
							c.isUpperCase || c.isDigit || c === PRIVATE_PREFIX.charAt(0) || c === STATIC_PREFIX.charAt(0)
						]
	}

	def isNonConstant(Variable variable) {
		!variable.isConstant
	}

	def isROM(Member member) {
		switch(member.storage?.type) {
			case CHRROM: true
			case PRGROM: true
			default: false	
		}
	}

	def isNonROM(Variable variable) {
		!variable.isROM
	}
	
	def isDMC(Variable variable) {
		val expr = variable.value
		
		if (expr instanceof StringLiteral) {
			expr.isDmcFile
		} else {
			false
		}
	}
	
	def isNonDMC(Variable variable) {
		!variable.isDMC
	}
	
	def isUnbounded(Member member) {
		!member.isBounded
	}
	
	def isBounded(Member member) {
		switch (member) {
			Variable: member.dimension?.forall[value !== null]
			Method: true 
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

	def isOverrideOf(Method m1, Method m2) {
		if (m1.name == m2.name 
			&& m1.params.size == m2.params.size 
			&& m1.containerClass.isSubclassOf(m2.containerClass)) {
			for (i : 0 ..< m1.params.size) {
				val p1 = m1.params.get(i)
				val p2 = m2.params.get(i)
				
				if (p1.typeOf != p2.typeOf) {
					return false
				}
				
				if (p1.dimensionOf.size != p2.dimensionOf.size) {
					return false
				}
			}

			return true
		}
		
		return false
	}

	def isOverrideOf(Variable v1, Variable v2) {
		return v1.name == v2.name
	}

	def isIrq(Method method) {
		method.containerClass.isGame && method.name == '''«STATIC_PREFIX»irq'''.toString && method.params.isEmpty
	}

	def isNmi(Method method) {
		method.containerClass.isGame && method.name == '''«STATIC_PREFIX»nmi'''.toString && method.params.isEmpty
	}
	
	def isReset(Method method) {
		method.containerClass.isGame && method.name == '''«STATIC_PREFIX»reset'''.toString && method.params.isEmpty
	}
	
	def isObjectSize(Method method) {
		method.containerClass.isObject && method.name == 'size' && method.params.isEmpty
	}
	
	def isNative(Method method) {
		val methodContainer = method.containerClass.fullyQualifiedName.toString
		return (methodContainer == TypeSystem.LIB_OBJECT || methodContainer == TypeSystem.LIB_PRIMITIVE) 
		&& (method.name == METHOD_ARRAY_LENGTH /*put other native methods here separated by || */)
	}
	
	def isNonNative(Method method) {
		!method.isNative
	}
	
	def isNativeArray(Method method) {
		method.isNative && (method.name == METHOD_ARRAY_LENGTH /*put other array methods here separated by || */)
	}
	
	def isNonNativeArray(Method method) {
		!method.isNativeArray
	}
	
	def isArrayLength(Method method) {
		method.isNativeArray && method.name == METHOD_ARRAY_LENGTH
	}
	
	def isNonArrayLength(Method method) {
		!method.isArrayLength
	}
	
	def boolean isInvokedOn(Method method, Statement statement) {
		statement !== null &&
		statement.eAllContents.filter(MemberRef).map[member].filter(Method).exists[
			it == method || body.statements.filter[it != statement].exists[method.isInvokedOn(it)]
		] ||
		statement.eAllContents.filter(MemberSelect).map[member].filter(Method).exists[
			it == method || body.statements.filter[it != statement].exists[method.isInvokedOn(it)]
		]
	}
	
	def isArrayReference(Member member, List<Index> indexes) {
		member.dimensionOf.size > indexes.size
	}

	def typeOf(Member member) {
		switch (member) {
			Variable: member.typeOf
			Method: member.typeOf
		}
	}

	def typeOf(Variable variable) {
		if (running.get.add(variable)) {
			try {
				if (variable.type !== null) {
					variable.type
				} else if (variable.value instanceof MemberRef && (variable.value as MemberRef).member === variable) {
					TypeSystem::TYPE_VOID
				} else {
					variable.value.typeOf
				}
			} finally {
				running.get.remove(variable)
			}
		}
	}

	def typeOf(Method method) {
		if (running.get.add(method)) {
			try {
				method.body.getAllContentsOfType(ReturnStatement).map[value.typeOf].filterNull.toSet.merge
			} finally {
				running.get.remove(method)
			}
		}
	}

	def valueOf(Member member) {
		switch (member) {
			Variable: member.valueOf
			Method: throw new NonConstantMemberException
		}
	}

	def valueOf(Variable variable) {
		if (variable.isNonConstant && variable.containerClass.isNonINESHeader) {
			throw new NonConstantMemberException
		}
		
		if (running.get.add(variable)) {
			try {
				return variable.value.valueOf
			} finally {
				running.get.remove(variable)
			}
		}
	}

	def lenOfArrayReference(Member member, List<Index> indexes) {
		member.dimensionOf.drop(indexes.size).reduce[d1, d2| d1 * d2]
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
		}
	}
	
	def List<Integer> dimensionOf(Method method) {
		if (running.get.add(method)) {
			try {
				method.body.getAllContentsOfType(ReturnStatement).head?.dimensionOf ?: emptyList
			} finally {
				running.get.remove(method)
			}
		}
	}

	def sizeOf(Member member) {
		member.typeOf.sizeOf * (member.dimensionOf.reduce [ d1, d2 |
			d1 * d2
		] ?: 1)
	}

	def nameOf(Member member) {
		switch (member) {
			Variable: member.nameOf
			Method: member.nameOf
		}
	}

	def nameOf(Variable variable) {
		variable.nameOf(variable.getContainerOfType(Method)?.nameOf)
	}

	def String nameOf(Variable variable, String containerName) {
		if (variable.isStatic) {
			variable.nameOfStatic
		} else if (variable.getContainerOfType(Method) !== null) {
			'''«containerName»«variable.fullyQualifiedName.toString.substring(containerName.indexOf('@'))»@«variable.hashCode.toHexString»'''
		} else {
			'''«containerName».«variable.name»@«variable.hashCode.toHexString»'''
		}
	}

	def nameOfStatic(Variable variable) {
		'''«variable.containerClass.name».«variable.name»'''.toString
	}

	def nameOfConstant(Variable variable) {
		variable.fullyQualifiedName.toString
	}

	def nameOfOffset(Variable variable) {
		variable.fullyQualifiedName.toString
	}
	
	def nameOfLen(Variable variable, String container, int i) {
		'''«variable.nameOf(container)».len«i»'''.toString
	}
	
	def nameOfLen(Variable variable, int i) {
		variable.nameOfLen(variable.getContainerOfType(Method).nameOf, i)
	}

	def nameOf(Method method) {
		'''«method.fullyQualifiedName.toString»@«method.hashCode.toHexString»'''.toString
	}

	def nameOfReceiver(Method method) {
		'''«method.nameOf».rcv'''.toString
	}
	
	def nameOfReturn(Method method) {
		'''«method.nameOf».ret'''.toString
	}
	
	def storageOf(Member member) {
		if (member.isROM) {
			member.storage.location?.valueOf as Integer ?: 0 // FIXME change to the current mapper's default bank
		} else if (member instanceof Variable) {
			if (member.storage?.type == StorageType::ZP) {
				Datas::PTR_PAGE
			} else {
				Datas::VAR_PAGE
			}
		} else {
			0
		}
	}

	def push(Variable variable) '''
		«IF variable.isParameter && (variable.type.isNonPrimitive || variable.dimension.isNotEmpty)»
			«val pointer = variable.nameOf»
				LDA «pointer» + 1
				PHA
				LDA «pointer» + 0
				PHA
			«FOR i : 0 ..< variable.dimension.size»
				«val len = variable.nameOfLen(i)»
					LDA «len» + 1
					PHA
					LDA «len» + 0
					PHA
			«ENDFOR»
		«ELSE»
			«val local = variable.nameOf»
			«val size = variable.sizeOf»
			«IF size < Datas::loopThreshold»
				«FOR i : size >.. 0»
					«noop»
						LDA «local»«IF i > 0» + «i»«ENDIF»
						PHA
				«ENDFOR»
			«ELSE»
				«val loop = 'pushLoop'»
					LDX #«size - 1»
				-«loop»:
					LDA «local», X
					PHA
					DEX
					BNE -«loop»
			«ENDIF»
		«ENDIF»
	'''
	
	def pull(Variable variable) '''
		«IF variable.isParameter && (variable.type.isNonPrimitive || variable.dimension.isNotEmpty)»
			«val pointer = variable.nameOf»
				PLA
				STA «pointer» + 0
				PLA
				STA «pointer» + 1
			«FOR i : 0 ..< variable.dimension.size»
				«val len = variable.nameOfLen(i)»
					PLA
					STA «len» + 0
					PLA
					STA «len» + 1
			«ENDFOR»
		«ELSE»
			«val local = variable.nameOf»
			«val size = variable.sizeOf»
			«IF size < Datas::loopThreshold»
				«FOR i : 0 ..< size»
					«noop»
						PLA
						STA «local»«IF i > 0» + «i»«ENDIF»
				«ENDFOR»
			«ELSE»
				«val loop = 'pushLoop'»
					LDX #0
				-«loop»:
					PLA
					STA «local», X
					INX
					CMP #«size»
					BNE -«loop»
			«ENDIF»
		«ENDIF»
	'''

	def prepare(Method method, AllocContext ctx) {
		if (preparing.get.add(method)) {
			try {
				method.body.statements.forEach[prepare(ctx)]
			} finally {
				preparing.get.remove(method)		
			}
		}
	}
	
	def prepareReference(Variable variable, Expression receiver, List<Index> indexes, AllocContext ctx) {
		receiver.prepare(ctx)
		variable.prepare(ctx)
		variable.prepareIndexes(indexes, ctx)
	}
	
	def prepareReference(Variable variable, List<Index> indexes, AllocContext ctx) {
		variable.prepare(ctx)
		variable.prepareIndexes(indexes, ctx)
	}
	
	def prepareInvocation(Method method, Expression receiver, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		if (method.isNative) {
			return
		}
		
		receiver.prepare(ctx)
		
		args.forEach [ arg, i |
			if (arg.containsMulDivMod) {
				try {
					arg.prepare(ctx => [types.put(method.params.get(i).type)])
				} finally {
					ctx.types.pop
				}
			} else {
				arg.prepare(ctx)
			}
		]
		
		method.prepare(ctx)
		method.overriders.forEach[prepare(ctx)]
		method.prepareIndexes(indexes, ctx)
	}
	
	def prepareInvocation(Method method, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		if (method.isNative) {
			return
		}
		
		args.forEach [ arg, i |
			if (arg.containsMulDivMod) {
				try {
					arg.prepare(ctx => [types.put(method.params.get(i).type)])
				} finally {
					ctx.types.pop
				}
			} else {
				arg.prepare(ctx)
			}
		]
		
		method.prepare(ctx)
		method.prepareIndexes(indexes, ctx)
	}
	
	private def prepareIndexes(Member member, List<Index> indexes, AllocContext ctx) {
		if (indexes.isNotEmpty) {
			if (member.isIndexImmediate(indexes)) {
				indexes.forEach[value.prepare(ctx)]
			} else {
				val indexType = if (member.isBounded && member.sizeOf <= 0xFF) member.toByteClass else member.toUIntClass
				
				try {
					member.getIndexExpression(indexes).prepare(ctx => [types.put(indexType)])				
				} finally {
					ctx.types.pop
				}
			}
		}
	}

	def alloc(Method method, AllocContext ctx) {
		if (allocating.get.add(method)) {
			try {
				val snapshot = ctx.snapshot
				val methodName = method.nameOf

				ctx.container = methodName

				val receiver = if (method.isNonStatic) {
						ctx.computePtr(method.nameOfReceiver)
					} else {
						emptyList
					}

				val chunks = (receiver + method.params.map[alloc(ctx)].flatten).toList
				chunks += method.body.statements.map[alloc(ctx)].flatten.toList
				chunks.disoverlap(methodName)

				ctx.restoreTo(snapshot)
				ctx.methods.put(method.nameOf, method)

				return chunks
			} finally {
				allocating.get.remove(method)
			}
		} else {
			newArrayList
		}
	}
	
	def allocReference(Variable variable, Expression receiver, List<Index> indexes, AllocContext ctx) {
		val chunks = receiver.alloc(ctx)
		
		if (variable.overriders.isNotEmpty && receiver.isNonThisNorSuper) {
			chunks += ctx.computeTmp(receiver.nameOfTmpVar(ctx.container), 2)
		}
		
		val rcv = new CompileContext => [
			container = ctx.container
			type = receiver.typeOf
			mode = Mode::REFERENCE
		]
		
		receiver.compile(rcv)
		
		val ref = rcv => [
			if (absolute !== null) {
				absolute = '''«rcv.absolute» + #«variable.nameOfOffset»'''
			} else if (indirect !== null) {
				index = '''«IF rcv.index !== null»«rcv.index» + «ENDIF»#«variable.nameOfOffset»'''
			}
		]
		
		chunks += variable.allocIndexes(indexes, ref, ctx)
		
		return chunks
	}
	
	def allocConstantReference(Variable variable, AllocContext ctx) {
		variable.alloc(ctx)
	}
	
	def allocStaticReference(Variable variable, List<Index> indexes, AllocContext ctx) {
		val ref = new CompileContext => [absolute = variable.nameOfStatic]
		variable.allocIndexes(indexes, ref, ctx) + variable.alloc(ctx)
	}
	
	def allocPointerReference(Variable variable, String receiver, List<Index> indexes, AllocContext ctx) {
		val ref = new CompileContext => [
			indirect = receiver
			index = if (variable.isNonParameter) '''#«variable.nameOfOffset»'''
		]
		variable.allocIndexes(indexes, ref, ctx)
	}
	
	def allocLocalReference(Variable variable, List<Index> indexes, AllocContext ctx) {
		val ref = new CompileContext => [absolute = variable.nameOf]
		variable.allocIndexes(indexes, ref, ctx)
	}
	
	def allocInvocation(Method method, Expression receiver, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		val chunks = newArrayList
		
		if (method.isNative) {
			return chunks
		}
		
		val methodChunks = method.alloc(ctx)
		
		if (method.overriders.isNotEmpty && receiver.isNonThisNorSuper) {
			methodChunks += method.overriders.map[alloc(ctx)].flatten
		}
		
		chunks += receiver.alloc(ctx)

		args.forEach [ arg, i |
			if (arg.containsMulDivMod) {
				try {
					chunks += arg.alloc(ctx => [types.put(method.params.get(i).type)])
				} finally {
					ctx.types.pop
				}
			} else {
				chunks += arg.alloc(ctx)
			}
		]

		chunks += method.allocIndexes(indexes, new CompileContext => [indirect = method.nameOfReturn], ctx)
		chunks += methodChunks

		return chunks
	}
	
	def allocInvocation(Method method, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		val chunks = newArrayList
		
		if (method.isNative) {
			return chunks
		}
		
		val methodChunks = method.alloc(ctx)
		
		args.forEach [ arg, i |
			if (arg.containsMulDivMod) {
				try {
					chunks += arg.alloc(ctx => [types.put(method.params.get(i).type)])
				} finally {
					ctx.types.pop
				}
			} else {
				chunks += arg.alloc(ctx)
			}
		]

		chunks += method.allocIndexes(indexes, new CompileContext => [indirect = method.nameOfReturn], ctx)
		chunks += methodChunks

		return chunks
	}
	
	private def allocIndexes(Member member, List<Index> indexes, CompileContext ref, AllocContext ctx) {
		val chunks = newArrayList
		
		if (indexes.isNotEmpty) {
			val indexSize = if (member.isBounded && member.sizeOf <= 0xFF) 1 else 2
			val isIndexImmediate = member.isIndexImmediate(indexes)
			val isIndexNonImmediate = !isIndexImmediate 
			
			if (isIndexImmediate) {
				chunks += indexes.map[value.alloc(ctx)].flatten
			} else {
				val indexType = if (indexSize > 1) member.toUIntClass else member.toByteClass
				
				try {
					chunks += member.getIndexExpression(indexes).alloc(ctx => [types.put(indexType)])				
				} finally {
					ctx.types.pop
				}
			}
			
			if (isIndexNonImmediate || ref.indirect !== null) {
				chunks += ctx.computeTmp(indexes.nameOfElement(ctx.container), 2)
			}
		}
		
		return chunks
	}
	
	def compile(Method method, CompileContext ctx) '''
		«IF method.isNonArrayLength»
			«method.nameOf»:
			«IF method.isReset»
				;;;;;;;;;; Initial setup begin
				SEI          ; disable IRQs
				CLD          ; disable decimal mode
				LDX #$40
				STX $4017    ; disable APU frame IRQ
				LDX #$FF
				TXS          ; Set up stack
				INX          ; now X = 0
				STX $2000    ; disable NMI
				STX $2001    ; disable rendering
				STX $4010    ; disable DMC IRQs
			
			-waitVBlank1:
				BIT $2002
				BPL -waitVBlank1
			
			-clrMem:
				LDA #$00
				STA $0000, X
				STA $0100, X
				STA $0300, X
				STA $0400, X
				STA $0500, X
				STA $0600, X
				STA $0700, X
				LDA #$FE
				STA $0200, X
				INX
				BNE -clrMem:

				; Instantiate all static variables
			«val resetMethod = method.nameOf»
			«FOR staticVar : ctx.allocation.statics.values»
				«staticVar.compile(new CompileContext => [container = resetMethod])»
			«ENDFOR»
			
			-waitVBlank2
				BIT $2002
				BPL -waitVBlank2
				;;;;;;;;;; Initial setup end
			«FOR statement : method.body.statements»
				«statement.compile(new CompileContext => [container = method.nameOf])»
			«ENDFOR»
				RTS
			«ELSEIF method.isNmi»
				;;;;;;;;;; NMI initialization begin
				PHA
				TXA
				PHA
				TYA
				PHA
			
				LDA #$00
				STA $2003       ; set the low byte (00) of the RAM address
				LDA #$02
				STA $4014       ; set the high byte (02) of the RAM address, start the transfer
				;;;;;;;;;; NMI initialization end
				;;;;;;;;;; Effective code begin
			«FOR statement : method.body.statements»
				«statement.compile(new CompileContext => [container = method.nameOf])»
			«ENDFOR»
				;;;;;;;;;; Effective code end
				;;;;;;;;;; NMI finalization begin
				PLA
				TAY
				PLA
				TAX
				PLA
				;;;;;;;;;; NMI finalization end
				RTI
			«ELSEIF method.isIrq»
				«FOR statement : method.body.statements»
					«statement.compile(new CompileContext => [container = method.nameOf])»
				«ENDFOR»
					RTI
			«ELSE»
				«FOR statement : method.body.statements»
					«statement.compile(new CompileContext => [container = method.nameOf])»
				«ENDFOR»
					RTS
			«ENDIF»
		«ENDIF»
	'''
		
	def compileConstant(Member member) {
		switch (member) {
			Variable: member.compileConstant
			Method: throw new NonConstantMemberException
		}
	}

	def compileConstant(Variable variable) {
		if (variable.isNonConstant) {
			throw new NonConstantMemberException
		}
		
		if (running.get.add(variable)) {
			try {
				return variable.nameOfConstant
			} finally {
				running.get.remove(variable)
			}
		}
	}
		
	def compileReference(Variable variable, Expression receiver, List<Index> indexes, CompileContext ctx) '''
		«val overriders = if (receiver.isNonThisNorSuper) variable.overriders else emptyList»
		«val rcv = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.isAccLoaded
			type = receiver.typeOf
		]»
		«IF overriders.isEmpty»
			«receiver.compile(rcv => [mode = Mode::REFERENCE])»
			«IF rcv.absolute !== null»
				«variable.compileAbsoluteReference(rcv, indexes, ctx)»
			«ELSEIF rcv.indirect !== null»
				«variable.compileIndirectReference(rcv, indexes, ctx)»
			«ENDIF»
		«ELSE»
			«receiver.compile(rcv => [
				indirect = receiver.nameOfTmpVar(ctx.container)
				mode = Mode::POINT
			])»
			«ctx.pushAccIfOperating»
				LDY #$00
				LDA («rcv.indirect»), Y
			«val finish = '''reference.end'''»
			«val pullAcc = ctx.pullAccIfOperating»
			«FOR overrider : overriders»
				«noop»
				+	CMP #«overrider.containerClass.nameOf»
					BNE +
				«pullAcc»
				«overrider.compileIndirectReference(rcv, indexes, ctx)»
					JMP +«finish»
			«ENDFOR»
			«IF pullAcc.length > 0»
				+«pullAcc»
				«variable.compileIndirectReference(rcv, indexes, ctx)»
			«ELSE»
				+«variable.compileIndirectReference(rcv, indexes, ctx)»
			«ENDIF»
			+«finish»:
		«ENDIF»
	'''
	
	private def compileAbsoluteReference(Variable variable, CompileContext receiver, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = receiver.container
			operation = receiver.operation
			accLoaded = receiver.accLoaded
			absolute = '''«receiver.absolute» + #«variable.nameOfOffset»'''
			index = receiver.index
			type = variable.typeOf
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''
	
	private def compileIndirectReference(Variable variable, CompileContext receiver, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = receiver.container
			operation = receiver.operation
			accLoaded = receiver.accLoaded
			indirect = receiver.indirect
			type = variable.typeOf
		]»
		«IF receiver.index.isAbsolute»
			«ref.index = receiver.index»
			«ctx.pushAccIfOperating»
				CLC
				LDA «ref.index»
				ADC #«variable.nameOfOffset»
				STA «ref.index»
			«ctx.pullAccIfOperating»
		«ELSEIF receiver.index !== null»
			«ref.index = '''«receiver.index» + #«variable.nameOfOffset»'''»
		«ELSE»
			«ref.index = '''#«variable.nameOfOffset»'''»
		«ENDIF»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compilePointerReference(Variable variable, String receiver, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			type = variable.typeOf
			indirect = receiver
			index = if (variable.isNonParameter) '''#«variable.nameOfOffset»'''
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compileStaticReference(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			type = variable.typeOf
			absolute = variable.nameOfStatic
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''
	
	def compileLocalReference(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			type = variable.typeOf
			absolute = variable.nameOf
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''
	
	def compileConstantReference(Variable variable, CompileContext ctx) '''
		«val const = new CompileContext => [
			container = ctx.container
			type = variable.typeOf
			immediate = variable.nameOfConstant
		]»
		«IF ctx.mode === Mode::OPERATE»
			«ctx.operateOn(const)»
		«ELSEIF ctx.mode === Mode::COPY»
			«const.copyTo(ctx)»
		«ENDIF»
	'''

	def compileInvocation(Method method, Expression receiver, List<Expression> args, List<Index> indexes, CompileContext ctx) '''
		«IF method.isNative»
			«method.compileNativeInvocation(receiver, args, ctx)»
		«ELSE»
			«val overriders = if (receiver.isNonThisNorSuper) method.overriders else emptyList»
			«receiver.compile(new CompileContext => [
				container = ctx.container
				operation = ctx.operation
				accLoaded = ctx.accLoaded
				indirect = method.nameOfReceiver
				type = receiver.typeOf
				mode = Mode::POINT
			])»
			«IF overriders.isEmpty»
				«method.compileInvocation(args, indexes, ctx)»
			«ELSE»
				«ctx.pushAccIfOperating»
					LDY #$00
					LDA («method.nameOfReceiver»), Y
				«val invocationEnd = '''invocation.end'''»
				«FOR overrider : overriders»
					«noop»
					+	CMP #«overrider.containerClass.nameOf»
						BEQ ++
						JMP +
					«val falseReceiver = new CompileContext => [
						operation = ctx.operation
						indirect = method.nameOfReceiver
					]»
					«val realReceiver = new CompileContext => [
						operation = ctx.operation
						indirect = overrider.nameOfReceiver
					]»
					++«realReceiver.pointTo(falseReceiver)»
					«overrider.compileInvocation(args, indexes, ctx)»
						JMP +«invocationEnd»
				«ENDFOR»
				+«method.compileInvocation(args, indexes, ctx)»
				+«invocationEnd»:
			«ENDIF»
		«ENDIF»
	'''

	def compileInvocation(Method method, List<Expression> args, List<Index> indexes, CompileContext ctx) '''
		«IF method.isNonNative»
			«ctx.pushAccIfOperating»
			«ctx.pushRecusiveVars»
			«val methodName = method.nameOf»
			«FOR i : 0..< args.size»
				«val param = method.params.get(i)»
				«val arg = args.get(i)»
				«arg.compile(new CompileContext => [
					container = ctx.container
					type = param.type
					
					if (param.type.isPrimitive && param.dimensionOf.isEmpty) {
						absolute = param.nameOf
						mode = Mode::COPY
					} else {
						indirect = param.nameOf
						mode = Mode::POINT
					}
				])»
				«IF param.isUnbounded»
					«val dimension = arg.dimensionOf»
					«FOR dim : 0..< dimension.size»
						«val len = dimension.get(dim).toHex»
							LDA #<«len»
							STA «param.nameOfLen(methodName, dim)»
							LDA #>«len»
							STA «param.nameOfLen(methodName, dim)» + 1
					«ENDFOR»
				«ENDIF»
			«ENDFOR»
			«noop»
				JSR «method.nameOf»
			«ctx.pullRecursiveVars»
			«ctx.pullAccIfOperating»
			«IF method.typeOf.isNonVoid»
				«val ret = new CompileContext => [
					container = ctx.container
					type = method.typeOf
					
					if (method.typeOf.isPrimitive && method.dimensionOf.isEmpty) {
						absolute = method.nameOfReturn
					} else {
						indirect = method.nameOfReturn
					}
				]»
				«method.compileIndexes(indexes, ret)»
				«IF ctx.mode === Mode::COPY && method.isArrayReference(indexes)»
					«ret.copyArrayTo(ctx, method.lenOfArrayReference(indexes))»
				«ELSE»
					«ret.resolveTo(ctx)»
				«ENDIF»
			«ENDIF»
		«ENDIF»
	'''
	
	private def compileNativeInvocation(Method method, Expression receiver, List<Expression> args, CompileContext ctx) '''
		«IF method.name == METHOD_ARRAY_LENGTH»
			«IF receiver instanceof MemberRef && (receiver as MemberRef).member instanceof Variable && ((receiver as MemberRef).member as Variable).isUnbounded»
				«val dim = (receiver as MemberRef).indexes.size»
				«val len = new CompileContext => [
					container = ctx.container
					type = ctx.type.toIntClass
					absolute = ((receiver as MemberRef).member as Variable).nameOfLen(dim)
				]»
				«len.resolveTo(ctx)»
			«ELSE»
				«val len = new CompileContext => [
					container = ctx.container
					type = ctx.type.toIntClass
					immediate = receiver.dimensionOf.head.toString
				]»
				«len.resolveTo(ctx)»
			«ENDIF»
		«ENDIF»
	'''
	
	private def compileIndexes(Member member, List<Index> indexes, CompileContext ref)'''
		«IF indexes.isNotEmpty»
			«val indexSize = if (member.isBounded && member.sizeOf <= 0xFF) 1 else 2»
			«val isIndexImmediate = member.isIndexImmediate(indexes)»
			«val isIndexNonImmediate = !isIndexImmediate»
			«val index = if (isIndexImmediate) {
				var immediate = ''
				val dimension = member.dimensionOf
				
				for (i : 0 ..< indexes.size) {
					if (!immediate.isNullOrEmpty) {
						immediate += ' + '
					}
					
					immediate += indexes.get(i).value.valueOf.toString
					
					for (j : i + 1 ..< indexes.size) {
						immediate += '''*«dimension.get(j)»'''
					}
				}

				'''(«immediate») * «member.typeOf.sizeOf»'''				
			}»
			«IF isIndexNonImmediate»
				«member.getIndexExpression(indexes).compile(new CompileContext => [
					container = ref.container
					operation = ref.operation
					accLoaded = ref.accLoaded
					type = if (indexSize > 1) ref.type.toUIntClass else ref.type.toByteClass
					register = 'A'
				])»
			«ENDIF»
			«IF isIndexImmediate»
				«IF ref.absolute !== null»
					«ref.absolute = '''«ref.absolute» + #(«index»)'''»
				«ELSEIF ref.indirect !== null»
					«val ptr = indexes.nameOfElement(ref.container)»
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
					«val ptr = indexes.nameOfElement(ref.container)»
					«ref.pushAccIfOperating»
						CLC
						ADC #<«ref.absolute»
						STA «ptr»
						«IF indexSize > 1»
							PLA
						«ELSE»
							LDA #0
						«ENDIF»
						ADC #>«ref.absolute»
						STA «ptr» + 1
					«ref.pullAccIfOperating»
					«ref.absolute = null»
					«ref.indirect = ptr»
				«ELSEIF ref.indirect !== null»
					«val ptr = indexes.nameOfElement(ref.container)»
					«ref.pushAccIfOperating»
						CLC
						ADC «ref.indirect»
						STA «ptr»
						«IF indexSize > 1»
							PLA
						«ELSE»
							LDA #0
						«ENDIF»
						ADC «ref.indirect» + 1
						STA «ptr» + 1
					«ref.pullAccIfOperating»
					«ref.indirect = ptr»
				«ENDIF»
			«ENDIF»
		«ENDIF»
	'''
	
	private def getIndexExpression(Member member, List<Index> indexes) {
		val memberTypeSize = member.typeOf.sizeOf
		
		if (memberTypeSize > 1) {
			NoopFactory::eINSTANCE.createMulExpression => [
				left = if (member.isBounded) indexes.sum(member.dimensionOf, 0) else indexes.sum(member as Variable, 0)
				right = NoopFactory::eINSTANCE.createByteLiteral => [value = memberTypeSize]
			]
		} else if (member.isBounded) {
			indexes.sum(member.dimensionOf, 0)
		} else {
			indexes.sum(member as Variable, 0)
		}
	}
	
	private def Expression mult(List<Index> indexes, Variable parameter, int i, int j) {
		if (j < indexes.size) {
			NoopFactory::eINSTANCE.createMulExpression => [
				left = NoopFactory::eINSTANCE.createMemberSelect => [
					receiver = NoopFactory::eINSTANCE.createMemberRef => [
						member = parameter
						
						for (x : 0 ..< j) {
							it.indexes.add(NoopFactory::eINSTANCE.createIndex => [
								value = NoopFactory::eINSTANCE.createByteLiteral => [value = 0]
							])
						}
					]
					member = parameter.type.allMethodsTopDown.findFirst[arrayLength]
				]
				right = indexes.mult(parameter, i, j + 1)
			]
		} else {
			indexes.get(i).value.copy
		}
	}
	
	private def Expression sum(List<Index> indexes, Variable parameter, int i) {
		if (i + 1 < indexes.size) {
			NoopFactory::eINSTANCE.createAddExpression => [
				left = indexes.mult(parameter, i, i + 1)
				right = indexes.sum(parameter, i + 1)
			]
		} else {
			indexes.mult(parameter, i, i + 1)
		}
	}
	
	private def Expression mult(List<Index> indexes, List<Integer> dimension, int i, int j) {
		if (j < indexes.size) {
			NoopFactory::eINSTANCE.createMulExpression => [
				left = NoopFactory::eINSTANCE.createByteLiteral => [value = dimension.get(j)]
				right = indexes.mult(dimension, i, j + 1)
			]
		} else {
			indexes.get(i).value.copy
		}
	}
	
	private def Expression sum(List<Index> indexes, List<Integer> dimension, int i) {
		if (i + 1 < indexes.size) {
			NoopFactory::eINSTANCE.createAddExpression => [
				left = indexes.mult(dimension, i, i + 1)
				right = indexes.sum(dimension, i + 1)
			]
		} else {
			indexes.mult(dimension, i, i + 1)
		}
	}
	
	private def isIndexImmediate(Member member, List<Index> indexes) {
		(member.isBounded || indexes.size == 1) && indexes.forall[value.isConstant]
	}
	
	private def isAbsolute(String index) {
		index !== null && index.split('\\+').exists[!trim.startsWith('#')]
	}
	
	private def void noop() {
	}
	
}
