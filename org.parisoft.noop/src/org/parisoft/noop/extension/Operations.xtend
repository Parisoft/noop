package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.CompileData

class Operations {

	@Inject extension Datas
	@Inject extension Classes

	val labelCounter = new AtomicInteger

	def operateOn(CompileData acc, CompileData data) {
		switch (acc.operation) {
			case OR: acc.or(data)
			case AND: acc.and(data)
			case ADDITION: acc.add(data)
			case SUBTRACTION: acc.subtract(data)
			case BIT_OR: acc.bitOr(data)
			case BIT_AND: acc.bitAnd(data)
			case INCREMENT: data.increment
			case DECREMENT: data.decrement
			default: ''''''
		}
	}

	def operate(CompileData acc) {
		switch (acc.operation) {
			case BIT_EXCLUSIVE_OR: acc.bitExclusiveOr
			case NEGATION: acc.negate
			case SIGNUM: acc.signum
			default: ''''''
		}
	}

	def or(CompileData acc, CompileData data) {
		if (data.immediate !== null) {
			data.operateImmediate('ORA')
		} else if (data.absolute !== null) {
			data.operateAbsolute('ORA')
		} else if (data.indirect !== null) {
			data.operateIndirect('ORA')
		}
	}

	def and(CompileData acc, CompileData data) {
		if (data.immediate !== null) {
			data.operateImmediate('AND')
		} else if (data.absolute !== null) {
			data.operateAbsolute('AND')
		} else if (data.indirect !== null) {
			data.operateIndirect('AND')
		}
	}

	def add(CompileData acc, CompileData data) {
		if (data.immediate !== null) {
			acc.operateImmediate('ADC', 'CLC', data)
		} else if (data.absolute !== null) {
			acc.operateAbsolute('ADC', 'CLC', data)
		} else if (data.indirect !== null) {
			acc.operateIndirect('ADC', 'CLC', data)
		}
	}

	def subtract(CompileData acc, CompileData data) {
		if (data.immediate !== null) {
			acc.operateImmediate('SBC', 'SEC', data)
		} else if (data.absolute !== null) {
			acc.operateAbsolute('SBC', 'SEC', data)
		} else if (data.indirect !== null) {
			acc.operateIndirect('SBC', 'SEC', data)
		}
	}

	def bitOr(CompileData acc, CompileData data) {
		if (data.immediate !== null) {
			acc.operateImmediate('ORA', data)
		} else if (data.absolute !== null) {
			acc.operateAbsolute('ORA', data)
		} else if (data.indirect !== null) {
			acc.operateIndirect('ORA', data)
		}
	}

	def bitAnd(CompileData acc, CompileData data) {
		if (data.immediate !== null) {
			acc.operateImmediate('AND', data)
		} else if (data.absolute !== null) {
			acc.operateAbsolute('AND', data)
		} else if (data.indirect !== null) {
			acc.operateIndirect('AND', data)
		}
	}

	def increment(CompileData data) {
		if (data.absolute !== null) {
			data.incAbsolute
		} else if (data.indirect !== null) {
			data.incIndirect
		}
	}

	def decrement(CompileData data) {
		if (data.absolute !== null) {
			data.decAbsolute
		} else if (data.indirect !== null) {
			data.decIndirect
		}
	}

	def bitExclusiveOr(CompileData acc) '''
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

	def negate(CompileData acc) '''
		«noop»
			EOR #$FF
	'''

	def signum(CompileData acc) '''
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

	def loadMSBFromAcc(CompileData acc) '''
		«IF acc.type.isSigned»
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
