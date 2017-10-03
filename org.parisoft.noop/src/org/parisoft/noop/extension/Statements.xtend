package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.CompileData
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

class Statements {

	@Inject extension Datas
	@Inject extension Members
	@Inject extension Classes
	@Inject extension Collections
	@Inject extension Expressions

	def isVoid(ReturnStatement ^return) {
		^return === null || ^return.value === null || ^return.method.typeOf.isVoid
	}

	def isNonVoid(ReturnStatement ^return) {
		!^return.isVoid
	}

	def getMethod(ReturnStatement ^return) {
		^return.getContainerOfType(Method)
	}

	def nameOf(ReturnStatement ^return) {
		'''«^return.getContainerOfType(Method).nameOf».ret'''.toString
	}

	def nameOfLen(ReturnStatement ^return) {
		'''«^return.getContainerOfType(Method).nameOf».ret.len'''.toString
	}

	def void prepare(Statement statement, AllocData data) {
		switch (statement) {
			Variable: {
				statement.value?.prepare(data)

				if (statement.isConstant) {
					data.constants += statement
				} else if (statement.isROM) {
					if (statement.storage.type == StorageType.PRGROM) {
						data.prgRoms += statement
					} else if (statement.storage.type == StorageType.CHRROM) {
						data.chrRoms += statement
					}
				} else if (statement.isStatic && statement.typeOf.isNonINESHeader) {
					data.statics += statement
				}
			}
			IfStatement: {
				statement.condition.prepare(data)
				statement.body.statements.forEach[prepare(data)]
			}
			ForStatement: {
				statement.variables.forEach[prepare(data)]
				statement.assignments.forEach[prepare(data)]
				statement.condition?.prepare(data)
				statement.expressions.forEach[prepare(data)]
				statement.body.statements.forEach[prepare(data)]
			}
			ForeverStatement: {
				statement.body.statements.forEach[prepare(data)]
			}
			AsmStatement: {
				statement.vars.forEach[prepare(data)]
			}
			ReturnStatement: {
				statement.value?.prepare(data)
			}
			Expression: {
				statement.prepare(data)
			}
		}
	}

	def List<MemChunk> alloc(Statement statement, AllocData data) {
		switch (statement) {
			Variable: {
				val name = statement.nameOf(data.container)
				val chunks = newArrayList

				if (statement.isParameter) {
					if (statement.type.isNonPrimitive || statement.dimensionOf.isNotEmpty) {
						chunks += data.computePtr(name)

						for (i : 0 ..< statement.dimensionOf.size) {
							chunks += data.computeVar(statement.nameOfLen(data.container, i), 1)
						}
					} else {
						chunks += data.computeVar(name, statement.sizeOf)
					}
				} else if (statement.isNonStatic) {
					chunks += data.computeVar(name, statement.sizeOf)
				}

				return (chunks + statement?.value.alloc(data)).filterNull.toList
			}
			IfStatement: {
				val snapshot = data.snapshot
				val chunks = statement.condition.alloc(data) + statement.body.statements.map[alloc(data)].flatten

				chunks.disoverlap(data.container)

				data.restoreTo(snapshot)

				return (chunks + (statement?.^else?.alloc(data) ?: emptyList)).filterNull.toList
			}
			ForStatement: {
				val snapshot = data.snapshot
				val chunks = statement.variables.map[alloc(data)].flatten.toList
				chunks += statement.assignments.map[alloc(data)].flatten
				chunks += statement.condition?.alloc(data)
				chunks += statement.expressions.map[alloc(data)].flatten
				chunks += statement.body.statements.map[alloc(data)].flatten
				chunks.disoverlap(data.container)

				data.restoreTo(snapshot)

				return chunks.filterNull.toList
			}
			ForeverStatement: {
				val snapshot = data.snapshot
				val chunks = statement.body.statements.map[alloc(data)].flatten

				chunks.disoverlap(data.container)

				data.restoreTo(snapshot)

				return chunks.toList
			}
			ReturnStatement: {
				val chunks = newArrayList

				if (statement.isNonVoid) {
					chunks += data.computePtr(statement.nameOf)
				}

				chunks += statement.value?.alloc(data)

				return chunks.filterNull.toList
			}
			Expression:
				statement.alloc(data)
			AsmStatement:
				statement.vars.map[alloc(data)].flatten.toList
			default:
				newArrayList
		}
	}

	def alloc(ElseStatement statement, AllocData data) {
		val snapshot = data.snapshot
		val chunks = statement.body.statements.map[alloc(data)].flatten

		chunks.disoverlap(data.container)

		data.restoreTo(snapshot)

		return chunks + statement?.^if.alloc(data)
	}

	def compile(Statement statement, CompileData data) {
		switch (statement) {
			Variable: '''
				«IF statement.isROM»
					«statement.value.compile(data => [
						relative = statement.nameOfStatic
						type = statement.typeOf
					])»
				«ELSEIF data.absolute !== null»
					«statement.value.compile(data => [
						absolute = '''«data.absolute» + #«statement.nameOfOffset»'''
						type = statement.typeOf
					])»
				«ELSEIF data.indirect !== null»
					«statement.value.compile(data => [
						index = '''#«statement.nameOfOffset»'''
						type = statement.typeOf
					])»
				«ELSE»
					«statement.value.compile(data => [
						absolute = statement.nameOf(data.container)
						type = statement.typeOf
					])»
				«ENDIF»
			'''
			ReturnStatement: '''
				«val method = statement.method»
				«IF statement.isNonVoid»
					«statement.value.compile(new CompileData => [
						container = method.nameOf
						type = statement.method.typeOf
						
						if (type.isPrimitive && statement.method.dimensionOf.isEmpty) {
							absolute = method.nameOfReturn
							copy = true							
						} else {
							indirect = method.nameOfReturn
							copy = false
						}
					])»
				«ELSEIF statement.value !== null»
					«statement.value.compile(new CompileData => [
						container = method.nameOf
						type = statement.value.typeOf
					])»
				«ENDIF»
			'''
			AsmStatement:
				if (statement.vars.isEmpty) {
					statement.codes.join('', [substring(1, it.length - 1)])
				} else {
					val i = new AtomicInteger(0)

					statement.codes.reduce [ c1, c2 |
						c1.substring(1, c1.length - 1) + statement.vars.get(i.andIncrement).nameOf + c2.substring(1, c2.length - 1)
					]
				}
			Expression:
				statement.compile(data)
			default:
				''
		}
	}
}
