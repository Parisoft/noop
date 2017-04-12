package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.parisoft.noop.noop.BoolLiteral
import org.parisoft.noop.noop.ByteLiteral
import org.parisoft.noop.noop.CharLiteral
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.New
import org.parisoft.noop.noop.Super
import org.parisoft.noop.noop.This
import org.parisoft.noop.noop.VarRef

import static extension org.parisoft.noop.^extension.Classes.*
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.SelectionExpression

class Expressions {

	@Inject extension Classes
	@Inject extension Members

	def NoopClass typeOf(Expression expression) {
		if(expression === null) {
			return TypeSystem::TYPE_VOID
		}

		switch (expression) {
			AssignmentExpression: expression.left.typeOf
			SelectionExpression: expression.typeOf
			ByteLiteral: expression.typeOf
			BoolLiteral: TypeSystem::TYPE_BOOL
			CharLiteral: TypeSystem::TYPE_CHAR
			This: expression.containingClass
			Super: expression.containingClass.superClassOrObject
			New: expression.type
			org.parisoft.noop.noop.Inject: expression.type
			VarRef: expression.variable.typeOf
		}
	}

	def typeOf(SelectionExpression selection) {
		if(selection.isInstanceOf) {
			return TypeSystem::TYPE_BOOL
		}

		if(selection.isCast) {
			return selection.type
		}

		return selection.member.typeOf
	}

	def typeOf(ByteLiteral b) {
		if(b.value > TypeSystem::MAX_INT) {
			return TypeSystem::TYPE_UINT
		}

		if(b.value > TypeSystem::MAX_UBYTE) {
			return TypeSystem::TYPE_INT
		}

		if(b.value > TypeSystem::MAX_BYTE) {
			return TypeSystem::TYPE_UBYTE
		}

		if(b.value < TypeSystem::MIN_BYTE) {
			return TypeSystem::TYPE_INT
		}

		if(b.value < 0) {
			return TypeSystem::TYPE_BYTE
		}

		return TypeSystem::TYPE_UBYTE
	}
}
