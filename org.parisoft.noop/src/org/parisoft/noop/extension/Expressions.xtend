package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.parisoft.noop.noop.AddExpression
import org.parisoft.noop.noop.AndExpression
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.BAndExpression
import org.parisoft.noop.noop.BOrExpression
import org.parisoft.noop.noop.BoolLiteral
import org.parisoft.noop.noop.ByteLiteral
import org.parisoft.noop.noop.CharLiteral
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
			AssignmentExpression: expression.left.typeOf
			MemberSelection: expression.typeOf
			OrExpression: expression.boolType
			AndExpression: expression.boolType
			EqualsExpression: expression.boolType
			DifferExpression: expression.boolType
			GtExpression: expression.boolType
			GeExpression: expression.boolType
			LtExpression: expression.boolType
			LeExpression: expression.boolType
			AddExpression: TypeSystem::TYPE_INT
			SubExpression: TypeSystem::TYPE_INT
			MulExpression: TypeSystem::TYPE_INT
			DivExpression: TypeSystem::TYPE_INT
			BOrExpression: TypeSystem::TYPE_CHAR
			BAndExpression: TypeSystem::TYPE_CHAR
			LShiftExpression: TypeSystem::TYPE_CHAR
			RShiftExpression: TypeSystem::TYPE_CHAR
			EorExpression: TypeSystem::TYPE_CHAR
			NotExpression: expression.boolType
			SigNegExpression: TypeSystem::TYPE_INT
			SigPosExpression: TypeSystem::TYPE_INT
			DecExpression: TypeSystem::TYPE_INT
			IncExpression: TypeSystem::TYPE_INT
			ByteLiteral: expression.typeOf
			BoolLiteral: expression.boolType
			CharLiteral: TypeSystem::TYPE_CHAR
			This: expression.containingClass
			Super: expression.containingClass.superClassOrObject
			NewInstance: expression.type
			InjectInstance: expression.type
			MemberRef: expression.member.typeOf
		}
	}

	def typeOf(ByteLiteral b) {
		if (b.value > TypeSystem::MAX_INT) {
			return TypeSystem::TYPE_UINT
		}

		if (b.value > TypeSystem::MAX_CHAR) {
			return TypeSystem::TYPE_INT
		}

		if (b.value > TypeSystem::MAX_BYTE) {
			return TypeSystem::TYPE_CHAR
		}

		if (b.value < TypeSystem::MIN_BYTE) {
			return TypeSystem::TYPE_INT
		}

		if (b.value < 0) {
			return TypeSystem::TYPE_BYTE
		}

		return TypeSystem::TYPE_CHAR
	}

	def typeOf(MemberSelection selection) {
		if (selection.isInstanceOf) {
			return selection.boolType
		}

		if (selection.isCast) {
			return selection.type
		}

		return selection.member.typeOf
	}

}
