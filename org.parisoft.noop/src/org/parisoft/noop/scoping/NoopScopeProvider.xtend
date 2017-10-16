/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.scoping

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.Block
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.noop.NoopPackage
import org.parisoft.noop.noop.Constructor
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.ConstructorField
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.AsmStatement

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class NoopScopeProvider extends AbstractNoopScopeProvider {

	@Inject extension Expressions
	@Inject extension Classes
	@Inject extension Members

	override getScope(EObject context, EReference eRef) {
		switch (context) {
			Block:
				if (eRef == NoopPackage.eINSTANCE.memberRef_Member) {
					return scopeForVariableRef(context)
				}
			AsmStatement:
				if (eRef == NoopPackage.eINSTANCE.asmStatement_Vars) {
					return scopeForVariableRef(context)
				}
			Constructor:
				if (eRef == NoopPackage.eINSTANCE.constructorField_Variable) {
					return scopeForNewInstance(context.eContainer as NewInstance)
				}
			ConstructorField:
				if (eRef == NoopPackage.eINSTANCE.constructorField_Variable) {
					return scopeForNewInstance(context.eContainer.eContainer as NewInstance)
				}
			MemberRef:
				return scopeForMemberRef(context)
			MemberSelect:
				return scopeForMemberSelect(context)
		}

		return super.getScope(context, eRef)
	}

	protected def scopeForMemberRef(MemberRef memberRef) {
		if (memberRef.hasArgs) {
			scopeForMethodInvocation(memberRef, memberRef.args)
		} else {
			scopeForVariableRef(memberRef)
		}
	}

	protected def IScope scopeForVariableRef(EObject context) {
		val container = context.eContainer

		if (container === null) {
			return IScope.NULLSCOPE
		}

		return switch (container) {
			NoopClass: {
				val thisMembers = container.members.takeWhile[it != context].filter(Variable) + container.declaredMethods
				val superMembers = container.allFieldsBottomUp + container.allMethodsBottomUp
				Scopes.scopeFor(thisMembers, Scopes.scopeFor(superMembers))
			}
			Method:
				Scopes.scopeFor(container.params, scopeForVariableRef(container))
			Block: {
				val localVars = container.statements.takeWhile[it != context].filter(Variable)
				Scopes.scopeFor(localVars, scopeForVariableRef(container))
			}
			ForStatement: {
				val localVars = container.variables.takeWhile[it != context]
				Scopes.scopeFor(localVars, scopeForVariableRef(container))
			}
			default:
				scopeForVariableRef(container)
		}
	}

	protected def IScope scopeForMethodInvocation(EObject context, EList<Expression> args) {
		val container = context.eContainer

		if (container === null) {
			return IScope.NULLSCOPE
		}

		return switch (container) {
			NoopClass: {
				val thisMembers = container.members.takeWhile[it != context].filter(Variable) + container.declaredMethods.filterOverload(args)
				val superMembers = container.allFieldsBottomUp + container.allMethodsBottomUp.filterOverload(args)
				Scopes.scopeFor(thisMembers, Scopes.scopeFor(superMembers))
			}
			Method:
				Scopes.scopeFor(container.params, scopeForMethodInvocation(container, args))
			Block: {
				val localVars = container.statements.takeWhile[it != context].filter(Variable)
				Scopes.scopeFor(localVars, scopeForMethodInvocation(container, args))
			}
			default:
				scopeForMethodInvocation(container, args)
		}
	}

	protected def scopeForMemberSelect(MemberSelect selection) {
		val receiver = selection.receiver
		val type = receiver.typeOf

		if (type === null) {
			IScope.NULLSCOPE
		} else if (receiver instanceof NewInstance && (receiver as NewInstance).constructor === null) {
			if (selection.hasArgs) {
				Scopes.scopeFor(
					type.declaredFields.filter[static] + type.declaredMethods.filter[static].filterOverload(selection.args),
					Scopes.scopeFor(type.allFieldsBottomUp.filter[static] + type.allMethodsBottomUp.filter[static].filterOverload(selection.args))
				)
			} else {
				Scopes.scopeFor(
					type.declaredFields.filter[static] + type.declaredMethods.filter[static],
					Scopes.scopeFor(type.allFieldsBottomUp.filter[static] + type.allMethodsBottomUp.filter[static])
				)
			}
		} else if (selection.hasArgs) {
			Scopes.scopeFor(
				type.declaredMethods.filterOverload(selection.args) + type.declaredFields,
				Scopes.scopeFor(type.allMethodsBottomUp.filterOverload(selection.args) + type.allFieldsBottomUp)
			)
		} else {
			Scopes.scopeFor(
				type.declaredFields + type.declaredMethods,
				Scopes.scopeFor(type.allFieldsBottomUp + type.allMethodsBottomUp)
			)
		}
	}

	protected def scopeForNewInstance(NewInstance newInstance) {
		val container = newInstance.type
		val thisFields = container.members.filter(Variable).filter[nonStatic]
		val superFields = container.allFieldsBottomUp.filter[nonStatic]

		return Scopes.scopeFor(thisFields, Scopes.scopeFor(superFields))
	}

	private def filterOverload(Iterable<Method> methods, List<Expression> args) {
		methods.filter [ method |
			method.params.size == args.size && args.forall [ arg |
				val index = args.indexOf(arg)
				val param = method.params.get(index)
				arg.typeOf.isInstanceOf(param.typeOf)
			]
		]
	}

}