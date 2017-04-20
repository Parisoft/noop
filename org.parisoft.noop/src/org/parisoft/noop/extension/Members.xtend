package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.MemberSelection

public class Members {

	public static val memberType = <Member, NoopClass>newHashMap()

	@Inject extension Classes
	@Inject extension Expressions

	def isAccessibleFrom(Member member, EObject context) {
		val contextClass = if (context instanceof MemberSelection) context.receiver.typeOf else context.containingClass
		val memberClass = member.containingClass

		contextClass == memberClass || contextClass.isSubclassOf(memberClass)
	}

	def typeOf(Member member) {
		switch (member) {
			Variable: member.typeOf
			Method: member.typeOf
		}
	}

	def typeOf(Variable variable) {
		memberType.computeIfAbsent(variable, [variable.type ?: variable.value.typeOf])
	}

	def typeOf(Method method) {
		if (memberType.containsKey(method)) {
			return memberType.get(method)
		}

		memberType.put(method, null)

		val returns = method.body.getAllContentsOfType(ReturnStatement)
		val type = returns.map[value.typeOf].filterNull.toSet.merge

		memberType.put(method, type)

		return type
	}
}
