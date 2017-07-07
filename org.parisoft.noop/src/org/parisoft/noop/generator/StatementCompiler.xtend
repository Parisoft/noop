package org.parisoft.noop.generator

import com.google.inject.Inject
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.ReturnStatement

class StatementCompiler {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension ExpressionCompiler
	@Inject extension Collections

	def prepare(Statement statement, MetaData data) {
		switch (statement) {
			Variable: {
				val mem = if (statement.isNonParameter) {
						new MemChunk(data.varCounter, statement.sizeOf)
					} else if (statement.dimensionOf.isNotEmpty) {
						new MemChunk(data.ptrCounter, data.varCounter, statement.dimensionOf.size)
					} else if (statement.typeOf.isPrimitive) {
						new MemChunk(data.varCounter, statement.sizeOf)
					} else {
						new MemChunk(data.ptrCounter)
					}

				if (mem.lastPtrAddr !== null) {
					data.ptrCounter = mem.lastPtrAddr + 1
				}

				if (mem.lastVarAddr !== null) {
					data.varCounter = mem.lastVarAddr + 1
				}

				statement.value?.prepareExpr(data)

				data.classes.add(statement.typeOf)
				data.variables.put(statement, mem)
			}
			ReturnStatement:
				statement.value?.prepareExpr(data)
			Expression:
				statement.prepareExpr(data)
		}
	}

}
