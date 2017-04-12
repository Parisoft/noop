package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.stream.Collectors
import org.eclipse.emf.ecore.EObject
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.parisoft.noop.^extension.Classes.*

public class Members {

	static val memberType = <Member, NoopClass>newHashMap()

	@Inject extension Classes
	@Inject extension Expressions
	@Inject extension TypeSystem

	def isAccessibleFrom(Member member, EObject context) {
		val contextClass = context.containingClass
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
		memberType.computeIfAbsent(variable, [k|variable.type ?: variable.value.typeOf])
	}

	def typeOf(Method method) {
		if(memberType.containsKey(method)) {
			return memberType.get(method)
		}

		memberType.put(method, TypeSystem::TYPE_UBYTE)

		val returns = method.body.getAllContentsOfType(ReturnStatement)
		val type = returns.stream.map([value.typeOf]).distinct.collect(Collectors.toList).merge

		memberType.put(method, type)

		return type
	}
}
