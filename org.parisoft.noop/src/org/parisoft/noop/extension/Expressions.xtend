package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.stream.Collectors
import org.parisoft.noop.exception.InvalidExpressionException
import org.parisoft.noop.exception.NonConstantExpressionException
import org.parisoft.noop.exception.NonConstantMemberException
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

class Expressions {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension TypeSystem

	def NoopClass typeOf(Expression expression) {
		if (expression === null) {
			return TypeSystem::TYPE_VOID
		}

		switch (expression) {
			AssignmentExpression:
				expression.left.typeOf
			MemberSelection:
				if (expression.isInstanceOf) {
					expression.toBoolClass
				} else if (expression.isCast) {
					expression.type
				} else {
					expression.member.typeOf
				}
			OrExpression:
				expression.toBoolClass
			AndExpression:
				expression.toBoolClass
			EqualsExpression:
				expression.toBoolClass
			DifferExpression:
				expression.toBoolClass
			GtExpression:
				expression.toBoolClass
			GeExpression:
				expression.toBoolClass
			LtExpression:
				expression.toBoolClass
			LeExpression:
				expression.toBoolClass
			AddExpression:
				expression.typeOfValueOrInt
			SubExpression:
				expression.typeOfValueOrInt
			MulExpression:
				expression.typeOfValueOrInt
			DivExpression:
				expression.typeOfValueOrInt
			BOrExpression:
				expression.typeOfValueOrInt
			BAndExpression:
				expression.typeOfValueOrInt
			LShiftExpression:
				expression.typeOfValueOrInt
			RShiftExpression:
				expression.typeOfValueOrInt
			EorExpression:
				expression.typeOfValueOrInt
			NotExpression:
				expression.toBoolClass
			SigNegExpression:
				expression.typeOfValueOrInt
			SigPosExpression:
				expression.typeOfValueOrInt
			DecExpression:
				expression.toIntClass
			IncExpression:
				expression.toIntClass
			ByteLiteral:
				if (expression.value > TypeSystem::MAX_INT) {
					expression.toUIntClass
				} else if (expression.value > TypeSystem::MAX_UBYTE) {
					expression.toIntClass
				} else if (expression.value > TypeSystem::MAX_BYTE) {
					expression.toUByteClass
				} else if (expression.value < TypeSystem::MIN_BYTE) {
					expression.toIntClass
				} else if (expression.value < TypeSystem::MIN_UBYTE) {
					expression.toByteClass
				} else {
					expression.toUByteClass
				}
			BoolLiteral:
				expression.toBoolClass
			ArrayLiteral:
				if (expression.values.isEmpty) {
					expression.toObjectClass
				} else {
					expression.values.map[it.typeOf].merge
				}
			StringLiteral:
				expression.toUByteClass
			This:
				expression.containingClass
			Super:
				expression.containingClass.superClassOrObject
			NewInstance:
				expression.type
			InjectInstance:
				expression.type
			MemberRef:
				expression.member.typeOf
		}
	}

	private def typeOfValueOrInt(Expression expression) {
		try {
			val value = expression.valueOf as Integer

			if (value > TypeSystem::MAX_INT) {
				expression.toUIntClass
			} else if (value > TypeSystem::MAX_UBYTE) {
				expression.toIntClass
			} else if (value > TypeSystem::MAX_BYTE) {
				expression.toUByteClass
			} else if (value < TypeSystem::MIN_BYTE) {
				expression.toIntClass
			} else if (value < TypeSystem::MIN_UBYTE) {
				expression.toByteClass
			} else {
				expression.toUByteClass
			}
		} catch (Exception e) {
			expression.toIntClass
		}
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
						expression.receiver
					} else {
						expression.member.valueOf
					}
				OrExpression:
					(expression.left.valueOf as Boolean) || (expression.right.valueOf as Boolean)
				AndExpression:
					(expression.left.valueOf as Boolean) && (expression.right.valueOf as Boolean)
				EqualsExpression:
					if (expression.left.typeOf.isNumber) {
						expression.right.typeOf.isNumber && expression.left.valueOf === expression.right.valueOf
					} else if (expression.left.typeOf.isBool) {
						expression.right.typeOf.isBool && expression.left.valueOf === expression.right.valueOf
					} else {
						throw new NonConstantExpressionException(expression)
					}
				DifferExpression:
					if (expression.left.typeOf.isNumber) {
						!expression.right.typeOf.isNumber || expression.left.valueOf !== expression.right.valueOf
					} else if (expression.left.typeOf.isBool) {
						!expression.right.typeOf.isBool || expression.left.valueOf !== expression.right.valueOf
					} else {
						throw new NonConstantExpressionException(expression)
					}
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
				ArrayLiteral:
					expression.values.map[it.valueOf]
				StringLiteral:
					expression.value.chars.boxed.collect(Collectors.toList)
				NewInstance:
					if (expression.type.isNumber) {
						0
					} else if (expression.type.isBool) {
						false
					} else {
						expression.type
					}
				InjectInstance:
					if (expression.type.isNumber) {
						0
					} else if (expression.type.isBool) {
						false
					} else {
						expression.type
					}
				MemberRef:
					expression.member.valueOf
				default:
//				DecExpression:
//				IncExpression:
//			    This: 
//			    Super:
					throw new NonConstantExpressionException(expression)
			}
		} catch (NonConstantMemberException e) {
			throw new NonConstantExpressionException(expression)
		} catch (ClassCastException e) {
			throw new InvalidExpressionException(expression)
		}
	}

}
