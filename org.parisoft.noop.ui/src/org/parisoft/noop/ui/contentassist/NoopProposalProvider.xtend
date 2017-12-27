/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.ui.contentassist

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.jface.viewers.StyledString
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.Keyword
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.eclipse.xtext.ui.editor.hover.IEObjectHover
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Collections
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.NewInstance

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class NoopProposalProvider extends AbstractNoopProposalProvider {

	@Inject extension Members
	@Inject extension Classes
	@Inject extension Expressions
	@Inject extension Collections

	@Inject IEObjectHover hover;

	override completeSelectionExpression_Member(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof MemberSelect) {
			val receiver = model.receiver

			if (receiver instanceof NewInstance) {
				receiver.type.allMethodsTopDown.filter[static].filter[isAccessibleFrom(model)].forEach [ method |
					val displayString = new StyledString(method.name).append('(')

					method.params.forEach [ param, i |
						displayString.append(param.type.name, StyledString::DECORATIONS_STYLER)
						displayString.append(param.dimension.map['''[«value?.valueOf»]'''].join,
							StyledString::DECORATIONS_STYLER).append(' ')
						displayString.append(param.name)

						if (i < method.params.length - 1) {
							displayString.append(', ')
						}
					]

					displayString.append(')').append(': ')
					displayString.append(method.typeOf.name, StyledString::DECORATIONS_STYLER)
					displayString.append(method.dimensionOf.map['''[«it»]'''].join, StyledString::DECORATIONS_STYLER)
					displayString.append(''' - «method.containerClass.name»''', StyledString::QUALIFIER_STYLER)

					val proposalString = '''«method.name»«IF method.params.isNotEmpty»()«ENDIF»'''
					val proposal = createCompletionProposal(proposalString, displayString, method.image,
						context) as ConfigurableCompletionProposal

					if (proposal !== null) {
						acceptor.accept(proposal => [
							it.cursorPosition = proposalString.length - 1
							it.proposalContextResource = context.resource
							it.additionalProposalInfo = method
							it.hover = hover
						])
					}
				]
			}
		}

//		lookupCrossReference(assignment.terminal as CrossReference, context, acceptor) [ description |
//			(description.EObjectOrProxy as Member).isAccessibleFrom(model)
//		]
	}

	override completeKeyword(Keyword keyword, ContentAssistContext contentAssistContext,
		ICompletionProposalAcceptor acceptor) {
		if (keyword.value == '.') {
			return
		}

		super.completeKeyword(keyword, contentAssistContext, acceptor)
	}

}
