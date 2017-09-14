package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.HashSet
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension java.lang.Integer.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.generator.CompileData
import org.parisoft.noop.generator.AllocData

public class Members {

	public static val STATIC_PREFIX = '#'
	public static val TEMP_VAR_NAME1 = 'billy'
	public static val TEMP_VAR_NAME2 = 'jimmy'

	static val UNDERLINE_CHAR = '_'.charAt(0)

	@Inject extension Classes
	@Inject extension Expressions
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	val running = new HashSet<Member>
	val allocating = new HashSet<Member>

	def isAccessibleFrom(Member member, EObject context) {
		val contextClass = if (context instanceof MemberSelection) context.receiver.typeOf else context.containingClass
		val memberClass = member.containingClass

		contextClass == memberClass || contextClass.isSubclassOf(memberClass)
	}

	def isStatic(Member member) {
		member.name.startsWith(STATIC_PREFIX)
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
							Character::isUpperCase(c) || Character::isDigit(c) || (c) === UNDERLINE_CHAR
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

	def isMain(Method method) {
		method.containingClass.isGame && method.name == 'main' && method.params.isEmpty
	}

	def isNmi(Method method) {
		method.containingClass.isGame && method.name == 'nmi' && method.params.isEmpty
	}
	
	def isReset(Method method) {
		method.containingClass.isGame && method.name == '#reset' && method.params.isEmpty
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
			Method: member.valueOf
		}
	}

	def valueOf(Variable variable) {
		if (running.add(variable)) {
			try {
				return variable.value.valueOf
			} finally {
				running.remove(variable)
			}
		}
	}

	def valueOf(Method method) {
		throw new NonConstantMemberException
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

	def sizeOf(Member member) {
		member.typeOf.sizeOf * (member.dimensionOf.reduce [ d1, d2 |
			d1 * d2
		] ?: 1)
	}

	def asmName(Variable variable) {
		variable.asmName(variable.getContainerOfType(Method)?.asmName)
	}

	def String asmName(Variable variable, String containerName) {
		if (variable.isStatic) {
			variable.asmStaticName
		} else if (variable.getContainerOfType(Method) !== null) {
			'''«containerName»«variable.fullyQualifiedName.toString.substring(containerName.indexOf('@'))»@«variable.hashCode.toHexString»'''
		} else {
			'''«containerName».«variable.name»@«variable.hashCode.toHexString»'''
		}
	}

	def asmStaticName(Variable variable) {
		'''«variable.containingClass.name».«variable.name»'''.toString
	}

	def asmConstantName(Variable variable) {
		variable.fullyQualifiedName.toString
	}

	def asmOffsetName(Variable variable) {
		variable.fullyQualifiedName.toString
	}
	
	def asmLenName(Variable variable, String container, int i) {
		'''«variable.asmName(container)».len«i»'''.toString
	}
	
	def asmLenName(Variable variable, int i) {
		variable.asmLenName(variable.getContainerOfType(Method).asmName, i)
	}

	def asmName(Method method) {
		'''«method.fullyQualifiedName.toString»@«method.hashCode.toHexString»'''.toString
	}

	def asmReceiverName(Method method) {
		'''«method.asmName».receiver'''.toString
	}
	
	def asmReturnName(Method method) {
		'''«method.asmName».return'''.toString
	}

	def alloc(Method method, AllocData data) {
		if (allocating.add(method)) {
			try {
				val snapshot = data.snapshot
				val methodName = method.asmName

				data.container = methodName

				val receiver = if (method.isNonStatic) {
						data.pointers.computeIfAbsent(method.asmReceiverName, [newArrayList(data.chunkForPtr(it))])
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
		«method.asmName»:
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

				; Instantiate all static variables, including the game itself
			«val resetMethod = method.asmName»
			«FOR staticVar : data.stack.statics»
				«staticVar.compile(new CompileData => [container = resetMethod])»
			«ENDFOR»
			
			-waitVBlank2
				BIT $2002
				BPL -waitVBlank2
				;;;;;;;;;; Initial setup end
			
			«val gameInstance = method.body.statements.filter(Variable).findFirst[typeOf.game]»
			«val gameName = gameInstance.asmStaticName»
			«val mainMethod = gameInstance.typeOf.allMethodsBottomUp.findFirst[main]»
			«val mainReceiver = mainMethod.asmReceiverName»
				LDA #<(«gameName»)
				STA «mainReceiver» + 0
				LDA #>(«gameName»)
				STA «mainReceiver» + 1
				JMP «mainMethod.asmName»
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
			«statement.compile(new CompileData => [container = method.asmName])»
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
				«statement.compile(new CompileData => [container = method.asmName])»
			«ENDFOR»
				RTS
		«ENDIF»
	'''

}
