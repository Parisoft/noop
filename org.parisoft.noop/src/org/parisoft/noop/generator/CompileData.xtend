package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass

class CompileData {

	enum Operation {
		OR,
		AND,
		COMPARE_EQ,
		COMPARE_NE,
		COMPARE_LT,
		COMPARE_GE,
		ADDITION, 
		SUBTRACTION,
		MULTIPLICATION,
		DIVISION,
		BIT_OR,
		BIT_AND,
		BIT_SHIFT_LEFT,
		BIT_SHIFT_RIGHT,
		BIT_EXCLUSIVE_OR,
		NEGATION,
		SIGNUM,
		DECREMENT,
		INCREMENT
	}
	
	enum Mode {
		COPY,
		POINT,
		OPERATE,
		REFERENCE
	}

	@Accessors var String immediate // #a
	@Accessors var String register // A, X or Y
	@Accessors var String absolute // a : Fetches the value from a 16-bit address anywhere in memory
	@Accessors var String relative // label : Branch instructions (e.g. BEQ, BCS) have a relative addressing mode that specifies an 8-bit signed offset relative to the current PC
	@Accessors var String indirect // (d) : The JMP instruction has a special indirect addressing mode that can jump to the address stored in a 16-bit pointer anywhere in memory
	@Accessors var String index // a, X or (d), Y
	@Accessors var Operation operation // Ex.: ORA a
	@Accessors var String container
	@Accessors var NoopClass type
	@Accessors var Mode mode = Mode::COPY
	@Accessors var AllocData allocation

	override toString() '''
		StorageData{
			immediate=«immediate»
			,register=«register»
			,absolute=«absolute»
			,relative=«relative»
			,indirect=«indirect»
			,index=«index»
			,operaion=«operation»
			,container=«container»
			,type=«type?.name»
			,mode=«mode»
		}
	'''

	def isIndexed() {
		index !== null
	}
	
	override CompileData clone() {
		val src = this
		new CompileData => [
			immediate = src.immediate
			register = src.register
			absolute = src.absolute
			relative = src.relative
			indirect = src.indirect
			index = src.index
			operation = src.operation
			container = src.container
			type = src.type
			mode = src.mode
		]
	}
	
}
