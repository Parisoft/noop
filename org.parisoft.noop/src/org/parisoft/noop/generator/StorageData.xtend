package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors

class StorageData {

	@Accessors var String accumulator //A, X or Y
	@Accessors var String absolute // a : Fetches the value from a 16-bit address anywhere in memory
	@Accessors var String relative // label : Branch instructions (e.g. BEQ, BCS) have a relative addressing mode that specifies an 8-bit signed offset relative to the current PC
	@Accessors var String indirect // (d) : The JMP instruction has a special indirect addressing mode that can jump to the address stored in a 16-bit pointer anywhere in memory
	@Accessors var String index    // a, X or (d), Y
	@Accessors var String container
}