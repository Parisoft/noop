package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
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
import org.parisoft.noop.noop.IncludeFile
import org.parisoft.noop.noop.InjectInstance
import org.parisoft.noop.noop.LShiftExpression
import org.parisoft.noop.noop.LeExpression
import org.parisoft.noop.noop.LtExpression
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.noop.MulExpression
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NotExpression
import org.parisoft.noop.noop.OrExpression
import org.parisoft.noop.noop.RShiftExpression
import org.parisoft.noop.noop.SigNegExpression
import org.parisoft.noop.noop.SigPosExpression
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.SubExpression
import org.parisoft.noop.noop.Super
import org.parisoft.noop.noop.This
import java.util.stream.Collectors
import org.parisoft.noop.exception.NonConstantMemberException

class Expressions {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension TypeSystem

	def NoopClass typeOf(Expression expression) {
		if (expression === null) {
			return TypeSystem::TYPE_VOID
		}

		switch (expression) {
			AssignmentExpression: expression.left.typeOf
			MemberSelection: expression.typeOf
			OrExpression: expression.toBoolClass
			AndExpression: expression.toBoolClass
			EqualsExpression: expression.toBoolClass
			DifferExpression: expression.toBoolClass
			GtExpression: expression.toBoolClass
			GeExpression: expression.toBoolClass
			LtExpression: expression.toBoolClass
			LeExpression: expression.toBoolClass
			AddExpression: expression.toIntClass
			SubExpression: expression.toIntClass
			MulExpression: expression.toIntClass
			DivExpression: expression.toIntClass
			BOrExpression: expression.toUByteClass
			BAndExpression: expression.toUByteClass
			LShiftExpression: expression.toUByteClass
			RShiftExpression: expression.toUByteClass
			EorExpression: expression.toUByteClass
			NotExpression: expression.toBoolClass
			SigNegExpression: expression.toIntClass
			SigPosExpression: expression.toIntClass
			DecExpression: expression.toIntClass
			IncExpression: expression.toIntClass
			ByteLiteral: expression.typeOf
			BoolLiteral: expression.toBoolClass
//			ArrayLiteral: 
			StringLiteral: expression.toUByteClass
			This: expression.containingClass
			Super: expression.containingClass.superClassOrObject
			NewInstance: expression.type
			InjectInstance: expression.type
			IncludeFile: expression.toUByteClass
			MemberRef: expression.member.typeOf
		}
	}

	private def typeOf(ByteLiteral b) {
		if (b.value > TypeSystem::MAX_INT) {
			return b.toUIntClass
		}

		if (b.value > TypeSystem::MAX_UBYTE) {
			return b.toIntClass
		}

		if (b.value > TypeSystem::MAX_BYTE) {
			return b.toUByteClass
		}

		if (b.value < TypeSystem::MIN_BYTE) {
			return b.toIntClass
		}

		if (b.value < 0) {
			return b.toByteClass
		}

		return b.toUByteClass
	}

	private def typeOf(MemberSelection selection) {
		if (selection.isInstanceOf) {
			return selection.toBoolClass
		}

		if (selection.isCast) {
			return selection.type
		}

		return selection.member.typeOf
	}

	def Object valueOf(Expression expression) {
		try {
			switch (expression) {
				AssignmentExpression:
					expression.right.valueOf
				MemberSelection:
					if (expression.isInstanceOf) {
						throw new NonConstantExpressionException(expression)
					} else if (expression.isCast) {
						return expression.receiver
					} else {
						return expression.member.valueOf
					}
				OrExpression:
					(expression.left.valueOf as Boolean) || (expression.right.valueOf as Boolean)
				AndExpression:
					(expression.left.valueOf as Boolean) && (expression.right.valueOf as Boolean)
				EqualsExpression:
					expression.left.valueOf == expression.right.valueOf
				DifferExpression:
					expression.left.valueOf != expression.right.valueOf
				GtExpression:
					(expression.left.valueOf as Integer) > (expression.right.valueOf as Integer)
				GeExpression:
					(expression.left.valueOf as Integer) >= (expression.right.valueOf as Integer)
				LtExpression:
					(expression.left.valueOf as Integer) < (expression.right.valueOf as Integer)
				LeExpression:
					(expression.left.valueOf as Integer) <= (expression.right.valueOf as Integer)
				AddExpression:
					(expression.left.valueOf as Integer) + (expression.right.valueOf as Integer)
				SubExpression:
					(expression.left.valueOf as Integer) - (expression.right.valueOf as Integer)
				MulExpression:
					(expression.left.valueOf as Integer) * (expression.right.valueOf as Integer)
				DivExpression:
					(expression.left.valueOf as Integer) / (expression.right.valueOf as Integer)
				BOrExpression:
					(expression.left.valueOf as Integer).bitwiseOr(expression.right.valueOf as Integer)
				BAndExpression:
					(expression.left.valueOf as Integer).bitwiseAnd(expression.right.valueOf as Integer)
				LShiftExpression:
					(expression.left.valueOf as Integer) << (expression.right.valueOf as Integer)
				RShiftExpression:
					(expression.left.valueOf as Integer) >> (expression.right.valueOf as Integer)
				EorExpression:
					(expression.right.valueOf as Integer).bitwiseNot
				NotExpression:
					!(expression.right.valueOf as Boolean)
				SigNegExpression:
					-(expression.right.valueOf as Integer)
				SigPosExpression:
					(expression.right.valueOf as Integer)
				ByteLiteral:
					expression.value
				BoolLiteral:
					expression.value
//			    ArrayLiteral: 
				StringLiteral:
					expression.value.chars.boxed.collect(Collectors.toList)
				MemberRef:
					expression.member.valueOf
				default:
//				DecExpression:
//				IncExpression:
//			    This: 
//			    Super:
//			    NewInstance: 
//			    InjectInstance:
//			    IncludeFile: 
					throw new NonConstantExpressionException(expression)
			}
		} catch (NonConstantMemberException e) {
			throw new NonConstantExpressionException(expression)
		} catch (ClassCastException e) {
			throw new InvalidExpressionException(expression)
		}
	}

}
