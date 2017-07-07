package org.parisoft.noop.generator

import com.google.inject.Inject
import org.parisoft.noop.noop.Method

class MethodCompiler {

	@Inject extension StatementCompiler

	def MemChunk prepare(Method method, MetaData data) {
		val mem = data.methods.computeIfAbsent(method, [new MemChunk])

		if (mem.isNotNew) {
			return mem.selfIfNotOverlappedBy(data)
		}

		mem => [
			firstPtrAddr = data.ptrCounter
			firstVarAddr = data.varCounter
		]

		method.params.forEach[prepare(data)]

		try {
			method.body.statements.forEach[prepare(data)]
		} catch (PtrMemOverlapException e) {
			return method.rollback(data).prepare(data => [ptrCounter = e.chunk.lastPtrAddr + 1])
		} catch (VarMemOverlapException e) {
			return method.rollback(data).prepare(data => [varCounter = e.chunk.lastVarAddr + 1])
		}

		if (mem.firstPtrAddr != data.ptrCounter) {
			mem.lastPtrAddr = data.ptrCounter
			data.ptrCounter = mem.firstPtrAddr
		}

		if (mem.firstVarAddr != data.varCounter) {
			mem.lastVarAddr = data.varCounter
			data.varCounter = mem.firstVarAddr
		}

		return mem
	}

	private def rollback(Method method, MetaData data) {
		data.methods.remove(method)
		return method
	}

}
