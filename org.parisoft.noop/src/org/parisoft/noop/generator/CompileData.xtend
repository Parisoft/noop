package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors
import org.parisoft.noop.noop.NoopClass

class CompileData {

	@Accessors var String register // A, X or Y
	@Accessors var String absolute // a : Fetches the value from a 16-bit address anywhere in memory
	@Accessors var String relative // label : Branch instructions (e.g. BEQ, BCS) have a relative addressing mode that specifies an 8-bit signed offset relative to the current PC
	@Accessors var String indirect // (d) : The JMP instruction has a special indirect addressing mode that can jump to the address stored in a 16-bit pointer anywhere in memory
	@Accessors var String index // a, X or (d), Y
	@Accessors var String container
	@Accessors var NoopClass type
	@Accessors var boolean copy = true
	@Accessors var AllocData allocation

	override toString() '''
		StorageData{
			register=«register»
			,absolute=«absolute»
			,relative=«relative»
			,indirect=«indirect»
			,index=«index»
			,container=«container»
			,type=«type?.name»
			,copy=«copy»
		}
	'''

	def isIndexed() {
		index !== null
	}

}
