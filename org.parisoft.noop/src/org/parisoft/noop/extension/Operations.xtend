package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger

import static extension java.lang.Integer.*
import static extension java.lang.Math.*
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.CompileContext.Operation
import java.util.concurrent.atomic.AtomicReference

class Operations {

	@Inject extension Datas
	@Inject extension Classes

	def isComparison(Operation operation) {
		switch (operation) {
			case COMPARE_EQ: true
			case COMPARE_NE: true
			case COMPARE_LT: true
			case COMPARE_GE: true
			default: false
		}
	}

	def isDivision(Operation operation) {
		switch (operation) {
			case DIVISION: true
			case BIT_SHIFT_RIGHT: true
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
			case DIVISION: acc.divide(operand)
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

	def divide(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.divideImmediate(operand)
		}
	}

	def bitOr(CompileContext acc, CompileContext operand) {
		if (operand.immediate !== null) {
			acc.operateImmediate('ORA', null, operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('ORA', null, operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('ORA', null, operand)
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
			acc.operateImmediate('AND', null, operand)
		} else if (operand.absolute !== null) {
			acc.operateAbsolute('AND', null, operand)
		} else if (operand.indirect !== null) {
			acc.operateIndirect('AND', null, operand)
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
				TAX
				PLA
				CPX #<(«operand.immediate»)
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				CMP #>(«operand.immediate»)
		«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
			«noop»
				TAX
				PLA
				CPX #(«operand.immediate»)
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				CMP #$00
		«ELSEIF acc.sizeOf > 1»
			«noop»
				TAX
				PLA
				CPX #(«operand.immediate»)
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				STA «Members::TEMP_VAR_NAME1»
			«operand.loadMSB»
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
		«IF acc.sizeOf > 1 && operand.sizeOf > 1»
			«noop»
				TAY
				PLA
				CMP «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				TYA
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
		«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
			«noop»
				TAY
				PLA
				CMP #$00
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				TYA
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
		«ELSEIF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				STA «Members::TEMP_VAR_NAME1» + 1
				LDA «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				CMP «Members::TEMP_VAR_NAME1»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«operand.loadMSB»
				CMP «Members::TEMP_VAR_NAME1» + 1
		«ELSEIF operand.sizeOf > 1»
			«noop»
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«acc.loadMSB»
				CMP «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
		«ELSE»
			«noop»
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
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
		«IF acc.sizeOf > 1 && operand.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				STA «Members::TEMP_VAR_NAME1» + 1
				LDA («operand.indirect»), Y
				CMP «Members::TEMP_VAR_NAME1»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
				INY
				LDA («operand.indirect»), Y
				CMP «Members::TEMP_VAR_NAME1» + 1
		«ELSEIF acc.sizeOf > 1»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
				PLA
				STA «Members::TEMP_VAR_NAME1» + 1
				LDA («operand.indirect»), Y
				CMP «Members::TEMP_VAR_NAME1»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«operand.loadMSB»
				CMP «Members::TEMP_VAR_NAME1» + 1
		«ELSEIF operand.sizeOf > 1»
			«noop»
				CMP («operand.indirect»), Y
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«acc.loadMSB»
				INY
				CMP («operand.indirect»), Y
		«ELSE»
			«noop»
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
		«var branch = new AtomicReference(ubranch)»
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					CMP #(«operand.immediate»)
					PLA
					SBC #$00
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
			«branch.set(sbranch)»
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					CMP #(«operand.immediate»)
					PLA
					SBC #$00
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
				«branch.get» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				«branch.get» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def compareAbsolute(CompileContext acc, String ubranch, String sbranch, CompileContext operand) '''
		«var branch = new AtomicReference(ubranch)»
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
					PLA
					SBC #$00
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
			«branch.set(sbranch)»
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					PLA
					SBC #$00
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
				«branch.get» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				«branch.get» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def compareIndirect(CompileContext acc, String ubranch, String sbranch, CompileContext operand) '''
		«var branch = new AtomicReference(ubranch)»
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					CMP («operand.indirect»), Y
					PLA
					SBC #$00
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
			«branch.set(sbranch)»
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					PLA
					SBC #$00
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
		«ENDIF»
		«IF acc.relative === null»
			«noop»
				«branch.get» +«comparisonIsTrue»
			+«comparisonIsFalse»:
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»:
				LDA #«Members::TRUE»
			+«comparisonEnd»:
		«ELSE»
			«noop»
				«branch.get» +«acc.relative»
			+«comparisonIsFalse»:
		«ENDIF»
	'''

	private def bitShiftLeftImmediate(CompileContext acc, CompileContext operand) '''
		«val shift = operand.immediate.parseInt.bitwiseAnd((operand.sizeOf * 8) - 1)»
		«IF acc.sizeOfOp > 1 && shift != 0»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF acc.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«acc.loadMSB»
			«ENDIF»
			«FOR i : 0..< shift»
				«noop»
					ASL «Members::TEMP_VAR_NAME1»
					ROL A
			«ENDFOR»
			«noop»
				PHA
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«FOR i : 0..< shift»
				«noop»
					ASL A
			«ENDFOR»
		«ENDIF»
	'''

	private def bitShiftLeftAbsolute(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOfOp > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
				LDA «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				AND #«(operand.sizeOf * 8) - 1»
				BEQ +«shiftEnd»
				TAY
			«IF acc.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«acc.loadMSB»
			«ENDIF»
			-«shiftLoop»:
				ASL «Members::TEMP_VAR_NAME1»
				ROL A
				DEY
				BNE -«shiftLoop»
				PHA
			+«shiftEnd»:
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				«IF operand.isIndexed»
					LDX «operand.index»
					STA «Members::TEMP_VAR_NAME1»
				«ELSE»
					TAX
				«ENDIF»
				LDA «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				AND #«(operand.sizeOf * 8) - 1»
				TAY
				«IF operand.isIndexed»
					LDA «Members::TEMP_VAR_NAME1»
				«ELSE»
					TXA
				«ENDIF»
				CPY #$00
				BEQ +«shiftEnd»
			-«shiftLoop»:
				ASL A
				DEY
				BNE -«shiftLoop»
			+«shiftEnd»:
		«ENDIF»
	'''

	private def bitShiftLeftIndirect(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOfOp > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				AND #«(operand.sizeOf * 8) - 1»
				BEQ +«shiftEnd»
				TAX
			«IF acc.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«acc.loadMSB»
			«ENDIF»
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
				AND #«(operand.sizeOf * 8) - 1»
				TAX
				LDA «Members::TEMP_VAR_NAME1»
				CPX #$00
				BEQ +«shiftEnd»
			-«shiftLoop»:
				ASL A
				DEX
				BNE -«shiftLoop»
			+«shiftEnd»:
		«ENDIF»
	'''

	private def bitShiftRightImmediate(CompileContext acc, CompileContext operand) '''
		«val shift = operand.immediate.parseInt.bitwiseAnd((operand.sizeOf * 8) - 1)»
		«IF (acc.sizeOfOp > 1 || acc.sizeOf > 1) && shift != 0»
			«noop»
				STA «Members::TEMP_VAR_NAME1»
			«IF acc.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«acc.loadMSB»
			«ENDIF»
			«IF acc.type.isUnsigned»
				«noop»
					«FOR i : 0..< shift»
						LSR A
						ROR «Members::TEMP_VAR_NAME1»
					«ENDFOR»
			«ELSE»
				«noop»
					STA «Members::TEMP_VAR_NAME1» + 1
					«FOR i : 0..< shift»
						«IF i > 0»
							LDA «Members::TEMP_VAR_NAME1» + 1
						«ENDIF»
						ASL A
						ROR «Members::TEMP_VAR_NAME1» + 1
						ROR «Members::TEMP_VAR_NAME1»
					«ENDFOR»
					«IF acc.sizeOfOp > 1»
						LDA «Members::TEMP_VAR_NAME1» + 1
					«ENDIF»
			«ENDIF»
			«noop»
				«IF acc.sizeOfOp > 1»
					PHA
				«ENDIF»
				LDA «Members::TEMP_VAR_NAME1»
		«ELSEIF acc.type.isUnsigned»
			«FOR i : 0..< shift»
				«noop»
					CMP #$80
					ROR A
			«ENDFOR»
		«ELSE»
			«FOR i : 0..< shift»
				«noop»
					LSR A
			«ENDFOR»
		«ENDIF»
	'''

	private def bitShiftRightAbsolute(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOfOp > 1 || acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				«IF operand.isIndexed»
					LDX «operand.index»
				«ENDIF»
				LDA «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				AND #«(operand.sizeOf * 8) - 1»
				BEQ +«shiftEnd»
				TAY
			«IF acc.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«acc.loadMSB»
			«ENDIF»
			«IF acc.type.isSigned»
				«noop»
					STA «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			-«shiftLoop»:
				«IF acc.type.isSigned»
					ASL A
					ROR «Members::TEMP_VAR_NAME1» + 1
					ROR «Members::TEMP_VAR_NAME1»
					LDA «Members::TEMP_VAR_NAME1» + 1
				«ELSE»
					LSR A
					ROR «Members::TEMP_VAR_NAME1»
				«ENDIF»
				DEY
				BNE -«shiftLoop»
				«IF acc.sizeOfOp > 1»
					PHA
				«ENDIF»
			+«shiftEnd»:
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				«IF operand.isIndexed»
					LDX «operand.index»
					STA «Members::TEMP_VAR_NAME1»
				«ELSE»
					TAX
				«ENDIF»
				LDA «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				AND #«(operand.sizeOf * 8) - 1»
				TAY
				«IF operand.isIndexed»
					LDA «Members::TEMP_VAR_NAME1»
				«ELSE»
					TXA
				«ENDIF»
				CPY #$00
				BEQ +«shiftEnd»
			-«shiftLoop»:
				«IF acc.type.isUnsigned»
					LSR A
				«ELSE»
					CMP #$80
					ROR A
				«ENDIF»
				DEY
				BNE -«shiftLoop»
			+«shiftEnd»:
		«ENDIF»
	'''

	private def bitShiftRightIndirect(CompileContext acc, CompileContext operand) '''
		«IF acc.sizeOfOp > 1 || acc.sizeOf > 1»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				AND #«(operand.sizeOf * 8) - 1»
				BEQ +«shiftEnd»
				TAX
			«IF acc.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«acc.loadMSB»
			«ENDIF»
			«IF acc.type.isSigned»
				«noop»
					STA «Members::TEMP_VAR_NAME1» + 1
			«ENDIF»
			-«shiftLoop»:
				«IF acc.type.isSigned»
					ASL A
					ROR «Members::TEMP_VAR_NAME1» + 1
					ROR «Members::TEMP_VAR_NAME1»
					LDA «Members::TEMP_VAR_NAME1» + 1
				«ELSE»
					LSR A
					ROR «Members::TEMP_VAR_NAME1»
				«ENDIF»
				DEX
				BNE -«shiftLoop»
				«IF acc.sizeOfOp > 1»
					PHA
				«ENDIF»
			+«shiftEnd»:
				LDA «Members::TEMP_VAR_NAME1»
		«ELSE»
			«val shiftLoop = labelForShiftLoop»
			«val shiftEnd = labelForShiftEnd»
				STA «Members::TEMP_VAR_NAME1»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
				LDA («operand.indirect»), Y
				AND #«(operand.sizeOf * 8) - 1»
				TAX
				LDA «Members::TEMP_VAR_NAME1»
				CPX #$00
				BEQ +«shiftEnd»
			-«shiftLoop»:
				«IF acc.type.isUnsigned»
					LSR A
				«ELSE»
					CMP #$80
					ROR A
				«ENDIF»
				DEX
				BNE -«shiftLoop»
			+«shiftEnd»:
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
		«val one = '1'.charAt(0)»
		«val bits = const.abs.toBinaryString.toCharArray.reverse»
		«IF multiplicand.sizeOfOp > 1»
			«IF const === 0»
				«noop»
					«IF multiplicand.sizeOf > 1»
						PLA
					«ENDIF»
					LDA #$00
					PHA
			«ELSEIF const.abs > 1 && bits.filter[it == one].size == 1»
				«noop»
					STA «Members::TEMP_VAR_NAME1»
				«IF multiplicand.sizeOf > 1»
					«noop»
						PLA
				«ELSE»
					«multiplicand.loadMSB»
				«ENDIF»
				«noop»
					«FOR i : 0..< bits.indexOf(one)»
						ASL «Members::TEMP_VAR_NAME1»
						ROL A
					«ENDFOR»
					PHA
					LDA «Members::TEMP_VAR_NAME1»
			«ELSEIF const.abs > 1»
				«var lastPower = new AtomicInteger»
					STA «Members::TEMP_VAR_NAME1»
				«IF multiplicand.sizeOf > 1»
					«noop»
						PLA
				«ELSE»
					«multiplicand.loadMSB»
				«ENDIF»
				«noop»
					STA «Members::TEMP_VAR_NAME1» + 1
					LDA «Members::TEMP_VAR_NAME1»
				«FOR i : 0..< bits.size»
					«IF bits.get(i) == one»
						«noop»
							«FOR pow : 0..< i - lastPower.get»
								ASL A
								ROL «Members::TEMP_VAR_NAME1» + 1
							«ENDFOR»
							«IF i == 0 || lastPower.get == 0 && bits.head != one»
								STA «Members::TEMP_VAR_NAME3»
								LDX «Members::TEMP_VAR_NAME1» + 1
								STX «Members::TEMP_VAR_NAME3» + 1
							«ELSEIF i < bits.size - 1»
								CLC
								TAX
								ADC «Members::TEMP_VAR_NAME3»
								STA «Members::TEMP_VAR_NAME3»
								LDA «Members::TEMP_VAR_NAME1» + 1
								ADC «Members::TEMP_VAR_NAME3» + 1
								STA «Members::TEMP_VAR_NAME3» + 1
								TXA
							«ELSE»
								CLC
								ADC «Members::TEMP_VAR_NAME3»
								TAX
								LDA «Members::TEMP_VAR_NAME1» + 1
								ADC «Members::TEMP_VAR_NAME3» + 1
								PHA
								TXA
							«ENDIF»
						«lastPower.set(i)»
					«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ELSE»
			«IF const === 0»
				«noop»
					LDA #$00
			«ELSEIF const.abs > 1 && bits.filter[it == one].size == 1»
				«noop»
					«FOR i : 0..< bits.indexOf(one)»
						ASL A
					«ENDFOR»
			«ELSEIF const.abs > 1»
				«var lastPower = new AtomicInteger»
				«FOR i : 0..< bits.size»
					«IF bits.get(i) == one»
						«noop»
							«FOR pow : 0..< i - lastPower.get»
								ASL A
							«ENDFOR»
							«IF i == 0 || lastPower.get == 0 && bits.head != one»
								STA «Members::TEMP_VAR_NAME1»
							«ELSEIF i < bits.size - 1»
								TAX
								CLC
								ADC «Members::TEMP_VAR_NAME1»
								STA «Members::TEMP_VAR_NAME1»
								TXA
							«ELSE»
								CLC
								ADC «Members::TEMP_VAR_NAME1»
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
		; TODO multiplyAbsolute
	'''

	private def multiplyIndirect(CompileContext multiplicand, CompileContext multiplier) '''
		; TODO multiplyIndirect
	'''

	private def divideImmediate(CompileContext dividend, CompileContext divisor) '''
		«val const = divisor.immediate.parseInt»
		«IF dividend.sizeOfOp > 1 || dividend.sizeOf > 1»
			; TODO divide 16bits
		«ELSE»
			«val divStart = '''div@«dividend.hashCode.toHexString».start'''»
			«val divDone = '''div@«dividend.hashCode.toHexString».done'''»
			«val divEnd = '''div@«dividend.hashCode.toHexString».end'''»
			«IF dividend.type.isSigned»
				«noop»
					TAY
					BPL +«divStart»
				«dividend.signum»
			«ENDIF»
			+«divStart»:
				LDX #$00
				STX «Members::TEMP_VAR_NAME1»
				«IF const.abs > 0xFF»
					CPX #>«const.abs»
					BCC +«divDone»
				«ENDIF»
				CMP #<«const.abs»
				BCC +«divDone»
			«FOR i : 8 >.. 0»
				«val shift = const.abs << i»
				«IF shift <= 0xFF»
					«noop»
						CMP #«shift»
						BCC +
						SBC #«shift»
					+	ROL «Members::TEMP_VAR_NAME1»
				«ENDIF»
			«ENDFOR»
			+«divDone»:
				LDA «Members::TEMP_VAR_NAME1»
			«IF dividend.type.isSigned»
				«noop»
					BEQ +«divEnd»
					CPY #$00
					«IF const < 0»
						BMI +«divEnd»
					«ELSE»
						BPL +«divEnd»
					«ENDIF»
				«dividend.signum»
			«ELSEIF const < 0»
				«noop»
					BEQ +«divEnd»
				«dividend.signum»
			«ENDIF»
			+«divEnd»:
		«ENDIF»
	'''

	private def operateImmediate(CompileContext operand, String instruction) '''
		«noop»
			«instruction» #(«operand.immediate»)
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					PLA
					«instruction» #$00
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					«instruction» «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					«instruction» #>(«operand.immediate»)
			«ELSEIF operand.type.isUnsigned»
				«acc.loadMSB»
					«instruction» #$00
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					PLA
					«instruction» #$00
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					«instruction» «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					«instruction» «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSEIF operand.type.isUnsigned»
				«acc.loadMSB»
					«instruction» #$00
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
			«ELSEIF acc.sizeOf > 1 && operand.type.isUnsigned»
				«noop»
					PLA
					«instruction» #$00
			«ELSEIF acc.sizeOf > 1»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					«instruction» «Members::TEMP_VAR_NAME1»
			«ELSEIF operand.sizeOf > 1»
				«acc.loadMSB»
					INY
					«instruction» («operand.indirect»), Y
			«ELSEIF operand.type.isUnsigned»
				«acc.loadMSB»
					«instruction» #$00
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

	private def labelForSignedMSBEnd() '''signedMSBEnd'''

	private def labelForIncDone() '''incDone'''

	private def labelForDecMSBSkip() '''decMSBSkip'''

	private def labelForShiftLoop() '''shiftLoop'''

	private def labelForShiftEnd() '''shiftEnd'''

	private def labelForComparison() '''comparison'''

	def labelForComparisonIsTrue() '''comparisonIsTrue'''

	def labelForComparisonIsFalse() '''comparisonIsFalse'''

	def labelForComparisonEnd() '''comparisonEnd'''

	private def void noop() {
	}
}
