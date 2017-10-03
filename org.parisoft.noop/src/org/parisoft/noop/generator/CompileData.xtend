package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass

class CompileData {

	enum Operation {
		OR,
		AND,
		ADDITION, 
		SUBTRACTION,
		MULTIPLICATION,
		DIVISION,
		BIT_OR,
		BIT_AND,
		BIT_LEFT_SHIFT,
		BIT_RIGHT_SHIFT,
		EXCLUSIVE_OR,
		NEGATION,
		SIGNUM
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
	@Accessors var boolean copy = true
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
			,copy=«copy»
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
			copy = src.copy
		]
	}
	
}
