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
	
	def operate(CompileData acc) {
		switch (acc.operation) {
			case EXCLUSIVE_OR: acc.exclusiveOr
			case NEGATION: acc.negate
			case SIGNUM: acc.signum
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
	
	def exclusiveOr(CompileData acc)'''
		«noop»
			EOR #$FF
		«IF acc.sizeOf > 1»
			STA «Members::TEMP_VAR_NAME1»
			PLA
			EOR #$FF
			PHA
			LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''
	
	def negate(CompileData acc)'''
		«noop»
			EOR #$FF
	'''
	
	def signum(CompileData acc)'''
		«IF acc.sizeOf > 1»
			«noop»
				SEC
				STA «Members::TEMP_VAR_NAME1»
				LDA #$00
				SBC «Members::TEMP_VAR_NAME1»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				STA «Members::TEMP_VAR_NAME1» + 1
				LDA #$00
				SBC «Members::TEMP_VAR_NAME1» + 1
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«noop»
				CLC
				EOR #$FF
				ADC #$01
		«ENDIF»
	'''

	private def orImmediate(CompileData acc, CompileData data) '''
		«data.operateImmediate('ORA')»
	'''

	private def orAbsolute(CompileData acc, CompileData data) '''
		«data.operateAbsolute('ORA')»
	'''

	private def orIndirect(CompileData acc, CompileData data) '''
		«data.operateIndirect('ORA')»
	'''

	private def andImmediate(CompileData acc, CompileData data) '''
		«data.operateImmediate('AND')»
	'''

	private def andAbsolute(CompileData acc, CompileData data) '''
		«data.operateAbsolute('AND')»
	'''

	private def andIndirect(CompileData acc, CompileData data) '''
		«data.operateIndirect('AND')»
	'''

	private def addImmediate(CompileData acc, CompileData data) '''
		«acc.operateImmediate('ADC', 'CLC', data)»
	'''

	private def addAbsolute(CompileData acc, CompileData data) '''
		«acc.operateAbsolute('ADC', 'CLC', data)»
	'''

	private def addIndirect(CompileData acc, CompileData data) '''
		«acc.operateIndirect('ADC', 'CLC', data)»
	'''

	private def subtractImmediate(CompileData acc, CompileData data) '''
		«acc.operateImmediate('SBC', 'SEC', data)»
	'''

	private def subtractAbsolute(CompileData acc, CompileData data) '''
		«acc.operateAbsolute('SBC', 'SEC', data)»
	'''

	private def subtractIndirect(CompileData acc, CompileData data) '''
		«acc.operateIndirect('SBC', 'SEC', data)»
	'''

	private def bitOrImmediate(CompileData acc, CompileData data) '''
		«acc.operateImmediate('ORA', data)»
	'''

	private def bitOrAbsolute(CompileData acc, CompileData data) '''
		«acc.operateAbsolute('ORA', data)»
	'''

	private def bitOrIndirect(CompileData acc, CompileData data) '''
		«acc.operateIndirect('ORA', data)»
	'''

	private def bitAndImmediate(CompileData acc, CompileData data) '''
		«acc.operateImmediate('AND', data)»
	'''

	private def bitAndAbsolute(CompileData acc, CompileData data) '''
		«acc.operateAbsolute('AND', data)»
	'''

	private def bitAndIndirect(CompileData acc, CompileData data) '''
		«acc.operateIndirect('AND', data)»
	'''

	private def incAbsolute(CompileData data) '''
		«noop»
			«IF data.isIndexed»
				LDX «data.index»
			«ENDIF»
			INC «data.absolute»«IF data.isIndexed», X«ENDIF»
		«IF data.sizeOf > 1»
			«val labelDone = labelForIncDone»
				BNE +«labelDone»
				INC «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
			+«labelDone»
		«ENDIF»
	'''

	private def incIndirect(CompileData data) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
			INC («data.indirect»), Y
		«IF data.sizeOf > 1»
			«val labelDone = labelForIncDone»
				BNE +«labelDone»
				INY
				INC («data.indirect»), Y
			+«labelDone»
		«ENDIF»
	'''

	private def decAbsolute(CompileData data) '''
		«IF data.isIndexed»
			«noop»
				LDX «data.index»
		«ENDIF»
		«IF data.sizeOf > 1»
			«val labelSkip = labelForDecMSBSkip»
				LDA «data.absolute»«IF data.isIndexed», X«ENDIF»
				BNE +«labelSkip»
				DEC «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
			+«labelSkip»
				DEC «data.absolute»«IF data.isIndexed», X«ENDIF»
		«ELSE»
			«noop»
				DEC «data.absolute»«IF data.isIndexed», X«ENDIF»
		«ENDIF»
	'''

	private def decIndirect(CompileData data) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
		«IF data.sizeOf > 1»
			«val labelSkip = labelForDecMSBSkip»
				LDA («data.indirect»), Y
				BNE +«labelSkip»
				INY
				DEC («data.indirect»), Y
				DEY
			+«labelSkip»
				DEC («data.indirect»), Y
		«ELSE»
			«noop»
				DEC («data.indirect»), Y
		«ENDIF»
	'''

	private def operateImmediate(CompileData data, String instruction) '''
		«noop»
			«instruction» #«data.immediate»
	'''

	private def operateImmediate(CompileData acc, String instruction, CompileData data) '''
		«operateImmediate(acc, instruction, null, data)»
	'''

	private def operateImmediate(CompileData acc, String instruction, String clear, CompileData data) '''
		«IF acc.sizeOf > 1»
			«noop»
				«IF clear !== null»
					«clear»
				«ENDIF»
				«instruction» #<(«data.immediate»)
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					«instruction» #>(«data.immediate»)
			«ELSE»
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					«instruction» «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«noop»
				«IF clear !== null»
					«clear»
				«ENDIF»
				«instruction» #«data.immediate»
		«ENDIF»
	'''

	private def operateAbsolute(CompileData data, String instruction) '''
		«noop»
			«IF data.isIndexed»
				LDX «data.index»
			«ENDIF»
			«instruction» «data.absolute»«IF data.isIndexed», X«ENDIF»
	'''

	private def operateAbsolute(CompileData acc, String instruction, CompileData data) '''
		«operateAbsolute(acc, instruction, null, data)»
	'''

	private def operateAbsolute(CompileData acc, String instruction, String clear, CompileData data) '''
		«noop»
			«IF data.isIndexed»
				LDX «data.index»
			«ENDIF»
			«IF clear !== null»
				«clear»
			«ENDIF»
			«instruction» «data.absolute»«IF data.isIndexed», X«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					PLA
					«instruction» «data.absolute» + 1«IF data.isIndexed», X«ENDIF»
			«ELSE»
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					«instruction» «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def operateIndirect(CompileData data, String instruction) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
			«instruction» «data.indirect», Y
	'''

	private def operateIndirect(CompileData acc, String instruction, CompileData data) '''
		«operateIndirect(acc, instruction, null, data)»
	'''

	private def operateIndirect(CompileData acc, String instruction, String clear, CompileData data) '''
		«noop»
			LDY «IF data.isIndexed»«data.index»«ELSE»#$00«ENDIF»
			«IF clear !== null»
				«clear»
			«ENDIF»
			«instruction» («data.indirect»), Y
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF data.sizeOf > 1»
				«noop»
					INY
					PLA
					«instruction» («data.indirect»), Y
			«ELSE»
				«data.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					«instruction» «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	def loadMSB(CompileData data) '''
		«IF data.type.isSigned»
			«noop»
				«IF data.immediate !== null»
					LDA #«data.immediate»
				«ELSEIF data.absolute !== null»
					LDA «data.absolute»«IF data.isIndexed», X«ENDIF»
				«ELSEIF data.indirect !== null»
					LDA («data.indirect»), Y
				«ENDIF»
			«data.loadMSBFromAcc»
		«ELSE»
			«noop»
				LDA #$00
		«ENDIF»
	'''

	def loadMSBFromAcc(CompileData data) '''
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

	private def labelForIncDone() '''incDone«labelCounter.andIncrement»:'''

	private def labelForDecMSBSkip() '''decMSBSkip«labelCounter.andIncrement»:'''

	private def noop() {
	}
}
