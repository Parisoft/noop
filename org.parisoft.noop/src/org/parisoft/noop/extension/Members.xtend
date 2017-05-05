package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.locks.ReentrantLock
import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*

public class Members {

	public static val CONSTANT_SUFFIX = '#'

	@Inject extension Classes
	@Inject extension Expressions

	val methodTypeLock = new ReentrantLock

	def isAccessibleFrom(Member member, EObject context) {
		val contextClass = if (context instanceof MemberSelection) context.receiver.typeOf else context.containingClass
		val memberClass = member.containingClass

		contextClass == memberClass || contextClass.isSubclassOf(memberClass)
	}

	def isConstant(Variable variable) {
		variable.name.startsWith(CONSTANT_SUFFIX)
	}

	def isNonConstant(Variable variable) {
		!variable.isConstant
	}

	def typeOf(Member member) {
		switch (member) {
			Variable: member.typeOf
			Method: member.typeOf
		}
	}

	def typeOf(Variable variable) {
		if (variable.type !== null) {
			variable.type
		} else if (variable.value instanceof MemberRef && (variable.value as MemberRef).member === variable) {
			TypeSystem::TYPE_VOID
		} else {
			variable.value.typeOf
		}
	}

	def typeOf(Method method) {
		if (methodTypeLock.tryLock) {
			try {
				method.body.getAllContentsOfType(ReturnStatement).map[value.typeOf].filterNull.toSet.merge
			} finally {
				methodTypeLock.unlock
			}
		}
	}

	def valueOf(Member member) {
		if (member instanceof Variable) {
			if (member.isConstant) {
				return member.value.valueOf
			}
		}

		throw new NonConstantMemberException
	}
}
