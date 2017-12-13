package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.CompileContext.Mode
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
		'''«ifStatement.nameOf».condition'''
	}

	def nameOfEnd(IfStatement ifStatement) {
		'''«ifStatement.nameOf».end'''
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
		'''«forever.nameOf».end'''
	}

	def nameOf(ForStatement forStatement) {
		'''for@«forStatement.hashCode.toHexString»'''
	}

	def nameOfCondition(ForStatement forStatement) {
		'''«forStatement.nameOf».condition'''
	}

	def nameOfEvaluation(ForStatement forStatement) {
		'''«forStatement.nameOf».evaluation'''
	}

	def nameOfIteration(ForStatement forStatement) {
		'''«forStatement.nameOf».iteration'''
	}

	def nameOfEnd(ForStatement forStatement) {
		'''«forStatement.nameOf».end'''
	}
	
	def dimensionOf(ReturnStatement returnStatement) {
		return returnStatement?.value?.dimensionOf ?: emptyList
	}

	def void prepare(Statement statement, AllocContext ctx) {
		switch (statement) {
			Variable: {
				statement.value?.prepare(ctx)

				if (statement.isConstant) {
					ctx.constants.put(statement.nameOfConstant, statement)
				} else if (statement.isROM) {
					if (statement.storage.type == StorageType.PRGROM) {
						ctx.prgRoms.put(statement.nameOfStatic, statement)
					} else if (statement.storage.type == StorageType.CHRROM) {
						ctx.chrRoms.put(statement.nameOfStatic, statement)
					}
				} else if (statement.isStatic && statement.typeOf.isNonINESHeader) {
					ctx.statics.put(statement.nameOfStatic, statement)
				}
			}
			IfStatement: {
				statement.condition.prepare(ctx)
				statement.body.statements.forEach[prepare(ctx)]
				statement.^else?.prepare(ctx)
			}
			ForStatement: {
				statement.variables.forEach[prepare(ctx)]
				statement.assignments.forEach[prepare(ctx)]
				statement.condition?.prepare(ctx)
				statement.expressions.forEach[prepare(ctx)]
				statement.body.statements.forEach[prepare(ctx)]
			}
			ForeverStatement: {
				statement.body.statements.forEach[prepare(ctx)]
			}
			AsmStatement: {
				statement.vars.forEach[prepare(ctx)]
			}
			ReturnStatement: {
				statement.value?.prepare(ctx)
			}
			Expression: {
				statement.prepare(ctx)
			}
		}
	}

	def prepare(ElseStatement elseStatement, AllocContext ctx) {
		if (elseStatement.^if !== null) {
			elseStatement.^if.prepare(ctx)
		} else if (elseStatement.body !== null) {
			elseStatement.body.statements.forEach[prepare(ctx)]
		}
	}

	def List<MemChunk> alloc(Statement statement, AllocContext ctx) {
		switch (statement) {
			Variable: {
				val name = statement.nameOf(ctx.container)
				val chunks = newArrayList

				if (statement.isParameter && (statement.type.isNonPrimitive || statement.dimensionOf.isNotEmpty)) {
					chunks += ctx.computePtr(name)

					if (statement.isUnbounded) {
						for (i : 0 ..< statement.dimensionOf.size) {
							chunks += ctx.computeVar(statement.nameOfLen(ctx.container, i), 2)
						}
					}
				} else if (statement.isNonStatic) {
					val page = statement?.storage?.location?.valueOf as Integer ?: Datas::VAR_PAGE
					chunks += ctx.computeVar(name, page, statement.sizeOf)
				}

				return (chunks + statement?.value.alloc(ctx)).filterNull.toList
			}
			IfStatement: {
				val snapshot = ctx.snapshot
				val chunks = statement.condition.alloc(ctx) + statement.body.statements.map[alloc(ctx)].flatten

				chunks.disoverlap(ctx.container)

				ctx.restoreTo(snapshot)

				return (chunks + (statement?.^else?.alloc(ctx) ?: emptyList)).filterNull.toList
			}
			ForStatement: {
				val snapshot = ctx.snapshot
				val chunks = statement.variables.map[alloc(ctx)].flatten.toList
				chunks += statement.assignments.map[alloc(ctx)].flatten
				chunks += statement.condition?.alloc(ctx)
				chunks += statement.expressions.map[alloc(ctx)].flatten
				chunks += statement.body.statements.map[alloc(ctx)].flatten
				chunks.disoverlap(ctx.container)

				ctx.restoreTo(snapshot)

				return chunks.filterNull.toList
			}
			ForeverStatement: {
				val snapshot = ctx.snapshot
				val chunks = statement.body.statements.map[alloc(ctx)].flatten

				chunks.disoverlap(ctx.container)

				ctx.restoreTo(snapshot)

				return chunks.toList
			}
			ReturnStatement: {
				val chunks = newArrayList

				if (statement.isNonVoid) {
					chunks += ctx.computePtr(statement.nameOf)
				}

				chunks += statement.value?.alloc(ctx)

				return chunks.filterNull.toList
			}
			Expression:
				statement.alloc(ctx)
			default:
				newArrayList
		}
	}

	def alloc(ElseStatement statement, AllocContext ctx) {
		if (statement.^if !== null) {
			return statement.^if.alloc(ctx)
		}

		val snapshot = ctx.snapshot
		val chunks = statement.body.statements.map[alloc(ctx)].flatten

		chunks.disoverlap(ctx.container)
		ctx.restoreTo(snapshot)

		return chunks

	}

	def String compile(Statement statement, CompileContext ctx) {
		switch (statement) {
			Variable: '''
				«IF statement.isROM»
					«statement.value.compile(ctx => [
						db = statement.nameOfStatic
						type = statement.typeOf
					])»
				«ELSEIF ctx.absolute !== null»
					«statement.value.compile(ctx => [
						absolute = '''«ctx.absolute» + #«statement.nameOfOffset»'''
						type = statement.typeOf
					])»
				«ELSEIF ctx.indirect !== null»
					«statement.value.compile(ctx => [
						index = '''#«statement.nameOfOffset»'''
						type = statement.typeOf
					])»
				«ELSE»
					«statement.value.compile(ctx => [
						absolute = statement.nameOf(ctx.container)
						type = statement.typeOf
					])»
				«ENDIF»
			'''
			IfStatement: '''
				«val mainIf = statement.ifContainer»
				«val endIf = mainIf.nameOfEnd»
				+«statement.nameOfCondition»:
				«statement.condition.compile(new CompileContext => [
					container = ctx.container
					operation = ctx.operation
					type = statement.condition.typeOf
					relative = statement.nameOf.toString
				])»
					JMP +«IF statement.^else !== null»«statement.^else.nameOfCondition»«ELSE»«endIf»«ENDIF»
				+«statement.nameOf»:
				«FOR stmt : statement.body.statements»
					«stmt.compile(new CompileContext => [
						container = ctx.container
						operation = ctx.operation
					])»
				«ENDFOR»
				«IF statement.^else !== null»
					«noop»
						JMP +«endIf»
					«statement.^else.compile(ctx)»
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
					«variable.compile(new CompileContext => [
						container = ctx.container
						operation = ctx.operation
					])»
				«ENDFOR»
				-«forCondition»:
				«IF statement.condition !== null»
					«statement.condition.compile(new CompileContext => [
						container = ctx.container
						operation = ctx.operation
						type = statement.condition.typeOf
						relative = forIteration.toString
					])»
						JMP +«forEnd»:
				«ENDIF»
				+«forIteration»:
				«FOR stmt : statement.body.statements»
					«stmt.compile(new CompileContext => [
						container = ctx.container
						operation = ctx.operation
					])»
				«ENDFOR»
				+«statement.nameOfEvaluation»:
				«FOR expression : statement.expressions»
					«expression.compile(new CompileContext => [
						container = ctx.container
						operation = ctx.operation
					])»
				«ENDFOR»
					JMP -«forCondition»:
				+«forEnd»:
			'''
			ForeverStatement: '''
				«val foreverLoop = statement.nameOf»
				-«foreverLoop»:
				«FOR stmt : statement.body.statements»
					«stmt.compile(new CompileContext => [
						container = ctx.container
						operation = ctx.operation
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
					«statement.value.compile(new CompileContext => [
						container = method.nameOf
						operation = ctx.operation
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
					«statement.value.compile(new CompileContext => [
						container = method.nameOf
						operation = ctx.operation
						type = statement.value.typeOf
					])»
				«ENDIF»
					RTS
			'''
			AsmStatement:
				if (statement.vars.isEmpty) {
					statement.codes.join('', [substring(1, length - 1)])
				} else {
					val i = new AtomicInteger

					statement.codes.reduce [ c1, c2 |
						val c1Ini = if(c1.startsWith('!') || c1.startsWith('?')) 1 else 0
						val c1End = if(c1.endsWith('!') || c1.endsWith('?')) c1.length - 1 else c1.length
						val c2Ini = if(c2.startsWith('!') || c2.startsWith('?')) 1 else 0
						val c2End = if(c2.endsWith('!') || c2.endsWith('?')) c2.length - 1 else c2.length

						c1.substring(c1Ini, c1End) + statement.vars.get(i.andIncrement).nameOf +
							c2.substring(c2Ini, c2End)
					]
				}
			Expression:
				statement.compile(ctx)
			default:
				''
		}
	}

	def compile(ElseStatement elseStatement, CompileContext ctx) '''
		«IF elseStatement.^if !== null»
			«elseStatement.^if.compile(ctx)»
		«ELSE»
			+«elseStatement.nameOf»:
			«FOR stmt : elseStatement.body?.statements»
				«stmt.compile(ctx)»
			«ENDFOR»
		«ENDIF»
	'''

	private def void noop() {
	}
}
