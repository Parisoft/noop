package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.CompileData

import static extension java.lang.Integer.*
import static extension java.lang.Math.*

class Operations {

	@Inject extension Datas
	@Inject extension Classes

	val labelCounter = new AtomicInteger

	def operateOn(CompileData acc, CompileData operand) {
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

	def isEquals(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.equalsImmediate(false, operand)
		} else if (operand.absolute !== null) {
			acc.equalsAbsolute(false, operand)
		} else if (operand.indirect !== null) {
			acc.equalsIndirect(false, operand)
		}
	}

	def notEquals(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.equalsImmediate(true, operand)
		} else if (operand.absolute !== null) {
			acc.equalsAbsolute(true, operand)
		} else if (operand.indirect !== null) {
			acc.equalsIndirect(true, operand)
		}
	}

	def lessThan(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.compareImmediate('BCC', 'BMI', operand)
		} else if (operand.absolute !== null) {
			acc.compareAbsolute('BCC', 'BMI', operand)
		} else if (operand.indirect !== null) {
			acc.compareIndirect('BCC', 'BMI', operand)
		}
	}

	def greaterEqualsThan(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.compareImmediate('BCS', 'BPL', operand)
		} else if (operand.absolute !== null) {
			acc.compareAbsolute('BCS', 'BPL', operand)
		} else if (operand.indirect !== null) {
			acc.compareIndirect('BCS', 'BPL', operand)
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

	def multiply(CompileData acc, CompileData operand) {
		if (operand.immediate !== null) {
			acc.multiplyImmediate(operand)
		} else if (operand.absolute !== null) {
			acc.multiplyAbsolute(operand)
		} else if (operand.indirect !== null) {
			acc.multiplyIndirect(operand)
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
			«IF acc.relative !== null»
				BEQ +«acc.relative»
			«ELSE»
				EOR #%00000001
			«ENDIF»
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

	private def equalsImmediate(CompileData acc, boolean diff, CompileData operand) '''
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«val comparisonEnd = labelForComparisonEnd»
		«IF acc.sizeOf > 1»
			«noop»
				CMP #<(«operand.immediate»)
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«IF operand.sizeOf > 1»
				«noop»
					PLA
					CMP #>(«operand.immediate»)
			«ELSE»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					CMP «Members::TEMP_VAR_NAME1»
			«ENDIF»
			«IF acc.relative === null»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
				+«comparisonIsFalse»
					LDA #«Members::FALSE»
					JMP +«comparisonEnd»
				+«comparisonIsTrue»
					LDA #«Members::TRUE»
				+«comparisonEnd»
			«ELSE»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
				+«comparisonIsFalse»
			«ENDIF»
		«ELSE»
			«noop»
				CMP #(«operand.immediate»)
			«IF acc.relative === null»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
					LDA #«Members::FALSE»
					JMP +«comparisonEnd»
				+«comparisonIsTrue»
					LDA #«Members::TRUE»
				+«comparisonEnd»
			«ELSE»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
			«ENDIF»
		«ENDIF»
	'''

	private def equalsAbsolute(CompileData acc, boolean diff, CompileData operand) '''
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«val comparisonEnd = labelForComparisonEnd»
			«IF operand.isIndexed»
				LDX «operand.index»
			«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«IF operand.sizeOf > 1»
				«noop»
					PLA
					CMP «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
			«ELSE»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					CMP «Members::TEMP_VAR_NAME1»
			«ENDIF»
			«IF acc.relative === null»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
				+«comparisonIsFalse»
					LDA #«Members::FALSE»
					JMP +«comparisonEnd»
				+«comparisonIsTrue»
					LDA #«Members::TRUE»
				+«comparisonEnd»
			«ELSE»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
				+«comparisonIsFalse»
			«ENDIF»
		«ELSE»
			«noop»
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
			«IF acc.relative === null»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
					LDA #«Members::FALSE»
					JMP +«comparisonEnd»
				+«comparisonIsTrue»
					LDA #«Members::TRUE»
				+«comparisonEnd»
			«ELSE»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
			«ENDIF»
		«ENDIF»
	'''

	private def equalsIndirect(CompileData acc, boolean diff, CompileData operand) '''
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«val comparisonEnd = labelForComparisonEnd»
			LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
		«IF acc.sizeOf > 1»
			«noop»
				CMP «operand.indirect», Y
				BNE +«IF diff»«comparisonIsTrue»«ELSE»«comparisonIsFalse»«ENDIF»
			«IF operand.sizeOf > 1»
				«noop»
					PLA
					CMP «operand.indirect», Y
			«ELSE»
				«operand.loadMSB»
					STA «Members::TEMP_VAR_NAME1»
					PLA
					CMP «Members::TEMP_VAR_NAME1»
			«ENDIF»
			«IF acc.relative === null»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
				+«comparisonIsFalse»
					LDA #«Members::FALSE»
					JMP +«comparisonEnd»
				+«comparisonIsTrue»
					LDA #«Members::TRUE»
				+«comparisonEnd»
			«ELSE»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
				+«comparisonIsFalse»
			«ENDIF»
		«ELSE»
			«noop»
				CMP («operand.indirect»), Y
			«IF acc.relative === null»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«comparisonIsTrue»
					LDA #«Members::FALSE»
					JMP +«comparisonEnd»
				+«comparisonIsTrue»
					LDA #«Members::TRUE»
				+«comparisonEnd»
			«ELSE»
				«noop»
					B«IF diff»NE«ELSE»EQ«ENDIF» +«acc.relative»
			«ENDIF»
		«ENDIF»
	'''

	private def compareImmediate(CompileData acc, String ubranch, String sbranch, CompileData operand) '''
		«var branch = ubranch»
		«val comparison = labelForComparison»
		«val comparisonEnd = labelForComparisonEnd»
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«IF acc.type.isSigned && operand.type.isSigned»
			«IF acc.sizeOf > 1»
				«noop»
					CMP #<(«operand.immediate»)
				«IF operand.sizeOf > 1»
					«noop»
						PLA
						SBC #>(«operand.immediate»)
				«ELSE»
					«operand.loadMSB»
						STA «Members::TEMP_VAR_NAME1»
						PLA
						SBC «Members::TEMP_VAR_NAME1»
				«ENDIF»
			«ELSE»
				«noop»
					SEC
					SBC #(«operand.immediate»)
			«ENDIF»
			«branch = sbranch»
				BVC +«comparison»
				EOR #$80
			+«comparison»
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
						STA «Members::TEMP_VAR_NAME1»
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PHA
						LDA «Members::TEMP_VAR_NAME1»
				«ELSE»
					«noop»
						TAY
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
			«ENDIF»
			«IF acc.sizeOf > 1»
				«noop»
					CMP #<(«operand.immediate»)
				«IF operand.sizeOf > 1»
					«noop»
						PLA
						SBC #>«operand.immediate»
				«ELSE»
					«operand.loadMSB»
						STA «Members::TEMP_VAR_NAME1»
						PLA
						SBC «Members::TEMP_VAR_NAME1»
				«ENDIF»
			«ELSE»
				«noop»
					CMP #(«operand.immediate»)
			«ENDIF»
		«ENDIF»
		«IF acc.relative === null»
			«noop»
				«branch» +«comparisonIsTrue»
			+«comparisonIsFalse»
				LDA #«Members::FALSE»
				JMP +«comparisonEnd»
			+«comparisonIsTrue»
				LDA #«Members::TRUE»
			+«comparisonEnd»
		«ELSE»
			«noop»
				«branch» +«acc.relative»
			+«comparisonIsFalse»
		«ENDIF»
	'''

	private def compareAbsolute(CompileData acc, String ubranch, String sbranch, CompileData operand) '''
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
			«IF acc.sizeOf > 1»
				«noop»
					CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
				«IF operand.sizeOf > 1»
					«noop»
						PLA
						SBC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
				«ELSE»
					«operand.loadMSB»
						STA «Members::TEMP_VAR_NAME1»
						PLA
						SBC «Members::TEMP_VAR_NAME1»
				«ENDIF»
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
						STA «Members::TEMP_VAR_NAME1»
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PHA
						LDA «Members::TEMP_VAR_NAME1»
				«ELSE»
					«noop»
						PHA
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
			«ENDIF»
			«noop»
				CMP «operand.absolute»«IF operand.isIndexed», X«ENDIF»
			«IF acc.sizeOf > 1»
				«IF operand.sizeOf > 1»
					«noop»
						PLA
						SBC «operand.absolute» + 1«IF operand.isIndexed», X«ENDIF»
				«ELSE»
					«operand.loadMSB»
						STA «Members::TEMP_VAR_NAME1»
						PLA
						SBC «Members::TEMP_VAR_NAME1»
				«ENDIF»
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

	private def compareIndirect(CompileData acc, String ubranch, String sbranch, CompileData operand) '''
		«var branch = ubranch»
		«val comparison = labelForComparison»
		«val comparisonEnd = labelForComparisonEnd»
		«val comparisonIsTrue = labelForComparisonIsTrue»
		«val comparisonIsFalse = labelForComparisonIsFalse»
		«IF acc.type.isSigned && operand.type.isSigned»
			«noop»
				LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«IF acc.sizeOf > 1»
				«noop»
					CMP («operand.indirect»), Y
				«IF operand.sizeOf > 1»
					«noop»
						INY
						PLA
						SBC («operand.indirect»), Y
				«ELSE»
					«operand.loadMSB»
						STA «Members::TEMP_VAR_NAME1»
						PLA
						SBC «Members::TEMP_VAR_NAME1»
				«ENDIF»
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
						PHA
						LDA («operand.indirect»), Y
						BMI +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PLA
						DEY
				«ELSE»
					«noop»
						LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
						PHA
						LDA («operand.indirect»), Y
						BMI +«IF ubranch === 'BCC'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PLA
				«ENDIF»
			«ELSEIF acc.type.isSigned && operand.type.isUnsigned»
				«IF acc.sizeOf > 1»
					«noop»
						STA «Members::TEMP_VAR_NAME1»
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
						PHA
						LDA «Members::TEMP_VAR_NAME1»
				«ELSE»
					«noop»
						PHA
						PLA
						BMI +«IF ubranch === 'BCS'»«comparisonIsFalse»«ELSE»«comparisonIsTrue»«ENDIF»
				«ENDIF»
			«ELSE»
				«noop»
					LDY «IF operand.isIndexed»«operand.index»«ELSE»#$00«ENDIF»
			«ENDIF»
			«noop»
				CMP («operand.indirect»), Y
			«IF acc.sizeOf > 1»
				«IF operand.sizeOf > 1»
					«noop»
						INY
						PLA
						SBC («operand.indirect»), Y
				«ELSE»
					«operand.loadMSB»
						STA «Members::TEMP_VAR_NAME1»
						PLA
						SBC «Members::TEMP_VAR_NAME1»
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
		«ENDIF»
	'''

	private def bitShiftLeftImmediate(CompileData acc, CompileData operand) '''
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

	private def bitShiftRightImmediate(CompileData acc, CompileData operand) '''
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
			-«shiftLoop»:
				LSR A
				DEY
				BNE -«shiftLoop»
			+«shiftEnd»:
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
			+«labelDone»:
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
			+«labelDone»:
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
			+«labelSkip»:
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
			+«labelSkip»:
				DEC («data.indirect»), Y
		«ELSE»
			«noop»
				DEC («data.indirect»), Y
		«ENDIF»
	'''

	private def multiplyImmediate(CompileData multiplicand, CompileData multiplier) '''
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

	private def multiplyAbsolute(CompileData multiplicand, CompileData multiplier) '''
		
	'''

	private def multiplyIndirect(CompileData multiplicand, CompileData multiplier) '''
		
	'''

	private def operateImmediate(CompileData operand, String instruction) '''
		«noop»
			«instruction» #(«operand.immediate»)
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
				«instruction» #(«operand.immediate»)
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
					LDA #(«data.immediate»)
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
