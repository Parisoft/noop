package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger

import static extension java.lang.Integer.*
import static extension java.lang.Math.*
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.CompileContext.Operation

class Operations {

	@Inject extension Datas
	@Inject extension Classes

	val labelCounter = new AtomicInteger

	def isComparisonOrMultiplication(Operation operation) {
		switch (operation) {
			case COMPARE_EQ: true
			case COMPARE_NE: true
			case COMPARE_LT: true
			case COMPARE_GE: true
			case MULTIPLICATION: true
			case DIVISION: true
			default: false
		}
	}

	def operateOn(CompileContext acc, CompileContext operand) {
		switch (acc.operation) {
			case OR: acc.or(operand)
			case AND: acc.and(operand)
			case COMPARE_EQ: acc.isEquals(operand)
			case COMPARE_NE: acc.notEquals(operand)
			case COMPARE_LT: acc.lessThan(operand)
			case COMPARE_GE: acc.greaterEqualsThan(operand)
			case ADDITION: acc.add(operand)
			case SUBTRACTION: acc.subtract(operand)
			case MULTIPLICATION: acc.multiply(operand)
			case BIT_OR: acc.bitOr(operand)
			case BIT_AND: acc.bitAnd(operand)
			case BIT_SHIFT_LEFT: acc.bitShiftLeft(operand)
			case BIT_SHIFT_RIGHT: acc.bitShiftRight(operand)
			case INCREMENT: operand.increment
			case DECREMENT: operand.decrement
			default: ''''''
		}
	}

	def operate(CompileContext acc) {
		switch (acc.operation) {
			case BIT_EXCLUSIVE_OR: acc.bitExclusiveOr
			case NEGATION: acc.negate
			case SIGNUM: acc.signum
			default: ''''''
		}
	}

	def or(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			operand.operateImmediate('ORA')
		} else if (operand.absolute !== null) {
			operand.operateAbsolute('ORA')
		} else if (operand.indirect !== null) {
			operand.operateIndirect('ORA')
		}
	}

	def and(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			operand.operateImmediate('AND')
		} else if (operand.absolute !== null) {
			operand.operateAbsolute('AND')
		} else if (operand.indirect !== null) {
			operand.operateIndirect('AND')
		}
	}

	def isEquals(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.equalsImmediate(false, operand)
		} else if (operand.absolute !== null) {
			acc.equalsAbsolute(false, operand)
		} else if (operand.indirect !== null) {
			acc.equalsIndirect(false, operand)
		}
	}

	def notEquals(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.equalsImmediate(true, operand)
		} else if (operand.absolute !== null) {
			acc.equalsAbsolute(true, operand)
		} else if (operand.indirect !== null) {
			acc.equalsIndirect(true, operand)
		}
	}

	def lessThan(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.compareImmediate('BCC', 'BMI', operand)
		} else if (operand.absolute !== null) {
			acc.compareAbsolute('BCC', 'BMI', operand)
		} else if (operand.indirect !== null) {
			acc.compareIndirect('BCC', 'BMI', operand)
		}
	}

	def greaterEqualsThan(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.compareImmediate('BCS', 'BPL', operand)
		} else if (operand.absolute !== null) {
			acc.compareAbsolute('BCS', 'BPL', operand)
		} else if (operand.indirect !== null) {
			acc.compareIndirect('BCS', 'BPL', operand)
		}
	}

	def add(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('ADC', 'CLC', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('ADC', 'CLC', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('ADC', 'CLC', operand)
		}
	}

	def subtract(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('SBC', 'SEC', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('SBC', 'SEC', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('SBC', 'SEC', operand)
		}
	}

	def multiply(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.multiplyImmediate(operand)
		} else if (operand.absolute !== null) {
			acc.multiplyAbsolute(operand)
		} else if (operand.indirect !== null) {
			acc.multiplyIndirect(operand)
		}
	}

	def bitOr(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('ORA', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('ORA', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('ORA', operand)
		}
	}

	def bitShiftLeft(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.bitShiftLeftImmediate(operand)
		} else if (operand.absolute !== null) {
			acc.bitShiftLeftAbsolute(operand)
		} else if (operand.indirect !== null) {
			acc.bitShiftLeftIndirect(operand)
		}
	}

	def bitShiftRight(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.bitShiftRightImmediate(operand)
		} else if (operand.absolute !== null) {
			acc.bitShiftRightAbsolute(operand)
		} else if (operand.indirect !== null) {
			acc.bitShiftRightIndirect(operand)
		}
	}

	def bitAnd(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('AND', operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('AND', operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('AND', operand)
		}
	}

	def increment(CompileContext operand) {
		if (operand.absolute !== null) {
			operand.incAbsolute
		} else if (operand.indirect !== null) {
			operand.incIndirect
		}
	}

	def decrement(CompileContext operand) {
		if (operand.absolute !== null) {
			operand.decAbsolute
		} else if (operand.indirect !== null) {
			operand.decIndirect
		}
	}

	def bitExclusiveOr(CompileContext acc) '''
		«noop»
			EOR #$FF
			«IF acc.sizeOf > 1»
				TAX
				PLA
				EOR #$FF
				PHA
				TXA
			«ENDIF»
	'''

	def negate(CompileContext acc) '''
		«noop»
			«IF acc.relative !== null»
				BEQ +«acc.relative»
			«ELSE»
				EOR #%00000001
			«ENDIF»
	'''

	def signum(CompileContext acc) '''
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

	private def equalsImmediate(CompileContext acc, boolean diff, CompileContext operand) '''
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«val comparisonEnd = labelForComparisonEnd»
		«IF acc.sizeOf > 1 && operand.sizeOf > 1»
			«noop»
				CMP #<(«operand.immediate»)
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				PLA
				CMP #>(«operand.immediate»)
		«ELSEIF acc.sizeOf > 1»
			«noop»
				CMP #(«operand.immediate»)
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«operand.loadMSB»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				CMP «Members::TEMP_VAR_NAME1»
		«ELSEIF operand.sizeOf > 1»
			«noop»
				CMP #<(«operand.immediate»)
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«acc.loadMSB»
				CMP #>(«operand.immediate»)
		«ELSE»
			«noop»
				CMP #(«operand.immediate»)
		«ENDIF»
		«IF acc.relative === null»
			«noop»
				B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def equalsAbsolute(CompileContext acc, boolean diff, CompileContext operand) '''
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«val comparisonEnd = labelForComparisonEnd»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
			CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
		«IF acc.sizeOf > 1 && operand.sizeOf > 1»
			«noop»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				PLA
				CMP «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
		«ELSEIF acc.sizeOf > 1»
			«noop»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«operand.loadMSB»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				CMP «Members::TEMP_VAR_NAME1»
		«ELSEIF operand.sizeOf > 1»
			«noop»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«acc.loadMSB»
				CMP «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
		«ENDIF»
		«IF acc.relative === null»
			«noop»
				B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def equalsIndirect(CompileContext acc, boolean diff, CompileContext operand) '''
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«val comparisonEnd = labelForComparisonEnd»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			CMP («operand.indirect»), Y
		«IF acc.sizeOf > 1 && operand.sizeOf > 1»
			«noop»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				PLA
				INY
				CMP («operand.indirect»), Y
		«ELSEIF acc.sizeOf > 1»
			«noop»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«operand.loadMSB»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				CMP «Members::TEMP_VAR_NAME1»
		«ELSEIF operand.sizeOf > 1»
			«noop»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«acc.loadMSB»
				INY
				CMP («operand.indirect»), Y
		«ENDIF»
		«IF acc.relative === null»
			«noop»
				B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def compareImmediate(CompileContext acc, String ubranch, String sbranch, CompileContext operand) '''
		«var branch = ubranch»
		«val comparison = labelForComparison»
		«val comparisonEnd = labelForComparisonEnd»
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«IF acc.type.isSigned && operand.type.isSigned»
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					CMP #<(«operand.immediate»)
					PLA
					SBC #>(«operand.immediate»)
			«ELSEIF acc.sizeOf > 1»
				«noop»
					CMP #(«operand.immediate»)
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					SBC «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«noop»
					CMP #<(«operand.immediate»)
				«acc.loadMSB»
					SBC #>(«operand.immediate»)
			«ELSE»
				«noop»
					SEC
					SBC #(«operand.immediate»)
			«ENDIF»
			«branch = sbranch»
				BVC +«comparison»
				EOR #$80
			+«comparison»:
		«ELSE»
			«IF acc.type.isUnsigned && operand.type.isSigned»
				«IF operand.sizeOf > 1»
					«noop»
						LDY #>(«operand.immediate»)
						BMI  +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ELSE»
					«noop»
						LDY #(«operand.immediate»)
						BMI +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
			«ELSEIF acc.type.isSigned && operand.type.isUnsigned»
				«IF acc.sizeOf > 1»
					«noop»
						TAY
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PHA
						TYA
				«ELSE»
					«noop»
						TAY
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
			«ENDIF»
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					CMP #<(«operand.immediate»)
					PLA
					SBC #>«operand.immediate»
			«ELSEIF acc.sizeOf > 1»
				«noop»
					CMP #(«operand.immediate»)
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					SBC «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«noop»
					CMP #<(«operand.immediate»)
				«acc.loadMSB»
					SBC #>«operand.immediate»
			«ELSE»
				«noop»
					CMP #(«operand.immediate»)
			«ENDIF»
		«ENDIF»
		«IF acc.relative === null»
			«noop»
				«branch» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				«branch» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def compareAbsolute(CompileContext acc, String ubranch, String sbranch, CompileContext operand) '''
		«var branch = ubranch»
		«val comparison = labelForComparison»
		«val comparisonEnd = labelForComparisonEnd»
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«IF acc.type.isSigned && operand.type.isSigned»
			«noop»
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
					PLA
					SBC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSEIF acc.sizeOf > 1»
				«noop»
					CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					SBC «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«noop»
					CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				«acc.loadMSB»
					SBC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSE»
				«noop»
					SEC
					SBC «operand.absolute»«IF operand.isIndexed», X«ENDIF»
			«ENDIF»
			«branch = sbranch»
				BVC +«comparison»
				EOR #$80
			+«comparison»:
		«ELSE»
			«noop»
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
			«IF acc.type.isUnsigned && operand.type.isSigned»
				«IF operand.sizeOf > 1»
					«noop»
						LDY «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
						BMI +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ELSE»
					«noop»
						LDY «operand.absolute»«IF operand.isIndexed», X«ENDIF»
						BMI +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
			«ELSEIF acc.type.isSigned && operand.type.isUnsigned»
				«IF acc.sizeOf > 1»
					«noop»
						TAY
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PHA
						TYA
				«ELSE»
					«noop»
						TAY
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
			«ENDIF»
			«noop»
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					PLA
					SBC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					SBC «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					SBC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ENDIF»
		«ENDIF»
		«IF acc.relative === null»
			«noop»
				«branch» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				«branch» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def compareIndirect(CompileContext acc, String ubranch, String sbranch, CompileContext operand) '''
		«var branch = ubranch»
		«val comparison = labelForComparison»
		«val comparisonEnd = labelForComparisonEnd»
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«IF acc.type.isSigned && operand.type.isSigned»
			«noop»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					CMP («operand.indirect»), Y
					PLA
					INY
					SBC («operand.indirect»), Y
			«ELSEIF acc.sizeOf > 1»
				«noop»
					CMP («operand.indirect»), Y
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					SBC «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«noop»
					CMP («operand.indirect»), Y
				«acc.loadMSB»
					INY
					SBC («operand.indirect»), Y
			«ELSE»
				«noop»
					SEC
					SBC («operand.indirect»), Y
			«ENDIF»
			«branch = sbranch»
				BVC +«comparison»
				EOR #$80
			+«comparison»:
		«ELSE»
			«IF acc.type.isUnsigned && operand.type.isSigned»
				«IF operand.sizeOf > 1»
					«noop»
						«IF operand.isIndexed»
							LDY «operand.index»
							INY
						«ELSE»
							LDY #$01
						«ENDIF»
						TAX
						LDA («operand.indirect»), Y
						BMI +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						TXA
						DEY
				«ELSE»
					«noop»
						LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
						TAX
						LDA («operand.indirect»), Y
						BMI +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						TXA
				«ENDIF»
			«ELSEIF acc.type.isSigned && operand.type.isUnsigned»
				«IF acc.sizeOf > 1»
					«noop»
						TAX
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PHA
						TXA
				«ELSE»
					«noop»
						TAX
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
				«noop»
					LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«ELSE»
				«noop»
					LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«ENDIF»
			«noop»
				CMP («operand.indirect»), Y
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					PLA
					INY
					SBC («operand.indirect»), Y
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					SBC «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					INY
					SBC («operand.indirect»), Y
			«ENDIF»
			«IF acc.relative === null»
				«noop»
					«branch» +«comparisonIsTrue»
				+«comparisonIsFalse»:
					LDA #«Members::FALSE»
					JMP +«comparisonEnd»
				+«comparisonIsTrue»:
					LDA #«Members::TRUE»
				+«comparisonEnd»:
			«ELSE»
				«noop»
					«branch» +«acc.relative»
				+«comparisonIsFalse»:
			«ENDIF»
		«ENDIF»
	'''

	private def bitShiftLeftImmediate(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				LDX #(«operand.immediate»)
				BEQ +«shiftEnd»
			-«shiftLoop»:
				ASL «Members::TEMP_VAR_NAME1»
				ROL A
				DEX
				BNE -«shiftLoop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
			+«shiftEnd»:
		«ELSE»
			«val labelLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				LDX #(«operand.immediate»)
				BEQ +«shiftEnd»
			-«labelLoop»:
				ASL A
				DEX
				BNE -«labelLoop»
			+«shiftEnd»:
		«ENDIF»
	'''

	private def bitShiftLeftAbsolute(CompileContext acc, CompileContext operand) '''
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
			-«shiftLoop»:
				ASL «Members::TEMP_VAR_NAME1»
				ROL A
				DEY
				BNE -«shiftLoop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
			+«shiftEnd»:
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
				LDY «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				BEQ +«shiftEnd»
			-«shiftLoop»:
				ASL A
				DEY
				BNE -«shiftLoop»
			+«shiftEnd»:
		«ENDIF»
	'''

	private def bitShiftLeftIndirect(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				BEQ +«shiftEnd»
				TAX
				PLA
			-«shiftLoop»:
				ASL «Members::TEMP_VAR_NAME1»
				ROL A
				DEX
				BNE -«shiftLoop»
				PHA
			+«shiftEnd»:
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
			-«shiftLoop»:
				ASL A
				DEX
				BNE -«shiftLoop»
			+«shiftEnd»:
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def bitShiftRightImmediate(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				LDX #(«operand.immediate»)
				BEQ +«shiftEnd»
			-«shiftLoop»:
				LSR A
				ROR «Members::TEMP_VAR_NAME1»
				DEX
				BNE -«shiftLoop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
			+«shiftEnd»:
		«ELSE»
			«val labelLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				LDX #(«operand.immediate»)
				BEQ +«shiftEnd»
			-«labelLoop»:
				LSR A
				DEX
				BNE -«labelLoop»
			+«shiftEnd»:
		«ENDIF»
	'''

	private def bitShiftRightAbsolute(CompileContext acc, CompileContext operand) '''
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
			-«shiftLoop»:
				LSR A
				DEY
				BNE -«shiftLoop»
			+«shiftEnd»:
		«ENDIF»
	'''

	private def bitShiftRightIndirect(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				BEQ +«shiftEnd»
				TAX
				PLA
			-«shiftLoop»:
				LSR A
				ROR «Members::TEMP_VAR_NAME1»
				DEX
				BNE -«shiftLoop»
				PHA
			+«shiftEnd»:
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
			-«shiftLoop»:
				LSR A
				DEX
				BNE -«shiftLoop»
			+«shiftEnd»:
				LDA «Members::TEMP_VAR_NAME1»
		«ENDIF»
	'''

	private def incAbsolute(CompileContext operand) '''
		«noop»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
			INC «operand.absolute»«IF operand.isIndexed», X«ENDIF»
		«IF operand.sizeOf > 1»
			«val labelDone = labelForIncDone»
				BNE +«labelDone»
				INC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			+«labelDone»:
		«ENDIF»
	'''

	private def incIndirect(CompileContext operand) '''
		«noop»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			INC («operand.indirect»), Y
		«IF operand.sizeOf > 1»
			«val labelDone = labelForIncDone»
				BNE +«labelDone»
				INY
				INC («operand.indirect»), Y
			+«labelDone»:
		«ENDIF»
	'''

	private def decAbsolute(CompileContext ctx) '''
		«IF ctx.isIndexed»
			«noop»
				LDX «ctx.index»
		«ENDIF»
		«IF ctx.sizeOf > 1»
			«val labelSkip = labelForDecMSBSkip»
				LDA «ctx.absolute»«IF ctx.isIndexed», X«ENDIF»
				BNE +«labelSkip»
				DEC «ctx.absolute» + 1«IF ctx.isIndexed», X«ENDIF»
			+«labelSkip»:
				DEC «ctx.absolute»«IF ctx.isIndexed», X«ENDIF»
		«ELSE»
			«noop»
				DEC «ctx.absolute»«IF ctx.isIndexed», X«ENDIF»
		«ENDIF»
	'''

	private def decIndirect(CompileContext ctx) '''
		«noop»
			LDY «IF ctx.isIndexed»«ctx.index»«ELSE»#$00«ENDIF»
		«IF ctx.sizeOf > 1»
			«val labelSkip = labelForDecMSBSkip»
				LDA («ctx.indirect»), Y
				BNE +«labelSkip»
				INY
				DEC («ctx.indirect»), Y
				DEY
			+«labelSkip»:
				DEC («ctx.indirect»), Y
		«ELSE»
			«noop»
				DEC («ctx.indirect»), Y
		«ENDIF»
	'''

	private def multiplyImmediate(CompileContext multiplicand, CompileContext multiplier) '''
		«val const = multiplier.immediate.valueOf»
		«val ONE = '1'.charAt(0)»
		«val bits = const.abs.toBinaryString.toCharArray.reverse»
		«IF multiplicand.sizeOf > 1»
			«IF const === 0»
				«noop»
					PLA
					LDA #$00
					PHA
			«ELSEIF const.abs > 1 && bits.filter[it == ONE].size == 1»
				«noop»
					TAX
					PLA
					TAY
					«FOR i : 0..< bits.indexOf(ONE)»
						TXA
						ASL A
						TAX
						TYA
						ROL A
						«IF i < bits.indexOf(ONE) - 1»
							TAY
						«ENDIF»
					«ENDFOR»
					PHA
					TXA
			«ELSEIF const.abs > 1»
				«var lastPower = new AtomicInteger»
					TAX
					PLA
					TAY
				«FOR i : 0..< bits.size»
					«IF bits.get(i) == ONE»
						«noop»
							«FOR pow : 0..< i - lastPower.get»
								TXA
								ASL A
								TAX
								TYA
								ROL A
								TAY
							«ENDFOR»
							«IF i == 0 || lastPower.get == 0 && bits.head != ONE»
								STX «Members::TEMP_VAR_NAME1»
								STA «Members::TEMP_VAR_NAME1» + 1
							«ELSEIF i == bits.size - 1»
								CLC
								TXA
								ADC «Members::TEMP_VAR_NAME1»
								TAX
								TYA
								ADC «Members::TEMP_VAR_NAME1» + 1
								PHA
								TXA
							«ELSE»
								CLC
								TXA
								ADC «Members::TEMP_VAR_NAME1»
								STA «Members::TEMP_VAR_NAME1»
								TYA
								ADC «Members::TEMP_VAR_NAME1» + 1
								STA «Members::TEMP_VAR_NAME1» + 1
							«ENDIF»
						«lastPower.set(i)»
					«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ELSE»
			«IF const === 0»
				«noop»
					LDA #$00
			«ELSEIF const.abs > 1 && bits.filter[it == ONE].size == 1»
				«noop»
					«FOR i : 0..< bits.indexOf(ONE)»
						ASL A
					«ENDFOR»
			«ELSEIF const.abs > 1»
				«var lastPower = new AtomicInteger»
				«FOR i : 0..< bits.size»
					«IF bits.get(i) == ONE»
						«noop»
							«FOR pow : 0..< i - lastPower.get»
								ASL A
							«ENDFOR»
							«IF i == 0 || lastPower.get == 0 && bits.head != ONE»
								STA «Members::TEMP_VAR_NAME1»
							«ELSEIF i == bits.size - 1»
								CLC
								ADC «Members::TEMP_VAR_NAME1»
							«ELSE»
								TAX
								CLC
								ADC «Members::TEMP_VAR_NAME1»
								STA «Members::TEMP_VAR_NAME1»
								TXA
							«ENDIF»
						«lastPower.set(i)»
					«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ENDIF»
		«IF const < 0»
			«multiplicand.signum»
		«ENDIF»
	'''

	private def multiplyAbsolute(CompileContext multiplicand, CompileContext multiplier) '''
		
	'''

	private def multiplyIndirect(CompileContext multiplicand, CompileContext multiplier) '''
		
	'''

	private def operateImmediate(CompileContext operand, String instruction) '''
		«noop»
			«instruction» #(«operand.immediate»)
	'''

	private def operateImmediate(CompileContext acc, String instruction, CompileContext operand) '''
		«operateImmediate(acc, instruction, null, operand)»
	'''

	private def operateImmediate(CompileContext acc, String instruction, String clear, CompileContext operand) '''
		«IF acc.sizeOfOp > 1»
			«noop»
				«IF clear !== null»
					«clear»
				«ENDIF»
				«instruction» #<(«operand.immediate»)
				TAX
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					PLA
					«instruction» #>(«operand.immediate»)
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					«instruction» «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					«instruction» #>(«operand.immediate»)
			«ELSE»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
				«acc.loadMSB»
					«instruction» «Members::TEMP_VAR_NAME1»
			«ENDIF»
			«noop»
				PHA
				TXA
		«ELSE»
			«noop»
				«IF clear !== null»
					«clear»
				«ENDIF»
				«instruction» #(«operand.immediate»)
		«ENDIF»
	'''

	private def operateAbsolute(CompileContext operand, String instruction) '''
		«noop»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
			«instruction» «operand.absolute»«IF operand.isIndexed», X«ENDIF»
	'''

	private def operateAbsolute(CompileContext acc, String instruction, CompileContext operand) '''
		«operateAbsolute(acc, instruction, null, operand)»
	'''

	private def operateAbsolute(CompileContext acc, String instruction, String clear, CompileContext operand) '''
		«noop»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
			«IF clear !== null»
				«clear»
			«ENDIF»
			«instruction» «operand.absolute»«IF operand.isIndexed», X«ENDIF»
		«IF acc.sizeOfOp > 1»
			«noop»
				TAY
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					PLA
					«instruction» «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					«instruction» «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					«instruction» «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSE»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
				«acc.loadMSB»
					«instruction» «Members::TEMP_VAR_NAME1»
			«ENDIF»
			«noop»
				PHA
				TYA
		«ENDIF»
	'''

	private def operateIndirect(CompileContext operand, String instruction) '''
		«noop»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«instruction» «operand.indirect», Y
	'''

	private def operateIndirect(CompileContext acc, String instruction, CompileContext operand) '''
		«operateIndirect(acc, instruction, null, operand)»
	'''

	private def operateIndirect(CompileContext acc, String instruction, String clear, CompileContext operand) '''
		«noop»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«IF clear !== null»
				«clear»
			«ENDIF»
			«instruction» («operand.indirect»), Y
		«IF acc.sizeOfOp > 1»
			«noop»
				TAX
			«IF acc.sizeOf > 1 && operand.sizeOf > 1»
				«noop»
					INY
					PLA
					«instruction» («operand.indirect»), Y
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					«instruction» «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					«instruction» («operand.indirect»), Y
			«ELSE»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
				«acc.loadMSB»
					«instruction» «Members::TEMP_VAR_NAME1»
			«ENDIF»
			«noop»
				PHA
				TXA
		«ENDIF»
	'''

	def loadMSB(CompileContext ctx) '''
		«IF ctx.type.isSigned»
			«noop»
				«IF ctx.immediate !== null»
					LDA #(«ctx.immediate»)
				«ELSEIF ctx.absolute !== null»
					LDA «ctx.absolute»«IF ctx.isIndexed», X«ENDIF»
				«ELSEIF ctx.indirect !== null»
					LDA («ctx.indirect»), Y
				«ENDIF»
			«ctx.loadMSBFromAcc»
		«ELSE»
			«noop»
				LDA #$00
		«ENDIF»
	'''

	def loadMSBFromAcc(CompileContext acc) '''
		«IF acc.type.isSigned»
			«val signLabel = labelForSignedMSBEnd»
				ORA #$7F
				BMI +«signLabel»
				LDA #$00
			+«signLabel»:
		«ELSE»
			«noop»
				LDA #$00
		«ENDIF»
	'''

	private def labelForSignedMSBEnd() '''signedMSBEnd«labelCounter.andIncrement»'''

	private def labelForIncDone() '''incDone«labelCounter.andIncrement»'''

	private def labelForDecMSBSkip() '''decMSBSkip«labelCounter.andIncrement»'''

	private def labelForShiftLoop() '''shiftLoop«labelCounter.andIncrement»'''

	private def labelForShiftEnd() '''shiftEnd«labelCounter.andIncrement»'''

	private def labelForComparison() '''comparison«labelCounter.andIncrement»'''

	private def labelForComparisonIsTrue() '''comparisonIsTrue«labelCounter.andIncrement»'''

	private def labelForComparisonIsFalse() '''comparisonIsFalse«labelCounter.andIncrement»'''

	private def labelForComparisonEnd() '''comparisonEnd«labelCounter.andIncrement»'''

	private def void noop() {
	}
}
