package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.exception.NonConstantMemberException
import java.util.WeakHashMap

public class Members {

	static val typeCache = new WeakHashMap<Member, NoopClass>
	
	@Inject extension Classes
	@Inject extension Expressions

	def isAccessibleFrom(Member member, EObject context) {
		val contextClass = if (context instanceof MemberSelection) context.receiver.typeOf else context.containingClass
		val memberClass = member.containingClass

		contextClass == memberClass || contextClass.isSubclassOf(memberClass)
	}

	def isConstant(Variable variable) {
		variable.name.startsWith('_')
	}

	def typeOf(Member member) {
		switch (member) {
			Variable: member.typeOf
			Method: member.typeOf
		}
	}

	def typeOf(Variable variable) {
		typeCache.computeIfAbsent(variable, [
			if (variable.type !== null) {
				variable.type
			} else if (variable.value instanceof MemberRef && (variable.value as MemberRef).member === variable) {
				TypeSystem::TYPE_VOID
			} else {
				variable.value.typeOf
			}
		])
	}

	def typeOf(Method method) {
		if (typeCache.containsKey(method)) {
			return typeCache.get(method)
		}

		typeCache.put(method, null)

		val returns = method.body.getAllContentsOfType(ReturnStatement)
		val type = returns.map[value.typeOf].filterNull.toSet.merge

		typeCache.put(method, type)

		return type
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
