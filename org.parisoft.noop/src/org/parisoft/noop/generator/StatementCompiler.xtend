package org.parisoft.noop.generator

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.ElseStatement
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.ForeverStatement
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.eclipse.xtext.naming.IQualifiedNameProvider

class StatementCompiler {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	@Inject ExpressionCompiler exprCompiler

	def void alloc(Statement statement, MetaData data) {
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
					val method = statement.getContainerOfType(Method)

					if (statement.isNonParameter) {
						data.variables.get(method).put(statement, data.chunkForVar(statement.sizeOf))
					} else if (statement.dimensionOf.isNotEmpty) {
						val i = new AtomicInteger(0)

						statement.dimensionOf.map [
							NoopFactory::eINSTANCE.createVariable => [
								name = statement.fullyQualifiedName.toString + ".len" + i.andIncrement
							]
						].forEach [
							data.variables.get(method).put(it, data.chunkForVar(1))
						]

						data.pointers.get(method).put(statement, data.chunkForPointer)
					} else if (statement.typeOf.isPrimitive) {
						data.variables.get(method).put(statement, data.chunkForVar(statement.sizeOf))
					} else {
						data.pointers.get(method).put(statement, data.chunkForPointer)
					}

					statement.value?.alloc(data)

					data.classes.add(statement.typeOf)
				}
			IfStatement: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get

				statement.condition.alloc(data)
				statement.body.statements.forEach[alloc(data)]

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)

				statement.^else?.alloc(data)
			}
			ForStatement: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get

				statement.variables.forEach[alloc(data)]
				statement.assignments.forEach[alloc(data)]
				statement.condition?.alloc(data)
				statement.expressions.forEach[alloc(data)]
				statement.body.statements.forEach[alloc(data)]

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
			ForeverStatement: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get

				statement.body.statements.forEach[alloc(data)]

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
			ReturnStatement:
				if (statement.value !== null) {
					val method = statement.getContainerOfType(Method)
					val returnVar = NoopFactory::eINSTANCE.createVariable => [
						name = method.fullyQualifiedName.toString + '.return'
					]

					data.variables.get(method).put(returnVar, data.chunkForVar(method.sizeOf))
				}
			Expression:
				statement.alloc(data)
		}
	}

	def alloc(ElseStatement statement, MetaData data) {
		val prevPtrCounter = data.ptrCounter.get
		val prevVarCounter = data.varCounter.get

		statement.body.statements.forEach[alloc(data)]

		data.ptrCounter.set(prevPtrCounter)
		data.varCounter.set(prevVarCounter)

		statement.^if?.alloc(data)
	}

	def alloc(Expression expression, MetaData data) {
		exprCompiler.alloc(expression, data)
	}

}
