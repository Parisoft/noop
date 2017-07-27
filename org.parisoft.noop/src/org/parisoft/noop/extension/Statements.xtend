package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.noop.AsmStatement
import org.parisoft.noop.noop.ElseStatement
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.ForeverStatement
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Statement
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.eclipse.xtext.naming.IQualifiedNameProvider
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.StackData
import org.parisoft.noop.generator.StorageData

class Statements {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension Collections
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider

	def isVoid(ReturnStatement ^return) {
		^return === null || ^return.value === null || ^return.method.typeOf.name == TypeSystem.LIB_VOID
	}

	def isNonVoid(ReturnStatement ^return) {
		!^return.isVoid
	}

	def getMethod(ReturnStatement ^return) {
		^return.getContainerOfType(Method)
	}

	def asmName(ReturnStatement ^return) {
		^return.getContainerOfType(Method).fullyQualifiedName.toString + '.return'
	}

	def List<MemChunk> alloc(Statement statement, StackData data) {
		switch (statement) {
			Variable: {
				val name = statement.asmName(data.container)
				val ptrChunks = data.pointers.computeIfAbsent(name, [newArrayList])
				val varChunks = data.variables.computeIfAbsent(name, [newArrayList])
				val allChunks = ptrChunks + varChunks

				if (allChunks.isEmpty) {
					if (statement.isParameter) {
						if (statement.type.isNonPrimitive || statement.dimensionOf.isNotEmpty) {
							ptrChunks += data.chunkForPointer(name)

							for (i : 0 ..< statement.dimensionOf.size) {
								varChunks += data.chunkForVar(name + '.len' + i, 1)
							}

							statement.type.alloc(data)
						} else {
							varChunks += data.chunkForVar(name, statement.sizeOf)
						}
					} else if (statement.isROM) {
						if (statement.storage.type == StorageType.PRGROM) {
							data.prgRoms += statement
						} else if (statement.storage.type == StorageType.CHRROM) {
							data.chrRoms += statement
						}
					} else if (statement.isConstant) {
						val type = statement.typeOf

						if (type.isNESHeader) {
							return newArrayList
						} else if (type.isSingleton) {
							type.alloc(data)
						} else if (type.isPrimitive) {
							data.constants += statement
						}
					} else {
						varChunks += data.chunkForVar(name, statement.sizeOf)
						statement.typeOf.alloc(data)
					}
				}

				return (allChunks + statement?.value.alloc(data)).filterNull.toList
			}
			IfStatement: {
				val snapshot = data.snapshot
				val chunks = statement.condition.alloc(data) + statement.body.statements.map[alloc(data)].flatten

				data.restoreTo(snapshot)

				return (chunks + statement.^else?.alloc(data)).toList
			}
			ForStatement: {
				val snapshot = data.snapshot
				val chunks = statement.variables.map[alloc(data)].flatten.toList
				chunks += statement.assignments.map[alloc(data)].flatten
				chunks += statement.condition?.alloc(data)
				chunks += statement.expressions.map[alloc(data)].flatten
				chunks += statement.body.statements.map[alloc(data)].flatten

				data.restoreTo(snapshot)

				return chunks
			}
			ForeverStatement: {
				val snapshot = data.snapshot
				val chunks = statement.body.statements.map[alloc(data)].flatten

				data.restoreTo(snapshot)

				return chunks.toList
			}
			ReturnStatement:
				if (statement.isNonVoid) {
					if (statement.method.typeOf.isPrimitive) {
						data.variables.compute(statement.asmName, [ name, v |
							newArrayList(data.chunkForVar(name, statement.method.sizeOf))
						])
					} else {
						data.pointers.compute(statement.asmName, [ name, v |
							newArrayList(data.chunkForPointer(name))
						])
					}
				} else {
					newArrayList
				}
			Expression:
				statement.alloc(data)
			AsmStatement:
				statement.vars.map[alloc(data)].flatten.toList
			default:
				newArrayList
		}
	}

	def alloc(ElseStatement statement, StackData data) {
		val snapshot = data.snapshot
		val chunks = statement.body.statements.map[alloc(data)].flatten

		data.restoreTo(snapshot)

		return chunks + statement.^if?.alloc(data)
	}

	def compile(Statement statement, StorageData data) {
		switch (statement) {
			Variable: '''
				«IF statement.isROM»
					«statement.value.compile(data => [
						relative = statement.asmConstantName
						type = statement.typeOf
					])»
				«ELSEIF data.absolute !== null || data.indirect !== null»
					«statement.value.compile(data => [
						index = statement.asmOffsetName
						type = statement.typeOf
					])»
				«ELSE»
					«statement.value.compile(data => [
						absolute = statement.asmName(data.container)
						type = statement.typeOf
					])»
				«ENDIF»
			'''
			AsmStatement:
				if (statement.vars.isEmpty) {
					statement.codes.join('', [substring(1, it.length - 1)])
				} else {
					val i = new AtomicInteger(0)

					statement.codes.reduce [ c1, c2 |
						c1.substring(1, c1.length - 1) + statement.vars.get(i.andIncrement).asmName + c2.substring(1, c2.length - 1)
					]
				}
			default:
				''
		}
	}
}
