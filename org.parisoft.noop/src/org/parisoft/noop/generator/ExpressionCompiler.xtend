package org.parisoft.noop.generator

import com.google.inject.Inject
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.BAndExpression
import org.parisoft.noop.noop.BOrExpression
import org.parisoft.noop.noop.ByteLiteral
import org.parisoft.noop.noop.DecExpression
import org.parisoft.noop.noop.DifferExpression
import org.parisoft.noop.noop.DivExpression
import org.parisoft.noop.noop.EorExpression
import org.parisoft.noop.noop.EqualsExpression
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.GeExpression
import org.parisoft.noop.noop.GtExpression
import org.parisoft.noop.noop.IncExpression
import org.parisoft.noop.noop.LShiftExpression
import org.parisoft.noop.noop.LeExpression
import org.parisoft.noop.noop.LtExpression
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.MulExpression
import org.parisoft.noop.noop.NotExpression
import org.parisoft.noop.noop.OrExpression
import org.parisoft.noop.noop.RShiftExpression
import org.parisoft.noop.noop.SigNegExpression
import org.parisoft.noop.noop.SigPosExpression
import org.parisoft.noop.noop.SubExpression
import org.parisoft.noop.noop.BoolLiteral
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.Variable
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.Statement

class ExpressionCompiler {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension Expressions
	@Inject extension MethodCompiler

	def void prepare(Expression expression, MetaData data) {
		switch (expression) {
			AssignmentExpression: {
				expression.right.prepare(data)
			}
			OrExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			AndExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			EqualsExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			DifferExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			GtExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			GeExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			LtExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			LeExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			AddExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			SubExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			MulExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			DivExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			BOrExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			BAndExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			LShiftExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			RShiftExpression: {
				expression.left.prepare(data)
				expression.right.prepare(data)
			}
			EorExpression: {
				expression.right.prepare(data)
			}
			NotExpression: {
				expression.right.prepare(data)
			}
			SigNegExpression: {
				expression.right.prepare(data)
			}
			SigPosExpression: {
				expression.right.prepare(data)
			}
			DecExpression: {
				expression.right.prepare(data)
			}
			IncExpression: {
				expression.right.prepare(data)
			}
			MemberSelection: {
				val ptrCounter = data.ptrCounter
				val varCounter = data.varCounter
				val member = expression.member

				expression.receiver.prepareTemp(data)

				if (expression.isMethodInvocation) {
					(member as Method).prepare(data)
					expression.args.forEach[prepareTemp(data)]
				} else if (expression.isInstanceOf || expression.isCast) {
					data.classes.add(expression.type)
				} else if (member instanceof Variable) {
					if (member.isConstant && member.typeOf.isPrimitive) {
						data.constants.add(member)
					} else if (member.typeOf.isSingleton) {
						data.singletons.add(member.typeOf)
					}
				}

				data.ptrCounter = ptrCounter
				data.varCounter = varCounter
			}
			MemberRef: {
				val ptrCounter = data.ptrCounter
				val varCounter = data.varCounter
				val member = expression.member

				if (expression.isMethodInvocation) {
					(member as Method).prepare(data)
					expression.args.forEach[prepareTemp(data)]
				} else if (member instanceof Variable) {
					if (member.isConstant && member.nonROM && member.typeOf.isPrimitive) {
						data.constants.add(member)
					} else if (member.typeOf.isSingleton) {
						data.singletons.add(member.typeOf)
					}
				}

				data.ptrCounter = ptrCounter
				data.varCounter = varCounter
			}
		}
	}

	private def prepareTemp(Expression expression, MetaData data) {
		switch (expression) {
			ByteLiteral:
				expression.allocTemp(data)
			BoolLiteral:
				expression.allocTemp(data)
			StringLiteral:
				expression.allocTemp(data)
			ArrayLiteral:
				expression.allocTemp(data)
			NewInstance:
				expression.allocTemp(data)
			default:
				expression.prepare(data)
		}
	}

	private def allocTemp(Expression expression, MetaData data) {
		val size = expression.typeOf.sizeOf * (expression.dimensionOf.reduce[d1, d2|d1 * d2] ?: 1)
		val mem = new MemChunk(data.varCounter, size)
		val container = expression.getContainerOfType(Statement)
		data.temps.put(container, mem)
		data.varCounter = mem.lastVarAddr
	}

}
