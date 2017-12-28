/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.ui.contentassist

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.jface.viewers.StyledString
import org.eclipse.swt.graphics.Image
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.eclipse.xtext.ui.editor.hover.IEObjectHover
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NewInstance

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class NoopProposalProvider extends AbstractNoopProposalProvider {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension Expressions

	@Inject IEObjectHover hover;

	override completeSelectionExpression_Member(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof MemberSelect) {
			val receiver = model.receiver
			val methods = receiver.typeOf.allMethodsTopDown.filter[isAccessibleFrom(model)]

			if (receiver.dimensionOf.size > 0) {
				methods.filter[nonStatic].filter[nativeArray].suppressOverriden.forEach [ method |
					acceptor.accept(method.createCompletionProposal(context))
				]
			} else if (receiver instanceof NewInstance) {
				if (receiver.constructor === null) {
					methods.filter[static].suppressStaticOverriden.forEach [ method |
						acceptor.accept(method.createCompletionProposal(context))
					]
				} else {
					methods.filter[nonStatic].filter[nonNativeArray].suppressOverriden.forEach [ method |
						acceptor.accept(method.createCompletionProposal(context))
					]
				}
			} else {
				methods.filter[nonStatic].filter[nonNativeArray].suppressOverriden.forEach [ method |
					acceptor.accept(method.createCompletionProposal(context))
				]
			}
		} else {
			super.completeSelectionExpression_Member(model, assignment, context, acceptor)
		}
	}

	override completeTerminalExpression_Member(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		model.containerClass.allMethodsTopDown.filter[nonNativeArray].suppressAnyOverriden.forEach [ method |
			acceptor.accept(method.createCompletionProposal(context))
		]
	}

	override completeSelectionExpression_Args(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		super.completeSelectionExpression_Args(model, assignment, context, acceptor)
	}

	override completeKeyword(Keyword keyword, ContentAssistContext contentAssistContext,
		ICompletionProposalAcceptor acceptor) {
		if (keyword.value == '.') {
			return
		}

		super.completeKeyword(keyword, contentAssistContext, acceptor)
	}

	override protected doCreateProposal(String proposal, StyledString displayString, Image image, int replacementOffset,
		int replacementLength) {
		new NoopMethodCompletionProposal(proposal, replacementOffset, replacementLength, proposal.length(), image,
			displayString, null, null)
	}

	private def createCompletionProposal(Method method, ContentAssistContext context) {
		val displayString = new StyledString(method.name).append('(')

		method.params.forEach [ param, i |
			displayString.append(param.type.name, StyledString::DECORATIONS_STYLER)
			displayString.append(param.dimension.map['''[«value?.valueOf»]'''].join, StyledString::DECORATIONS_STYLER)
			displayString.append(' ').append(param.name)

			if (i < method.params.length - 1) {
				displayString.append(', ')
			}
		]

		displayString.append(')').append(': ')
		displayString.append(method.typeOf.name, StyledString::DECORATIONS_STYLER)
		displayString.append(method.dimensionOf.map['''[«it»]'''].join, StyledString::DECORATIONS_STYLER)
		displayString.append(''' - «method.containerClass.name»''', StyledString::QUALIFIER_STYLER)

		val proposalString = method.name
		val proposal = createCompletionProposal(proposalString, displayString, method.image, context)

		if (proposal instanceof NoopMethodCompletionProposal) {
			proposal => [
				it.hover = hover
				it.setLinkedMode(context.viewer, method)
			]
		}
	}

	private def suppressAnyOverriden(Iterable<Method> methods) {
		methods.suppressOverriden.suppressStaticOverriden
	}

	private def suppressOverriden(Iterable<Method> methods) {
		val suppressed = newHashSet

		methods.forEach [ method, i |
			suppressed += methods.drop(i + 1).findFirst[method.isOverrideOf(it)]
			suppressed += if (methods.drop(i + 1).exists[isOverrideOf(method)]) {
				method
			}
		]

		methods.filter[!suppressed.contains(it)]
	}

	private def suppressStaticOverriden(Iterable<Method> methods) {
		val suppressed = newHashSet

		methods.forEach [ method, i |
			suppressed += methods.drop(i + 1).findFirst[method.isStaticOverrideOf(it)]
			suppressed += if (methods.drop(i + 1).exists[isStaticOverrideOf(method)]) {
				method
			}
		]

		methods.filter[!suppressed.contains(it)]
	}

}
