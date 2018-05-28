package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors

class MemChunk implements Comparable<MemChunk> {

	@Accessors var int lo
	@Accessors var int hi
	@Accessors var String variable
	@Accessors var boolean disposed = false
	@Accessors var boolean tmp = false
	

	new(String variable, int addr, int size) {
		this.variable = variable
		this.lo = addr
		this.hi = addr + size - 1
	}

	def getPage() {
		lo / 256
	}

	def isZP() {
		lo < 0x0100
	}

	def nonZP() {
		!isZP
	}

	def isNonDisposed() {
		!disposed
	}

	def overlap(MemChunk other) {
		this.lo <= other.hi && this.hi >= other.lo
	}

	def deltaFrom(MemChunk other) {
		other.hi - this.lo + 1
	}

	def shiftTo(MemChunk other) {
		val delta = other.hi - this.lo + 1
		this.lo += delta
		this.hi += delta

		return delta
	}

	def void shiftTo(int delta) {
		this.lo += delta
		this.hi += delta
	}

	override compareTo(MemChunk other) {
		val loComp = this.lo.compareTo(other.lo)

		if (loComp != 0) {
			loComp
		} else {
			this.variable.compareTo(other.variable)
		}

	}

	override toString() '''
		MemChunk{
			variable:«variable»,
			lo:«Integer.toHexString(lo)», 
			hi:«Integer.toHexString(hi)»
		}
	'''

}
