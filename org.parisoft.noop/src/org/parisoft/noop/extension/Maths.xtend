package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.CompileData

class Maths {

	@Inject extension Datas
	@Inject extension Classes

	val labelCounter = new AtomicInteger

	def operateOn(CompileData acc, CompileData data) {
		switch (acc.operation) {
			case ADDITION: acc.add(data)
			case SUBTRACTION: acc.subtract(data)
			case BIT_OR: acc.bitOr(data)
			case BIT_AND: acc.bitAnd(data)
			default: ''''''
		}
	}

	def add(CompileData acc, CompileData data) '''
		«IF data.immediate !== null»
			«acc.addImmediate(data)»
		«ELSEIF data.absolute !== null»
			«acc.addAbsolute(data)»
		«ELSEIF data.indirect !== null»
			«acc.addIndirect(data)»
		«ENDIF»
	'''

	def subtract(CompileData acc, CompileData data) '''
		«IF data.immediate !== null»
			«acc.subtractImmediate(data)»
		«ELSEIF data.absolute !== null»
			«acc.subtractAbsolute(data)»
		«ELSEIF data.indirect !== null»
			«acc.subtractIndirect(data)»
		«ENDIF»
	'''

	def bitOr(CompileData acc, CompileData data) '''
		«IF data.immediate !== null»
			«acc.bitOrImmediate(data)»
		«ELSEIF data.absolute !== null»
			«acc.bitOrAbsolute(data)»
		«ELSEIF data.indirect !== null»
			«acc.bitOrIndirect(data)»
		«ENDIF»
	'''

	def bitAnd(CompileData acc, CompileData data) '''
		«IF data.immediate !== null»
			«acc.bitAndImmediate(data)»
		«ELSEIF data.absolute !== null»
			«acc.bitAndAbsolute(data)»
		«ELSEIF data.indirect !== null»
			«acc.bitAndIndirect(data)»
		«ENDIF»
	'''

	private def addImmediate(CompileData acc, CompileData data) '''
		«noop»
			CLC
			ADC #<(«data.immediate»)
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					ADC #>(«acc.immediate»)
			«ELSE»
				«noop»
					LDA #<(«data.immediate»)
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					ADC «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def addAbsolute(CompileData acc, CompileData data) '''
		«noop»
			«IF data.isIndexed»
				LDX «data.index»
			«ENDIF»
			CLC
			ADC «data.absolute»«IF data.isIndexed», X«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					ADC «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
			«ELSE»
				«noop»
					LDA «data.absolute»«IF data.isIndexed», X«ENDIF»
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					ADC «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def addIndirect(CompileData acc, CompileData data) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
			CLC
			ADC («data.indirect»), Y
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					INY
					PLA
					ADC («data.indirect»), Y
			«ELSE»
				«noop»
					LDA («data.indirect»), Y
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					ADC «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def subtractImmediate(CompileData acc, CompileData data) '''
		«noop»
			SEC
			SBC #<(«data.immediate»)
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					SBC #>(«acc.immediate»)
			«ELSE»
				«noop»
					LDA #<(«data.immediate»)
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					SBC «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def subtractAbsolute(CompileData acc, CompileData data) '''
		«noop»
			«IF data.isIndexed»
				LDX «data.index»
			«ENDIF»
			SEC
			SBC «data.absolute»«IF data.isIndexed», X«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					SBC «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
			«ELSE»
				«noop»
					LDA «data.absolute»«IF data.isIndexed», X«ENDIF»
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					SBC «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def subtractIndirect(CompileData acc, CompileData data) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
			SEC
			SBC («data.indirect»), Y
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					INY
					PLA
					SBC («data.indirect»), Y
			«ELSE»
				«noop»
					LDA («data.indirect»), Y
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					SBC «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def bitOrImmediate(CompileData acc, CompileData data) '''
		«noop»
			ORA #<(«data.immediate»)
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					ORA #>(«acc.immediate»)
			«ELSE»
				«noop»
					LDA #<(«data.immediate»)
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					ORA «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def bitOrAbsolute(CompileData acc, CompileData data) '''
		«noop»
			«IF data.isIndexed»
				LDX «data.index»
			«ENDIF»
			ORA «data.absolute»«IF data.isIndexed», X«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					ORA «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
			«ELSE»
				«noop»
					LDA «data.absolute»«IF data.isIndexed», X«ENDIF»
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					ORA «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def bitOrIndirect(CompileData acc, CompileData data) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
			ORA («data.indirect»), Y
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					INY
					PLA
					ORA («data.indirect»), Y
			«ELSE»
				«noop»
					LDA («data.indirect»), Y
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					ORA «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def bitAndImmediate(CompileData acc, CompileData data) '''
		«noop»
			AND #<(«data.immediate»)
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					AND #>(«acc.immediate»)
			«ELSE»
				«noop»
					LDA #<(«data.immediate»)
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					AND «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def bitAndAbsolute(CompileData acc, CompileData data) '''
		«noop»
			«IF data.isIndexed»
				LDX «data.index»
			«ENDIF»
			AND «data.absolute»«IF data.isIndexed», X«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					AND «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
			«ELSE»
				«noop»
					LDA «data.absolute»«IF data.isIndexed», X«ENDIF»
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					AND «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def bitAndIndirect(CompileData acc, CompileData data) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
			AND («data.indirect»), Y
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					INY
					PLA
					AND («data.indirect»), Y
			«ELSE»
				«noop»
					LDA («data.indirect»), Y
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					AND «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	def loadMSB(CompileData data) '''
		«IF data.type.isSigned»
			«val signLabel = labelForSignedMSBEnd»
				ORA #$7F
				BMI +«signLabel»
				LDA #$00
			+«signLabel»
		«ELSE»
			«noop»
				LDA #$00
		«ENDIF»
	'''

	private def labelForSignedMSBEnd() '''signedMSBEnd«labelCounter.andIncrement»:'''

	private def noop() {
	}
}
