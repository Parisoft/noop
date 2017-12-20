package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import java.util.Set

class CompileContext {

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
		MODULO,
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
	@Accessors var String db
	@Accessors var Operation operation // Ex.: ORA a
	@Accessors var String container
	@Accessors var NoopClass type
	@Accessors var NoopClass opType
	@Accessors var Mode mode = Mode::COPY
	@Accessors var AllocContext allocation
	@Accessors var boolean accLoaded = false
	@Accessors var Set<Variable> recursiveVars = newHashSet

	override toString() '''
		StorageData{
			immediate=«immediate»
			,register=«register»
			,absolute=«absolute»
			,relative=«relative»
			,indirect=«indirect»
			,index=«index»
			,db=«db»
			,operaion=«operation»
			,container=«container»
			,type=«type?.name»
			,mode=«mode»
			,accLoaded=«accLoaded»
			,opType=«opType»
		}
	'''

	def isIndexed() {
		index !== null
	}
	
	override CompileContext clone() {
		val src = this
		new CompileContext => [
			immediate = src.immediate
			register = src.register
			absolute = src.absolute
			relative = src.relative
			indirect = src.indirect
			index = src.index
			db = src.db
			operation = src.operation
			container = src.container
			type = src.type
			mode = src.mode
			accLoaded = src.isAccLoaded
			opType = src.opType
		]
	}
	
}
