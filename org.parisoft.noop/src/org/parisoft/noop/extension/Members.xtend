package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.HashSet
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.CompileContext.Mode
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension java.lang.Character.*
import static extension java.lang.Integer.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.noop.Super
import org.parisoft.noop.noop.This

public class Members {

	public static val STATIC_PREFIX = '$'
	public static val PRIVATE_PREFIX = '_'
	public static val TEMP_VAR_NAME1 = 'zitz'
	public static val TEMP_VAR_NAME2 = 'pimple'
	public static val TEMP_VAR_NAME3 = 'rash'
	public static val FT_DPCM_OFF = 'FT_DPCM_OFF'
	public static val FT_DPCM_PTR = 'FT_DPCM_PTR'
	public static val TRUE = 'TRUE'
	public static val FALSE = 'FALSE'
	public static val FILE_SCHEMA = 'file://'
	public static val FILE_ASM_EXTENSION = '.asm'
	public static val FILE_INC_EXTENSION = '.inc'
	public static val FILE_DMC_EXTENSION = '.dmc'

	@Inject extension Datas
	@Inject extension Values
	@Inject extension Classes
	@Inject extension Operations
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Expressions
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	val running = new HashSet<Member>
	val allocating = new HashSet<Member>

	def getOverriders(Method method) {
		method.containerClass.subClasses.map[declaredMethods.filter[it.isOverrideOf(method)]].filterNull.flatten
	}
	
	def getOverriders(Variable variable) {
		variable.containerClass.subClasses.map[declaredFields.filter[it.isOverrideOf(variable)]].filterNull.flatten
	}

	def isAccessibleFrom(Member member, EObject context) {
		if (context instanceof MemberSelect) {
			val receiverClass = context.receiver.typeOf
			member.containerClass.isSubclassOf(receiverClass) && (context.containerClass.isSubclassOf(receiverClass) || member.isPublic)
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

	def isROM(Variable variable) {
		switch(variable.storage?.type) {
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

	def isOverrideOf(Method m1, Method m2) {
		if (m1.params.size === m2.params.size) {
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

			return m1.name == m2.name
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
	
	def isDispose(Method method) {
		method.name == 'dispose' && method.params.isEmpty
	}
	
	def isNonDispose(Method method) {
		!method.isDispose
	}
	
	def isArrayReference(Variable variable, List<Index> indexes) {
		variable.dimensionOf.size > indexes.size
	}

	def typeOf(Member member) {
		switch (member) {
			Variable: member.typeOf
			Method: member.typeOf
		}
	}

	def typeOf(Variable variable) {
		if (running.add(variable)) {
			try {
				if (variable.type !== null) {
					variable.type
				} else if (variable.value instanceof MemberRef && (variable.value as MemberRef).member === variable) {
					TypeSystem::TYPE_VOID
				} else {
					variable.value.typeOf
				}
			} finally {
				running.remove(variable)
			}
		}
	}

	def typeOf(Method method) {
		if (running.add(method)) {
			try {
				method.body.getAllContentsOfType(ReturnStatement).map[value.typeOf].filterNull.toSet.merge
			} finally {
				running.remove(method)
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
		
		if (running.add(variable)) {
			try {
				return variable.value.valueOf
			} finally {
				running.remove(variable)
			}
		}
	}

	def lenOfArrayReference(Variable variable, List<Index> indexes) {
		variable.dimensionOf.drop(indexes.size).reduce[d1, d2| d1 * d2]
	}

	def List<Integer> dimensionOf(Member member) {
		switch (member) {
			Variable:
				if (member.isParameter) {
					member.dimension.map[1]
				} else {
					member.value.dimensionOf
				}
			Method:
				<Integer>emptyList // FIXME methods cannot return arrays?
		}
	}

	def rawSizeOf(Member member) {
		member.typeOf.rawSizeOf * (member.dimensionOf.reduce [ d1, d2 |
			d1 * d2
		] ?: 1)
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

	def prepare(Method method, AllocContext ctx) {
		method.body.statements.forEach[prepare(ctx)]
	}

	def dispose(Member member, AllocContext ctx) {
		if (member instanceof Variable) {
			if (member.isNonStatic && member.isNonField && member.isNonParameter) { // TODO check for non for/forEach/while variables
				val allChunks = ctx.pointers.get(member.nameOf) + ctx.variables.get(member.nameOf)
				
				ctx.counters.forEach[counter, page|
					val chunks = allChunks.filter[hi < (page + 1) * 256]
					val last = chunks.last
					
					if (last.hi + 1 === counter.get) {
						if (last.lo < (page + 1) * 256) {
							counter.set(last.lo)
						} else {
							ctx.resetCounter(page)
							ctx.counters.get(page - 1).set(last.lo)
						}
					}
				]
			}
		}
	}

	def alloc(Method method, AllocContext ctx) {
		if (allocating.add(method)) {
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
				ctx.methods += method

				return chunks
			} finally {
				allocating.remove(method)
			}
		} else {
			newArrayList
		}
	}

	def compile(Method method, CompileContext ctx) '''
		«IF method.isNonDispose»
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
			«FOR staticVar : ctx.allocation.statics»
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
		
		if (running.add(variable)) {
			try {
				return variable.nameOfConstant
			} finally {
				running.remove(variable)
			}
		}
	}

	def compileReference(Variable variable, Expression receiver, List<Index> indexes, CompileContext ctx) '''
		«val overriders = if (receiver instanceof This || receiver instanceof Super) emptyList else variable.overriders»
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
			«val finish = '''reference@«rcv.hashCode.toHexString».end'''»
			«val pullAcc = ctx.pullAccIfOperating»
			«FOR overrider : overriders»
				«val skip = '''reference@«rcv.hashCode.toHexString».skip.«overrider.fullyQualifiedName»'''»
					CMP #«overrider.containerClass.asmName»
					BNE +«skip»
				«pullAcc»
				«overrider.compileIndirectReference(rcv, indexes, ctx)»
					JMP +«finish»
				+«skip»:
			«ENDFOR»
			«pullAcc»
			«variable.compileIndirectReference(rcv, indexes, ctx)»
			+«finish»:
		«ENDIF»
	'''
	
	private def compileAbsoluteReference(Variable variable, CompileContext receiver, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = receiver.container
			operation = receiver.operation
			absolute = receiver.absolute
			index = receiver.index
			type = variable.typeOf
		]»
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, ctx)»
			«val tmpIndex = indexes.nameOfTmp(ctx.container)»
			«IF ref.index === null»
				«ref.index = tmpIndex»
			«ELSE»
				«ctx.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					ADC «ref.index»
					STA «tmpIndex»
				«ctx.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ENDIF»
		«ELSE»
			«val tmpIndex = '''#«variable.nameOfOffset»'''»
			«ref.absolute = '''«ref.absolute» + «tmpIndex»'''»
		«ENDIF»
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
			indirect = receiver.indirect
			index = receiver.index
			type = variable.typeOf
		]»
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, ctx)»
			«val tmpIndex = indexes.nameOfTmp(ctx.container)»
			«IF ref.index === null»
				«ref.index = tmpIndex»
			«ELSEIF ref.index.contains(STATIC_PREFIX)»
				«ctx.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					«FOR immediate : ref.index.split(' + ')»
						ADC «immediate»
					«ENDFOR»
					STA «tmpIndex»
				«ctx.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ELSE»
				«ctx.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					ADC «ref.index»
					STA «tmpIndex»
				«ctx.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ENDIF»
		«ELSE»
			«val tmpIndex = '''#«variable.nameOfOffset»'''»
			«IF ref.index === null»
				«ref.index = tmpIndex»
			«ELSEIF ref.index.contains(STATIC_PREFIX)»
				«ref.index = '''«ref.index» + «tmpIndex»'''»
			«ELSE»
				«ctx.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					ADC «ref.index»
					STA «tmpIndex»
				«ctx.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ENDIF»
		«ENDIF»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compilePointerReference(Variable variable, String receiver, List<Index> indexes, CompileContext ctx) '''
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, ctx)»
		«ENDIF»
		«val ref = new CompileContext => [
			container = ctx.container
			type = variable.typeOf
			indirect = receiver
			index = if (indexes.isNotEmpty) {
				indexes.nameOfTmp(ctx.container)
			} else {
				'''#«variable.nameOfOffset»'''
			}
		]»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compileStaticReference(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, ctx)»
		«ENDIF»
		«val ref = new CompileContext => [
			container = ctx.container
			type = variable.typeOf
			absolute = variable.nameOfStatic
			index = if (indexes.isNotEmpty) {
				indexes.nameOfTmp(ctx.container)
			}
		]»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(ctx, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''
	
	def compileLocalReference(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, ctx)»
		«ENDIF»
		«val ref = new CompileContext => [
			container = ctx.container
			type = variable.typeOf
			absolute = variable.nameOf
			index = if (indexes.isNotEmpty) {
				indexes.nameOfTmp(ctx.container)
			}
		]»
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

	def compileInvocation(Method method, Expression receiver, List<Expression> args, CompileContext ctx) '''
		«val overriders = if (receiver instanceof This || receiver instanceof Super) emptyList else method.overriders»
		«receiver.compile(new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			indirect = method.nameOfReceiver
			type = receiver.typeOf
			mode = Mode::POINT
		])»
		«IF overriders.isNotEmpty»
			«ctx.pushAccIfOperating»
				LDY #$00
				LDA («method.nameOfReceiver»), Y
		«ENDIF»
		«val finish = '''invocation@«overriders.hashCode.toHexString».finish'''»
		«FOR overrider : overriders»
			«val skip = '''invocation@«overriders.hashCode.toHexString».skip.«overrider.fullyQualifiedName»'''»
				CMP #«overrider.containerClass.asmName»
				BNE +«skip»
			«val falseReceiver = new CompileContext => [
				operation = ctx.operation
				indirect = method.nameOfReceiver
			]»
			«val realReceiver = new CompileContext => [
				operation = ctx.operation
				indirect = overrider.nameOfReceiver
			]»
			«realReceiver.pointTo(falseReceiver)»
			«overrider.compileInvocation(args, ctx)»
				JMP +«finish»
			+«skip»:
		«ENDFOR»
		«method.compileInvocation(args, ctx)»
		«IF overriders.isNotEmpty»
			+«finish»:
		«ENDIF»
	'''

	def compileInvocation(Method method, List<Expression> args, CompileContext ctx) '''
		«IF method.isNonDispose»
			«ctx.pushAccIfOperating»
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
				«val dimension = arg.dimensionOf»
				«FOR dim : 0..< dimension.size»
				«noop»
					LDA #«dimension.get(dim).toHex»
					STA «param.nameOfLen(methodName, dim)»
				«ENDFOR»
			«ENDFOR»
			«noop»
				JSR «method.nameOf»
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
				«ret.resolveTo(ctx)»
			«ENDIF»
		«ENDIF»
	'''

	def compileIndexes(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«val indexName = indexes.nameOfTmp(ctx.container)»
		«val dimension = variable.dimensionOf»
		«val sizeOfVar = variable.typeOf.sizeOf»
		«ctx.pushAccIfOperating»
		«IF dimension.size === 1 && sizeOfVar === 1»
			«indexes.head.value.compile(new CompileContext => [
				container = ctx.container
				type = ctx.type.toByteClass
				register = 'A'
			])»
				«IF variable.isField && variable.isNonStatic»
					CLC
					ADC #«variable.nameOfOffset»
				«ENDIF»
				STA «indexName»
		«ELSE»
			«FOR i : 0..< indexes.size»
				«indexes.get(i).value.compile(new CompileContext => [
					container = ctx.container
					operation = ctx.operation
					type = ctx.type.toByteClass
					register = 'A'
				])»
					«FOR len : (i + 1)..< dimension.size»
						STA «Members::TEMP_VAR_NAME1»
						LDA «IF variable.isParameter»«variable.nameOfLen(len)»«ELSE»#«dimension.get(len).toHex»«ENDIF»
						STA «Members::TEMP_VAR_NAME2»
						LDA #$00
						mult8x8to8
					«ENDFOR»
					«IF (i + 1) < indexes.size»
						PHA
					«ENDIF»
			«ENDFOR»
			«FOR i : 1..< indexes.size»
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
				«IF variable.isField && variable.isNonStatic»
					ADC #«variable.nameOfOffset»
				«ENDIF»
				STA «indexName»
		«ENDIF»
		«ctx.pullAccIfOperating»
	'''
	
	private def void noop() {
	}
	
}
