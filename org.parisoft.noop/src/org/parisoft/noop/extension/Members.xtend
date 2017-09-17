package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.HashSet
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.CompileData
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension java.lang.Character.*
import static extension java.lang.Integer.*
import static extension org.eclipse.xtext.EcoreUtil2.*

public class Members {

	public static val STATIC_PREFIX = '#'
	public static val TEMP_VAR_NAME1 = 'billy'
	public static val TEMP_VAR_NAME2 = 'jimmy'

	static val UNDERLINE_CHAR = '_'.charAt(0)

	@Inject extension Classes
	@Inject extension Expressions
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension Values
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

	def prepare(Method method, AllocData data) {
		method.body.statements.forEach[prepare(data)]
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
			«FOR staticVar : data.allocation.statics»
				«staticVar.compile(new CompileData => [container = resetMethod])»
			«ENDFOR»
			
			«val gameInstance = data.allocation.statics.findFirst[typeOf.game]»
			«val gameName = gameInstance.asmStaticName»
			«val nmiReceiver = gameInstance.typeOf.allMethodsBottomUp.findFirst[nmi].asmReceiverName»
				LDA #<(«gameName»)
				STA «nmiReceiver» + 0
				LDA #>(«gameName»)
				STA «nmiReceiver» + 1
			
			-waitVBlank2
				BIT $2002
				BPL -waitVBlank2
				;;;;;;;;;; Initial setup end

			«FOR statement : method.body.statements»
				«statement.compile(new CompileData => [container = method.asmName])»
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

	def compileIndirectReference(Variable variable, String varAsIndirect, List<Index> indexes, CompileData data) '''
		«val varIsIndexed = indexes.isNotEmpty»
		«IF data.absolute !== null»
			«IF data.isIndexed»
				«noop»
					LDX «data.index»
			«ENDIF»
			«IF varIsIndexed»
				«variable.compileIndexesIntoRegiter(indexes, 'Y')»
			«ELSE»
				«noop»
					LDY #«IF variable.isField»«variable.asmOffsetName»«ELSE»$00«ENDIF»
			«ENDIF»
			«FOR i : 0..< data.type.sizeOf»
				«noop»
					«IF i > 0»
						INY
					«ENDIF»
					LDA («varAsIndirect»), Y
					STA «data.absolute»«IF i > 0» + «i»«ENDIF»«IF data.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSEIF data.indirect !== null && data.isCopy»
			«IF data.isIndexed»
				«noop»
					LDY «data.index»
			«ELSE»
				«noop»
					LDY #$00
			«ENDIF»
			«IF varIsIndexed»
				«variable.compileIndexesIntoRegiter(indexes, 'X')»
			«ELSE»
				«noop»
					LDX #«IF variable.isField»«variable.asmOffsetName»«ELSE»$00«ENDIF»
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
			«IF varIsIndexed || variable.isField»
				«IF varIsIndexed»
					«variable.compileIndexesIntoRegiter(indexes, 'A')»
				«ELSE»
					«noop»
						LDA #«variable.asmOffsetName»
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
			«IF varIsIndexed»
				«variable.compileIndexesIntoRegiter(indexes, 'Y')»
					LDA («varAsIndirect»), Y
			«ELSEIF variable.isField»
				«noop»
					LDY #«variable.asmOffsetName»
					LDA («varAsIndirect»), Y
			«ELSE»
				«noop»
					LDA («varAsIndirect»)
			«ENDIF»
			«IF data.register != 'A'»
				«noop»
					TA«data.register»
			«ENDIF»
		«ENDIF»
	'''

	def compileAbsoluteReference(Variable variable, String varAsAbsolute, List<Index> indexes, CompileData data) '''
		«val varIsIndexed = indexes.isNotEmpty»
		«IF data.absolute !== null»
			«IF data.isIndexed»
				«noop»
					LDX «data.index»
			«ENDIF»
			«IF varIsIndexed»
				«variable.compileIndexesIntoRegiter(indexes, 'Y')»
			«ENDIF»
			«FOR i : 0..< data.type.sizeOf»
				«noop»
					LDA «varAsAbsolute»«IF i > 0» + «i»«ENDIF»«IF varIsIndexed», Y«ENDIF»
					STA «data.absolute»«IF i > 0» + «i»«ENDIF»«IF data.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSEIF data.indirect !== null && data.isCopy»
			«IF data.isIndexed»
				«noop»
					LDY «data.index»
			«ELSE»
				«noop»
					LDY #$00
			«ENDIF»
			«IF varIsIndexed»
				«variable.compileIndexesIntoRegiter(indexes, 'X')»
			«ENDIF»
			«FOR i : 0..< data.type.sizeOf»
				«noop»
					«IF i > 0»
						INY
					«ENDIF»
					LDA «varAsAbsolute»«IF i > 0» + «i»«ENDIF»«IF varIsIndexed», X«ENDIF»
					STA («data.indirect»), Y
			«ENDFOR»
		«ELSEIF data.indirect !== null»
			«IF varIsIndexed»
				«variable.compileIndexesIntoRegiter(indexes, 'A')»
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
			«IF varIsIndexed»
				«IF data.register == 'Y'»
					«variable.compileIndexesIntoRegiter(indexes, 'X')»
						LDY «varAsAbsolute», X
				«ELSE»
					«variable.compileIndexesIntoRegiter(indexes, 'Y')»
						LD«data.register» «varAsAbsolute», Y
				«ENDIF»
			«ELSE»
				«noop»
					LD«data.register» «varAsAbsolute»
			«ENDIF»
		«ENDIF»
	'''
	
	def compileConstantReference(Variable variable, String varAsConstant, List<Index> indexes, CompileData data) '''
		«IF data.absolute !== null»
			«IF data.isIndexed»
				«noop»
					LDX «data.index»
			«ENDIF»
			«noop»
				LDA #<(«varAsConstant»)
				STA «data.absolute»«IF data.isIndexed», X«ENDIF»
				«IF data.type.sizeOf > 1»
					LDA #>(«varAsConstant»)
					STA «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
				«ENDIF»
		«ELSEIF data.indirect !== null && data.isCopy»
			«val sizeOfData = data.type.sizeOf»
			«IF data.isIndexed»
				«noop»
					LDY «data.index»
			«ELSEIF sizeOfData > 1»
				«noop»
					LDY #$00
			«ENDIF»
			«noop»
				LDA #<(«varAsConstant»)
				STA («data.indirect»)«IF sizeOfData > 1 || data.isIndexed», Y«ENDIF»
				«IF sizeOfData > 1»
					INY
					LDA #>(«varAsConstant»)
					STA («data.indirect»), Y
				«ENDIF»
		«ELSEIF data.indirect !== null»
			«noop»
				LDA #<(«varAsConstant»)
				STA «data.indirect» + 0
				LDA #>(«varAsConstant»)
				STA «data.indirect» + 1
		«ELSEIF data.register !== null»
			«noop»
				LD«data.register» #<(«varAsConstant»)
		«ENDIF»
	'''

	def compileInvocation(Method method, List<Expression> args, CompileData data) '''
		«val methodName = method.asmName»
		«FOR i : 0..< args.size»
			«val param = method.params.get(i)»
			«val arg = args.get(i)»
			«arg.compile(new CompileData => [
				container = methodName
				type = param.type
				
				if (param.type.isPrimitive && param.dimensionOf.isEmpty) {
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
		«IF method.typeOf.isPrimitive»
			«val retAsAbsolute = method.asmReturnName»
			«IF data.absolute !== null»
				«noop»
					«IF data.isIndexed»
						LDX «data.index»
					«ENDIF»
					«FOR i : 0..< data.type.sizeOf»
						LDA «retAsAbsolute»«IF i > 0» + «i»«ENDIF»
						STA «data.absolute»«IF i > 0» + «i»«ENDIF»«IF data.isIndexed», X«ENDIF»
					«ENDFOR»
			«ELSEIF data.indirect !== null && data.isCopy»
				«val sizeOfData = data.type.sizeOf»
					«IF data.isIndexed»
						LDY «data.index»
					«ELSEIF sizeOfData > 1»
						LDY #$00
					«ENDIF»
					«FOR i : 0..< sizeOfData»
						«IF i > 0»
							INY
						«ENDIF»
						LDA «retAsAbsolute»«IF i > 0» + «i»«ENDIF»
						STA («data.indirect»)«IF i > 0 || data.isIndexed», Y«ENDIF»
					«ENDFOR»
			«ELSEIF data.indirect !== null»
				«noop»
					LDA #<(«retAsAbsolute»)
					STA «data.indirect» + 0
					LDA #>(«retAsAbsolute»)
					STA «data.indirect» + 1
			«ELSEIF data.register !== null»
				«noop»
					LD«data.register» «retAsAbsolute»
			«ENDIF»
		«ELSEIF method.typeOf.isNonVoid»
			«val retAsIndirect = method.asmReturnName»
			«IF data.absolute !== null»
				«noop»
					«IF data.isIndexed»
						LDX «data.index»
					«ENDIF»
					«FOR i : 0..< data.type.sizeOf»
						«IF i == 1»
							LDY #$01
						«ELSEIF i > 1»
							INY
						«ENDIF»
						LDA («retAsIndirect»)«IF i > 0», Y«ENDIF»
						STA «data.absolute»«IF i > 0» + «i»«ENDIF»«IF data.isIndexed», X«ENDIF»
					«ENDFOR»
			«ELSEIF data.indirect !== null && data.isCopy»
				«val sizeOfData = data.type.sizeOf»
					«IF data.isIndexed»
						LDY «data.index»
					«ELSEIF sizeOfData > 1»
						LDY #$00
					«ENDIF»
					«IF sizeOfData > 1»
						LDX #$00
					«ENDIF»
					«FOR i : 0..< sizeOfData»
						«IF i > 0»
							INX
							INY
						«ENDIF»
						LDA («retAsIndirect»«IF i > 0», X«ENDIF»)
						STA («data.indirect»)«IF i > 0 || data.isIndexed», Y«ENDIF»
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
	'''

	def compileIndexesIntoRegiter(Variable variable, List<Index> indexes, String reg) '''
		«val dimension = variable.dimensionOf»
		«val sizeOfVar = variable.typeOf.sizeOf»
		«IF dimension.size === 1 && sizeOfVar === 1»
			«val index = indexes.head»
			«IF variable.isField»
				«index.value.compile(new CompileData => [register = 'A'])»
					ADC #«variable.asmOffsetName»
					«IF reg != 'A'»
						TA«reg»
					«ENDIF»
			«ELSE»
				«index.value.compile(new CompileData => [register = reg])»
			«ENDIF»
		«ELSE»
			«FOR i : 0..< indexes.size»
				«val index = indexes.get(i)»
				«index.value.compile(new CompileData => [register = 'A'])»
					«FOR len : (i + 1)..< dimension.size»
						STA «Members::TEMP_VAR_NAME1»
						LDA «IF variable.isParameter»«variable.asmLenName(len)»«ELSE»#«dimension.get(len).toHex»«ENDIF»
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
				«IF variable.isField»
					ADC #«variable.asmOffsetName»
				«ENDIF»
				«IF reg != 'A'»
					TA«reg»
				«ENDIF»
		«ENDIF»
	'''
	
	private def void noop() {
	}
	
}
