package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.CompileData
import org.parisoft.noop.generator.CompileData.Mode
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.noop.AsmStatement
import org.parisoft.noop.noop.BreakStatement
import org.parisoft.noop.noop.ContinueStatement
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

import static extension java.lang.Integer.*
import static extension org.eclipse.xtext.EcoreUtil2.*

class Statements {

	@Inject extension Datas
	@Inject extension Members
	@Inject extension Classes
	@Inject extension Collections
	@Inject extension Expressions

	def getForContainer(Statement statement) {
		var container = statement.eContainer

		while (container !== null && !(container instanceof ForStatement || container instanceof ForeverStatement)) {
			container = container.eContainer
		}

		return container
	}

	def IfStatement getIfContainer(IfStatement ifStatement) {
		val elseContainer = ifStatement.eContainer

		if (elseContainer !== null && elseContainer instanceof ElseStatement) {
			return elseContainer.getContainerOfType(IfStatement).ifContainer
		}

		return ifStatement
	}

	def isVoid(ReturnStatement ^return) {
		^return === null || ^return.value === null || ^return.method.typeOf.isVoid
	}

	def isNonVoid(ReturnStatement ^return) {
		!^return.isVoid
	}

	def getMethod(ReturnStatement ^return) {
		^return.getContainerOfType(Method)
	}

	def nameOf(IfStatement ifStatement) {
		'''«IF ifStatement.eContainer instanceof ElseStatement»elseif«ELSE»if«ENDIF»@«ifStatement.hashCode.toHexString»'''
	}

	def nameOfCondition(IfStatement ifStatement) {
		'''«ifStatement.nameOf»@condition'''
	}

	def nameOfEnd(IfStatement ifStatement) {
		'''«ifStatement.nameOf»@end'''
	}

	def nameOf(ElseStatement elseStatement) {
		if (elseStatement.^if !== null) {
			elseStatement.^if.nameOf
		} else {
			'''else@«elseStatement.hashCode.toHexString»'''
		}
	}
	
	def nameOfCondition(ElseStatement elseStatement) {
		if (elseStatement.^if !== null) {
			elseStatement.^if.nameOfCondition
		} else {
			elseStatement.nameOf
		}
	}

	def nameOf(ReturnStatement ^return) {
		'''«^return.getContainerOfType(Method).nameOf».ret'''.toString
	}

	def nameOfLen(ReturnStatement ^return) {
		'''«^return.getContainerOfType(Method).nameOf».ret.len'''.toString
	}

	def nameOf(ForeverStatement forever) {
		'''forever@«forever.hashCode.toHexString»'''
	}

	def nameOfEnd(ForeverStatement forever) {
		'''«forever.nameOf»@end'''
	}

	def nameOf(ForStatement forStatement) {
		'''for@«forStatement.hashCode.toHexString»'''
	}

	def nameOfCondition(ForStatement forStatement) {
		'''«forStatement.nameOf»@condition'''
	}

	def nameOfEvaluation(ForStatement forStatement) {
		'''«forStatement.nameOf»@evaluation'''
	}

	def nameOfIteration(ForStatement forStatement) {
		'''«forStatement.nameOf»@iteration'''
	}

	def nameOfEnd(ForStatement forStatement) {
		'''«forStatement.nameOf»@end'''
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
				statement.^else?.prepare(data)
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
	
	def prepare(ElseStatement elseStatement, AllocData data) {
		if (elseStatement.^if !== null) {
			elseStatement.^if.prepare(data)
		} else if (elseStatement.body !== null) {
			elseStatement.body.statements.forEach[prepare(data)]
		}
	}

	def List<MemChunk> alloc(Statement statement, AllocData data) {
		switch (statement) {
			Variable: {
				val name = statement.nameOf(data.container)
				val chunks = newArrayList

				if (statement.isParameter && (statement.type.isNonPrimitive || statement.dimensionOf.isNotEmpty)) {
					chunks += data.computePtr(name)

					for (i : 0 ..< statement.dimensionOf.size) {
						chunks += data.computeVar(statement.nameOfLen(data.container, i), 1)
					}
				} else if (statement.isNonStatic) {
					val page = statement?.storage?.location?.valueOf as Integer ?: Datas::VAR_PAGE
					chunks += data.computeVar(name, page, statement.sizeOf)
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
		if (statement.^if !== null) {
			return statement.^if.alloc(data)
		}

		val snapshot = data.snapshot
		val chunks = statement.body.statements.map[alloc(data)].flatten

		chunks.disoverlap(data.container)
		data.restoreTo(snapshot)

		return chunks

	}

	def String compile(Statement statement, CompileData data) {
		switch (statement) {
			Variable: '''
				«IF statement.isROM»
					«statement.value.compile(data => [
						db = statement.nameOfStatic
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
			IfStatement: '''
				«val mainIf = statement.ifContainer»
				«val endIf = mainIf.nameOfEnd»
				+«statement.nameOfCondition»:
				«statement.condition.compile(new CompileData => [
					container = data.container
					operation = data.operation
					type = statement.condition.typeOf
					relative = statement.nameOf.toString
				])»
					JMP +«IF statement.^else !== null»«statement.^else.nameOfCondition»«ELSE»«endIf»«ENDIF»
				+«statement.nameOf»:
				«FOR stmt : statement.body.statements»
					«stmt.compile(new CompileData => [
						container = data.container
						operation = data.operation
					])»
				«ENDFOR»
				«IF statement.^else !== null»
					«noop»
						JMP +«endIf»
					«statement.^else.compile(data)»
				«ENDIF»
				«IF mainIf == statement»
					+«endIf»:
				«ENDIF»
			'''
			ForStatement: '''
				«val forCondition = statement.nameOfCondition»
				«val forIteration = statement.nameOfIteration»
				«val forEnd = statement.nameOfEnd»
				+«statement.nameOf»:
				«FOR variable : statement.variables»
					«variable.compile(new CompileData => [
						container = data.container
						operation = data.operation
					])»
				«ENDFOR»
				-«forCondition»:
				«IF statement.condition !== null»
					«statement.condition.compile(new CompileData => [
						container = data.container
						operation = data.operation
						type = statement.condition.typeOf
						relative = forIteration.toString
					])»
						JMP +«forEnd»:
				«ENDIF»
				+«forIteration»:
				«FOR stmt : statement.body.statements»
					«stmt.compile(new CompileData => [
						container = data.container
						operation = data.operation
					])»
				«ENDFOR»
				+«statement.nameOfEvaluation»:
				«FOR expression : statement.expressions»
					«expression.compile(new CompileData => [
						container = data.container
						operation = data.operation
					])»
				«ENDFOR»
					JMP -«forCondition»:
				+«forEnd»:
			'''
			ForeverStatement: '''
				«val foreverLoop = statement.nameOf»
				-«foreverLoop»:
				«FOR stmt : statement.body.statements»
					«stmt.compile(new CompileData => [
						container = data.container
						operation = data.operation
					])»
				«ENDFOR»
					JMP -«foreverLoop»:
				+«statement.nameOfEnd»:
			'''
			ContinueStatement: '''
				«val forContainer = statement.forContainer»
					«IF forContainer !== null»
						«IF forContainer instanceof ForStatement»
							JMP +«forContainer.nameOfEvaluation»:
						«ELSEIF forContainer instanceof ForeverStatement»
							JMP -«(forContainer as ForeverStatement).nameOf»:
						«ENDIF»
					«ENDIF»
			'''
			BreakStatement: '''
				«val forContainer = statement.forContainer»
					«IF forContainer !== null»
						«IF forContainer instanceof ForStatement»
							JMP +«forContainer.nameOfEnd»:
						«ELSEIF forContainer instanceof ForeverStatement»
							JMP +«(forContainer as ForeverStatement).nameOfEnd»:
						«ENDIF»
					«ENDIF»
			'''
			ReturnStatement: '''
				«val method = statement.method»
				«IF statement.isNonVoid»
					«statement.value.compile(new CompileData => [
						container = method.nameOf
						operation = data.operation
						type = statement.method.typeOf
						
						if (type.isPrimitive && statement.method.dimensionOf.isEmpty) {
							absolute = method.nameOfReturn
							mode = Mode::COPY
						} else {
							indirect = method.nameOfReturn
							mode = Mode::POINT
						}
					])»
				«ELSEIF statement.value !== null»
					«statement.value.compile(new CompileData => [
						container = method.nameOf
						operation = data.operation
						type = statement.value.typeOf
					])»
				«ENDIF»
			'''
			AsmStatement:
				if (statement.vars.isEmpty) {
					statement.codes.join('', [substring(1, length - 1)])
				} else {
					val i = new AtomicInteger

					statement.codes.reduce [ c1, c2 |
						val c1Ini = if (c1.startsWith('!') || c1.startsWith('?')) 1 else 0
						val c1End = if (c1.endsWith('!') || c1.endsWith('?')) c1.length - 1 else c1.length
						val c2Ini = if (c2.startsWith('!') || c2.startsWith('?')) 1 else 0
						val c2End = if (c2.endsWith('!') || c2.endsWith('?')) c2.length - 1 else c2.length
						
						c1.substring(c1Ini, c1End) + statement.vars.get(i.andIncrement).nameOf + c2.substring(c2Ini, c2End)
					]
				}
			Expression:
				statement.compile(data)
			default:
				''
		}
	}

	def compile(ElseStatement elseStatement, CompileData data) '''
		«IF elseStatement.^if !== null»
			«elseStatement.^if.compile(data)»
		«ELSE»
			+«elseStatement.nameOf»:
			«FOR stmt : elseStatement.body?.statements»
				«stmt.compile(data)»
			«ENDFOR»
		«ENDIF»
	'''

	private def void noop() {
	}
}
