package org.parisoft.noop.generator

import com.google.inject.Inject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
import org.parisoft.noop.noop.ArrayLiteral
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.BAndExpression
import org.parisoft.noop.noop.BOrExpression
import org.parisoft.noop.noop.BoolLiteral
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
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopFactory
import org.parisoft.noop.noop.NotExpression
import org.parisoft.noop.noop.OrExpression
import org.parisoft.noop.noop.RShiftExpression
import org.parisoft.noop.noop.SigNegExpression
import org.parisoft.noop.noop.SigPosExpression
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.SubExpression
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*

class ExpressionCompiler {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension Expressions
	@Inject extension IQualifiedNameProvider
	@Inject extension MethodCompiler

	def void alloc(Expression expression, MetaData data) {
		switch (expression) {
			AssignmentExpression: {
				expression.right.alloc(data)
			}
			OrExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			AndExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			EqualsExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			DifferExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			GtExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			GeExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			LtExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			LeExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			AddExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			SubExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			MulExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			DivExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			BOrExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			BAndExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			LShiftExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			RShiftExpression: {
				expression.left.alloc(data)
				expression.right.alloc(data)
			}
			EorExpression: {
				expression.right.alloc(data)
			}
			NotExpression: {
				expression.right.alloc(data)
			}
			SigNegExpression: {
				expression.right.alloc(data)
			}
			SigPosExpression: {
				expression.right.alloc(data)
			}
			DecExpression: {
				expression.right.alloc(data)
			}
			IncExpression: {
				expression.right.alloc(data)
			}
			MemberSelection: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get
				val method = expression.getContainerOfType(Method)
				val member = expression.member
				val receiver = expression.receiver

				if (receiver instanceof ByteLiteral || receiver instanceof BoolLiteral || receiver instanceof StringLiteral ||
					receiver instanceof ArrayLiteral || receiver instanceof NewInstance) {
					data.variables.get(method).put(NoopFactory::eINSTANCE.createVariable => [
						name = method.fullyQualifiedName.toString + '.tmp' + data.tmpCounter.andIncrement
					], data.chunkForVar(receiver.sizeOf))
				} else {
					receiver.alloc(data)
				}

				if (expression.isMethodInvocation) {
					(member as Method).alloc(data)
					expression.args.reject[
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach[alloc(data)]
					expression.args.filter [
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach [ arg |
						data.variables.get(method).put(NoopFactory::eINSTANCE.createVariable => [
							name = method.fullyQualifiedName.toString + '.tmp' + data.tmpCounter.andIncrement
						], data.chunkForVar(arg.sizeOf))
					]
				} else if (expression.isInstanceOf || expression.isCast) {
					data.classes.add(expression.type)
				} else if (member instanceof Variable) {
					if (member.isConstant && member.nonROM && member.typeOf.isPrimitive) {
						data.constants.add(member)
					} else if (member.typeOf.isSingleton) {
						data.singletons.add(member.typeOf)
					}
				}

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
			MemberRef: {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get
				val method = expression.getContainerOfType(Method)
				val member = expression.member

				if (expression.isMethodInvocation) {
					(member as Method).alloc(data)
					expression.args.reject[
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach[alloc(data)]
					expression.args.filter [
						it instanceof ArrayLiteral || it instanceof NewInstance
					].forEach [ arg |
						data.variables.get(method).put(NoopFactory::eINSTANCE.createVariable => [
							name = method.fullyQualifiedName.toString + '.tmp' + data.tmpCounter.andIncrement
						], data.chunkForVar(arg.sizeOf))
					]
				} else if (member instanceof Variable) {
					if (member.isConstant && member.nonROM && member.typeOf.isPrimitive) {
						data.constants.add(member)
					} else if (member.typeOf.isSingleton) {
						data.singletons.add(member.typeOf)
					}
				}

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
			}
		}
	}

}
