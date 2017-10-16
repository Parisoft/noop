package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.HashSet
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.CompileData
import org.parisoft.noop.generator.CompileData.Mode
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension java.lang.Character.*
import static extension java.lang.Integer.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.MemberSelect

public class Members {

	public static val STATIC_PREFIX = '$'
	public static val TEMP_VAR_NAME1 = 'billy'
	public static val TEMP_VAR_NAME2 = 'jimmy'
	public static val TRUE = 'TRUE'
	public static val FALSE = 'FALSE'
	public static val FILE_SCHEMA = 'file://'

	static val UNDERLINE_CHAR = '_'.charAt(0)

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

	def isAccessibleFrom(Member member, EObject context) {
		val contextClass = if (context instanceof MemberSelect) {
				context.receiver.typeOf
			} else {
				context.containingClass
			} 
		val memberClass = member.containingClass

		contextClass == memberClass || contextClass.isSubclassOf(memberClass)
	}

	def isStatic(Member member) {
		try {
			member.name.startsWith(STATIC_PREFIX)
		} catch (Error e) {
			e.printStackTrace			
		}
	}

	def isNonStatic(Member member) {
		!member.isStatic
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
							c.isUpperCase || c.isDigit || c === UNDERLINE_CHAR
						]
	}

	def isNonConstant(Variable variable) {
		!variable.isConstant
	}

	def isROM(Variable variable) {
		variable.storage !== null
	}

	def isNonROM(Variable variable) {
		!variable.isROM
	}
	
	def isFileInclude(Variable variable) {
		variable.name.toLowerCase.startsWith(FILE_SCHEMA)
	}
	
	def isDMC(Variable variable) {
		variable.isFileInclude && variable.name.toLowerCase.endsWith('.dmc')
	}
	
	def isNonDMC(Variable variable) {
		!variable.isDMC
	}

	def isIrq(Method method) {
		method.containingClass.isGame && method.name == '''«STATIC_PREFIX»irq'''.toString && method.params.isEmpty
	}

	def isNmi(Method method) {
		method.containingClass.isGame && method.name == '''«STATIC_PREFIX»nmi'''.toString && method.params.isEmpty
	}
	
	def isReset(Method method) {
		method.containingClass.isGame && method.name == '''«STATIC_PREFIX»reset'''.toString && method.params.isEmpty
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
		if (variable.isNonConstant) {
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
				<Integer>emptyList // methods cannot return arrays?
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
		'''«variable.containingClass.name».«variable.name»'''.toString
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

	def prepare(Method method, AllocData data) {
		method.body.statements.forEach[prepare(data)]
	}

	def dispose(Member member, AllocData data) {
		if (member instanceof Variable) {
			if (member.isNonStatic && member.isNonField && member.isNonParameter) { // TODO check for non for/forEach/while variables
				val pointers = data.pointers.get(member.nameOf)
				
				if (pointers !== null) {
					pointers.forEach[disposed = true]
					
					if (pointers.last.hi === data.ptrCounter.get + 1) {
						data.ptrCounter.set(pointers.last.lo)
					}
				}
				
				val variables = data.variables.get(member.nameOf)

				if (variables !== null) {
					variables.forEach[disposed = true]
					
					if (variables.last.hi === data.varCounter.get - 1) {
						data.varCounter.set(variables.last.lo)
					}
				}				
			}
		}
	}

	def alloc(Method method, AllocData data) {
		if (allocating.add(method)) {
			try {
				val snapshot = data.snapshot
				val methodName = method.nameOf

				data.container = methodName

				val receiver = if (method.isNonStatic) {
						data.computePtr(method.nameOfReceiver)
					} else {
						emptyList
					}

				val chunks = (receiver + method.params.map[alloc(data)].flatten).toList
				chunks += method.body.statements.map[alloc(data)].flatten.toList
				chunks.disoverlap(methodName)

				data.restoreTo(snapshot)
				data.methods += method

				return chunks
			} finally {
				allocating.remove(method)
			}
		} else {
			newArrayList
		}
	}

	def compile(Method method, CompileData data) '''
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
			«FOR staticVar : data.allocation.statics»
				«staticVar.compile(new CompileData => [container = resetMethod])»
			«ENDFOR»
			
			-waitVBlank2
				BIT $2002
				BPL -waitVBlank2
				;;;;;;;;;; Initial setup end
			«FOR statement : method.body.statements»
				«statement.compile(new CompileData => [container = method.nameOf])»
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
				«statement.compile(new CompileData => [container = method.nameOf])»
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
					«statement.compile(new CompileData => [container = method.nameOf])»
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

	def compileAbsoluteReference(Variable variable, CompileData receiver, List<Index> indexes, CompileData data) '''
		«val ref = new CompileData => [
			container = receiver.container
			operation = receiver.operation
			absolute = receiver.absolute
			index = receiver.index
			type = variable.typeOf
		]»
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, data)»
			«val tmpIndex = indexes.nameOfTmp(data.container)»
			«IF ref.index === null»
				«ref.index = tmpIndex»
			«ELSE»
				«data.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					ADC «ref.index»
					STA «tmpIndex»
				«data.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ENDIF»
		«ELSE»
			«val tmpIndex = '''#«variable.nameOfOffset»'''»
			«ref.absolute = '''«ref.absolute» + «tmpIndex»'''»
		«ENDIF»
		«IF data.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(data, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(data)»
		«ENDIF»
	'''
	
	def compileIndirectReference(Variable variable, CompileData receiver, List<Index> indexes, CompileData data) '''
		«val ref = new CompileData => [
			container = receiver.container
			operation = receiver.operation
			indirect = receiver.indirect
			index = receiver.index
			type = variable.typeOf
		]»
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, data)»
			«val tmpIndex = indexes.nameOfTmp(data.container)»
			«IF ref.index === null»
				«ref.index = tmpIndex»
			«ELSEIF ref.index.contains(STATIC_PREFIX)»
				«data.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					«FOR immediate : ref.index.split(' + ')»
						ADC «immediate»
					«ENDFOR»
					STA «tmpIndex»
				«data.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ELSE»
				«data.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					ADC «ref.index»
					STA «tmpIndex»
				«data.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ENDIF»
		«ELSE»
			«val tmpIndex = '''#«variable.nameOfOffset»'''»
			«IF ref.index === null»
				«ref.index = tmpIndex»
			«ELSEIF ref.index.contains(STATIC_PREFIX)»
				«ref.index = '''«ref.index» + «tmpIndex»'''»
			«ELSE»
				«data.pushAccIfOperating»
					CLC
					LDA «tmpIndex»
					ADC «ref.index»
					STA «tmpIndex»
				«data.pullAccIfOperating»
				«ref.index = tmpIndex»
			«ENDIF»
		«ENDIF»
		«IF data.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(data, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(data)»
		«ENDIF»
	'''

	def compilePointerReference(Variable variable, String receiver, List<Index> indexes, CompileData data) '''
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, data)»
		«ENDIF»
		«val ref = new CompileData => [
			container = data.container
			type = variable.typeOf
			indirect = receiver
			index = if (indexes.isNotEmpty) {
				indexes.nameOfTmp(data.container)
			} else {
				'''#«variable.nameOfOffset»'''
			}
		]»
		«IF data.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(data, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(data)»
		«ENDIF»
	'''

	def compileStaticReference(Variable variable, List<Index> indexes, CompileData data) '''
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, data)»
		«ENDIF»
		«val ref = new CompileData => [
			container = data.container
			type = variable.typeOf
			absolute = variable.nameOfStatic
			index = if (indexes.isNotEmpty) {
				indexes.nameOfTmp(data.container)
			}
		]»
		«IF data.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(data, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(data)»
		«ENDIF»
	'''
	
	def compileLocalReference(Variable variable, List<Index> indexes, CompileData data) '''
		«IF indexes.isNotEmpty»
			«variable.compileIndexes(indexes, data)»
		«ENDIF»
		«val ref = new CompileData => [
			container = data.container
			type = variable.typeOf
			absolute = variable.nameOf
			index = if (indexes.isNotEmpty) {
				indexes.nameOfTmp(data.container)
			}
		]»
		«IF data.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.copyArrayTo(data, variable.lenOfArrayReference(indexes))»
		«ELSE»
			«ref.resolveTo(data)»
		«ENDIF»
	'''
	
	def compileConstantReference(Variable variable, CompileData data) '''
		«val const = new CompileData => [
			container = data.container
			type = variable.typeOf
			immediate = variable.nameOfConstant
		]»
		«IF data.mode === Mode::OPERATE»
			«data.operateOn(const)»
		«ELSEIF data.mode === Mode::COPY»
			«const.copyTo(data)»
		«ENDIF»
	'''

	def compileInvocation(Method method, List<Expression> args, CompileData data) '''
		«IF method.isNonDispose»
			«data.pushAccIfOperating»
			«val methodName = method.nameOf»
			«FOR i : 0..< args.size»
				«val param = method.params.get(i)»
				«val arg = args.get(i)»
				«arg.compile(new CompileData => [
					container = data.container
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
			«data.pullAccIfOperating»
			«IF method.typeOf.isNonVoid»
				«val ret = new CompileData => [
					container = data.container
					type = method.typeOf
					
					if (method.typeOf.isPrimitive && method.dimensionOf.isEmpty) {
						absolute = method.nameOfReturn
					} else {
						indirect = method.nameOfReturn
					}
				]»
				«ret.resolveTo(data)»
			«ENDIF»
		«ENDIF»
	'''

	def compileIndexes(Variable variable, List<Index> indexes, CompileData data) '''
		«val indexName = indexes.nameOfTmp(data.container)»
		«val dimension = variable.dimensionOf»
		«val sizeOfVar = variable.typeOf.sizeOf»
		«data.pushAccIfOperating»
		«IF dimension.size === 1 && sizeOfVar === 1»
			«indexes.head.value.compile(new CompileData => [
				container = data.container
				type = data.type.toByteClass
				register = 'A'
			])»
				«IF variable.isField && variable.isNonStatic»
					CLC
					ADC #«variable.nameOfOffset»
				«ENDIF»
				STA «indexName»
		«ELSE»
			«FOR i : 0..< indexes.size»
				«indexes.get(i).value.compile(new CompileData => [
					container = data.container
					operation = data.operation
					type = data.type.toByteClass
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
		«data.pullAccIfOperating»
	'''
	
	private def void noop() {
	}
	
}
