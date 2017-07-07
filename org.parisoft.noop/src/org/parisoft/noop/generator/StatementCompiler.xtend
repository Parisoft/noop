package org.parisoft.noop.generator

import com.google.inject.Inject
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.ElseStatement
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.ForeverStatement
import org.parisoft.noop.noop.StorageType

class StatementCompiler {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension Collections
	@Inject ExpressionCompiler exprCompiler

	def void prepare(Statement statement, MetaData data) {
		switch (statement) {
			Variable:
				if (statement.isROM && statement.storage.type == StorageType.PRGROM) {
					data.prgRoms.add(statement)
				} else if (statement.isROM && statement.storage.type == StorageType.CHRROM) {
					data.chrRoms.add(statement)
				} else if (statement.isConstant && statement.typeOf.isPrimitive) {
					data.constants.add(statement)
				} else if (statement.typeOf.isSingleton) {
					data.classes.add(statement.typeOf)
					data.singletons.add(statement.typeOf)
				} else {
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

					statement.value?.prepare(data)

					data.classes.add(statement.typeOf)
					data.variables.put(statement, mem)
				}
			IfStatement: {
				val ptrCounter = data.ptrCounter
				val varCounter = data.varCounter

				statement.condition.prepare(data)
				statement.body.statements.forEach[prepare(data)]

				data.ptrCounter = ptrCounter
				data.varCounter = varCounter

				statement.^else?.prepare(data)
			}
			ForStatement: {
				val ptrCounter = data.ptrCounter
				val varCounter = data.varCounter

				statement.variables.forEach[prepare(data)]
				statement.assignments.forEach[prepare(data)]
				statement.condition?.prepare(data)
				statement.expressions.forEach[prepare(data)]
				statement.body.statements.forEach[prepare(data)]

				data.ptrCounter = ptrCounter
				data.varCounter = varCounter
			}
			ForeverStatement: {
				val ptrCounter = data.ptrCounter
				val varCounter = data.varCounter

				statement.body.statements.forEach[prepare(data)]

				data.ptrCounter = ptrCounter
				data.varCounter = varCounter
			}
			ReturnStatement:
				statement.value?.prepare(data)
			Expression:
				statement.prepare(data)
		}
	}

	def prepare(ElseStatement statement, MetaData data) {
		val ptrCounter = data.ptrCounter
		val varCounter = data.varCounter

		statement.body.statements.forEach[prepare(data)]

		data.ptrCounter = ptrCounter
		data.varCounter = varCounter

		statement.^if?.prepare(data)
	}

	def prepare(Expression expression, MetaData data) {
		exprCompiler.prepare(expression, data)
	}
}
