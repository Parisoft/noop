package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.CompileData

class Operations {

	@Inject extension Datas
	@Inject extension Classes

	val labelCounter = new AtomicInteger

	def operateOn(CompileData acc, CompileData operand) {
		switch (acc.operation) {
			case OR: acc.or(operand)
			case AND: acc.and(operand)
			case ADDITION: acc.add(operand)
			case SUBTRACTION: acc.subtract(operand)
			case BIT_OR: acc.bitOr(operand)
			case BIT_AND: acc.bitAnd(operand)
			case BIT_SHIFT_LEFT: acc.bitShiftLeft(operand)
			case BIT_SHIFT_RIGHT: acc.bitShiftRight(operand)
			case INCREMENT: operand.increment
			case DECREMENT: operand.decrement
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

	def or(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			operand.operateImmediate('ORA')
		} else if (operand.absolute !== null) {
			operand.operateAbsolute('ORA')
		} else if (operand.indirect !== null) {
			operand.operateIndirect('ORA')
		}
	}

	def and(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			operand.operateImmediate('AND')
		} else if (operand.absolute !== null) {
			operand.operateAbsolute('AND')
		} else if (operand.indirect !== null) {
			operand.operateIndirect('AND')
		}
	}

	def add(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('ADC', 'CLC', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('ADC', 'CLC', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('ADC', 'CLC', operand)
		}
	}

	def subtract(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('SBC', 'SEC', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('SBC', 'SEC', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('SBC', 'SEC', operand)
		}
	}

	def bitOr(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('ORA', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('ORA', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('ORA', operand)
		}
	}

	def bitShiftLeft(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.bitShiftLeftImmediate(operand)
		} else if (operand.absolute !== null) {
			acc.bitShiftLeftAbsolute(operand)
		} else if (operand.indirect !== null) {
			acc.bitShiftLeftIndirect(operand)
		}
	}
	
	def bitShiftRight(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.bitShiftRightImmediate(operand)
		} else if (operand.absolute !== null) {
			acc.bitShiftRightAbsolute(operand)
		} else if (operand.indirect !== null) {
			acc.bitShiftRightIndirect(operand)
		}
	}
	
	def bitAnd(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('AND', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('AND', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('AND', operand)
		}
	}

	def increment(CompileData operand) {
		if (operand.absolute !== null) {
			operand.incAbsolute
		} else if (operand.indirect !== null) {
			operand.incIndirect
		}
	}

	def decrement(CompileData operand) {
		if (operand.absolute !== null) {
			operand.decAbsolute
		} else if (operand.indirect !== null) {
			operand.decIndirect
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
			EOR #%00000001
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
	
	private def compareEqualsImmediate(CompileData acc, CompileData operand)'''
	'''

	private def bitShiftLeftImmediate(CompileData acc, CompileData operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				LDX #«operand.immediate»
				BEQ +«shiftEnd»
			-«shiftLoop»
				ASL «Members::TEMP_VAR_NAME1»
				ROL A
				DEX
				BNE -«shiftLoop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
			+«shiftEnd»
		«ELSE»
			«val labelLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				LDX #«operand.immediate»
				BEQ +«shiftEnd»
			-«labelLoop»
				ASL A
				DEX
				BNE -«labelLoop»
			+«shiftEnd»
		«ENDIF»
	'''
	
	private def bitShiftLeftAbsolute(CompileData acc, CompileData operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
				LDY «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				BEQ +«shiftEnd»
			-«shiftLoop»
				ASL «Members::TEMP_VAR_NAME1»
				ROL A
				DEY
				BNE -«shiftLoop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
			+«shiftEnd»
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
				LDY «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				BEQ +«shiftEnd»
			-«shiftLoop»
				ASL A
				DEY
				BNE -«shiftLoop»
			+«shiftEnd»
		«ENDIF»
	'''
	
	private def bitShiftLeftIndirect(CompileData acc, CompileData operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				BEQ +«shiftEnd»
				TAX
				PLA
			-«shiftLoop»
				ASL «Members::TEMP_VAR_NAME1»
				ROL A
				DEX
				BNE -«shiftLoop»
				PHA
			+«shiftEnd»
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				BEQ +«shiftEnd»
				TAX
				LDA «Members::TEMP_VAR_NAME1»
			-«shiftLoop»
				ASL A
				DEX
				BNE -«shiftLoop»
			+«shiftEnd»
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''
	private def bitShiftRightImmediate(CompileData acc, CompileData operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				LDX #«operand.immediate»
				BEQ +«shiftEnd»
			-«shiftLoop»
				LSR A
				ROR «Members::TEMP_VAR_NAME1»
				DEX
				BNE -«shiftLoop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
			+«shiftEnd»
		«ELSE»
			«val labelLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				LDX #«operand.immediate»
				BEQ +«shiftEnd»
			-«labelLoop»
				LSR A
				DEX
				BNE -«labelLoop»
			+«shiftEnd»
		«ENDIF»
	'''
	
	private def bitShiftRightAbsolute(CompileData acc, CompileData operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
				LDY «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				BEQ +«shiftEnd»
			-«shiftLoop»
				LSR A
				ROR «Members::TEMP_VAR_NAME1»
				DEY
				BNE -«shiftLoop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
			+«shiftEnd»
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
				LDY «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				BEQ +«shiftEnd»
			-«shiftLoop»
				LSR A
				DEY
				BNE -«shiftLoop»
			+«shiftEnd»
		«ENDIF»
	'''
	
	private def bitShiftRightIndirect(CompileData acc, CompileData operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				BEQ +«shiftEnd»
				TAX
				PLA
			-«shiftLoop»
				LSR A
				ROR «Members::TEMP_VAR_NAME1»
				DEX
				BNE -«shiftLoop»
				PHA
			+«shiftEnd»
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				BEQ +«shiftEnd»
				TAX
				LDA «Members::TEMP_VAR_NAME1»
			-«shiftLoop»
				LSR A
				DEX
				BNE -«shiftLoop»
			+«shiftEnd»
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def incAbsolute(CompileData operand) '''
		«noop»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
			INC «operand.absolute»«IF operand.isIndexed», X«ENDIF»
		«IF operand.sizeOf > 1»
			«val labelDone = labelForIncDone»
				BNE +«labelDone»
				INC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			+«labelDone»
		«ENDIF»
	'''

	private def incIndirect(CompileData operand) '''
		«noop»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			INC («operand.indirect»), Y
		«IF operand.sizeOf > 1»
			«val labelDone = labelForIncDone»
				BNE +«labelDone»
				INY
				INC («operand.indirect»), Y
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

	private def operateImmediate(CompileData operand, String instruction) '''
		«noop»
			«instruction» #«operand.immediate»
	'''

	private def operateImmediate(CompileData acc, String instruction, CompileData operand) '''
		«operateImmediate(acc, instruction, null, operand)»
	'''

	private def operateImmediate(CompileData acc, String instruction, String clear, CompileData operand) '''
		«IF acc.sizeOf > 1»
			«noop»
				«IF clear !== null»
					«clear»
				«ENDIF»
				«instruction» #<(«operand.immediate»)
				STA «Members::TEMP_VAR_NAME1»
			«IF operand.sizeOf > 1»
				«noop»
					PLA
					«instruction» #>(«operand.immediate»)
			«ELSE»
				«operand.loadMSB»
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
				«instruction» #«operand.immediate»
		«ENDIF»
	'''

	private def operateAbsolute(CompileData operand, String instruction) '''
		«noop»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
			«instruction» «operand.absolute»«IF operand.isIndexed», X«ENDIF»
	'''

	private def operateAbsolute(CompileData acc, String instruction, CompileData operand) '''
		«operateAbsolute(acc, instruction, null, operand)»
	'''

	private def operateAbsolute(CompileData acc, String instruction, String clear, CompileData operand) '''
		«noop»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
			«IF clear !== null»
				«clear»
			«ENDIF»
			«instruction» «operand.absolute»«IF operand.isIndexed», X«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF operand.sizeOf > 1»
				«noop»
					PLA
					«instruction» «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSE»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1» + 1
					PLA
					«instruction» «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def operateIndirect(CompileData operand, String instruction) '''
		«noop»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«instruction» «operand.indirect», Y
	'''

	private def operateIndirect(CompileData acc, String instruction, CompileData operand) '''
		«operateIndirect(acc, instruction, null, operand)»
	'''

	private def operateIndirect(CompileData acc, String instruction, String clear, CompileData operand) '''
		«noop»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«IF clear !== null»
				«clear»
			«ENDIF»
			«instruction» («operand.indirect»), Y
		«IF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF operand.sizeOf > 1»
				«noop»
					INY
					PLA
					«instruction» («operand.indirect»), Y
			«ELSE»
				«operand.loadMSB»
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
	
	private def labelForShiftLoop() '''shiftLoop«labelCounter.andIncrement»:'''
	
	private def labelForShiftEnd() '''shiftEnd«labelCounter.andIncrement»:'''

	private def noop() {
	}
}
