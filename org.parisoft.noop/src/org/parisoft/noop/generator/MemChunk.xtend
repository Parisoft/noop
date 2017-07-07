package org.parisoft.noop.generator

import org.eclipse.xtend.lib.annotations.Accessors

class MemChunk {

	@Accessors var Integer firstPtrAddr
	@Accessors var Integer firstVarAddr
	@Accessors var Integer lastPtrAddr
	@Accessors var Integer lastVarAddr

	new() {
		super()
	}

	new(int addr) {
		firstPtrAddr = addr
		lastPtrAddr = addr + 1
		firstVarAddr = null
		lastVarAddr = null
	}

	new(int addr, int size) {
		firstPtrAddr = null
		lastPtrAddr = null
		firstVarAddr = addr
		lastVarAddr = addr + size - 1
	}

	new(int ptrAddr, int varAddr, int varSize) {
		firstPtrAddr = ptrAddr
		lastPtrAddr = ptrAddr + 1
		firstVarAddr = varAddr
		lastVarAddr = varAddr + varSize - 1
	}

	def setLastPtrAddr(Integer addr) {
		if (addr ?: 0 > 0x00FF) {
			throw new PtrMemOverflowException
		}

		lastPtrAddr = addr
	}

	def setLastVarAddr(Integer addr) {
		if (addr ?: 0 > 0x08FF) {
			throw new PtrMemOverflowException
		}

		lastVarAddr = addr
	}

	def isPointer() {
		firstPtrAddr === null
	}

	def ptrSize() {
		if (firstPtrAddr !== null && lastPtrAddr !== null) {
			lastPtrAddr - firstPtrAddr + 1
		} else {
			0
		}
	}

	def varSize() {
		if (firstVarAddr !== null && lastVarAddr !== null) {
			lastVarAddr - firstVarAddr + 1
		} else {
			0
		}
	}

	def isNew() {
		firstVarAddr === null && lastVarAddr === null && firstPtrAddr === null && lastPtrAddr === null
	}

	def isNotNew() {
		!isNew
	}

	def selfIfNotOverlappedBy(MetaData data) {
		if (firstPtrAddr !== null && firstPtrAddr < data.ptrCounter) {
			throw new PtrMemOverlapException(this)
		}

		if (firstVarAddr !== null && firstVarAddr < data.varCounter) {
			throw new VarMemOverlapException(this)
		}

		this
	}
}
