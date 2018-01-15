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
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.eclipse.xtext.ui.editor.hover.IEObjectHover
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Files
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.Block
import org.parisoft.noop.noop.DifferExpression
import org.parisoft.noop.noop.EqualsExpression
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.ForeverStatement
import org.parisoft.noop.noop.IfStatement
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.ui.labeling.NoopLabelProvider

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.eclipse.xtext.nodemodel.util.NodeModelUtils.*
import org.eclipse.xtext.CrossReference
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal

/**
 * See https://www.eclipse.org/Xtext/documentation/304_ide_concepts.html#content-assist
 * on how to customize the content assistant.
 */
class NoopProposalProvider extends AbstractNoopProposalProvider {

	@Inject extension Files
	@Inject extension Members
	@Inject extension Classes
	@Inject extension Expressions

	@Inject NoopLabelProvider labelProvider
	@Inject IEObjectHover hover

	val storageKeywords = StorageType::VALUES.map[literal].toList
	val proposableKeywords = (newArrayList('extends', 'instanceOf', 'as', 'return', 'this', 'super', 'break',
		'continue') + storageKeywords).toList
	val matcher = new SmartPrefixMatcher

	override completeNoopClass_SuperClass(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof NoopClass) {
			lookupCrossReference((assignment.getTerminal() as CrossReference), context, acceptor) [
				val superClass = if(EObjectOrProxy.eIsProxy) EObjectOrProxy.resolve(model) else EObjectOrProxy

				if (superClass instanceof NoopClass) {
					if (superClass.isVoid || superClass.isPrimitive || superClass.isINESHeader ||
						superClass.superClasses.exists[isInstanceOf(model)]) {
						return false
					}
				}

				true
			]
		} else {
			super.completeNoopClass_SuperClass(model, assignment, context, acceptor)
		}
	}

	override completeNoopClass_Members(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof NoopClass) {
			model.allMethodsTopDown.filter[nonNativeArray].suppressOverriden.filter[containerClass != model].forEach [ method |
				acceptor.accept(method.createOverrideProposal(context))
			]
		} else {
			super.completeNoopClass_Members(model, assignment, context, acceptor)
		}
	}

	override completeSelectionExpression_Member(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof MemberSelect) {
			val receiver = model.receiver
			val variables = receiver.typeOf.allFieldsTopDown.filter[isAccessibleFrom(model)].suppressHeaders
			val methods = receiver.typeOf.allMethodsTopDown.filter[isAccessibleFrom(model)]

			if (receiver.dimensionOf.size > 0) {
				methods.filter[nonStatic].filter[nativeArray].suppressOverriden.forEach [ method |
					acceptor.accept(method.createInvocationProposal(context))
				]
			} else if (receiver instanceof NewInstance) {
				if (receiver.constructor === null) {
					variables.filter[static].suppressOverriden.forEach [ variable |
						acceptor.accept(variable.createReferenceProposal(context))
					]
					methods.filter[static].suppressOverriden.forEach [ method |
						acceptor.accept(method.createInvocationProposal(context))
					]
				} else {
					variables.filter[nonStatic].suppressOverriden.forEach [ variable |
						acceptor.accept(variable.createReferenceProposal(context))
					]
					methods.filter[nonStatic].filter[nonNativeArray].suppressOverriden.forEach [ method |
						acceptor.accept(method.createInvocationProposal(context))
					]
				}
			} else {
				variables.filter[nonStatic].suppressOverriden.forEach [ variable |
					acceptor.accept(variable.createReferenceProposal(context))
				]
				methods.filter[nonStatic].filter[nonNativeArray].suppressOverriden.forEach [ method |
					acceptor.accept(method.createInvocationProposal(context))
				]
			}
		} else {
			super.completeSelectionExpression_Member(model, assignment, context, acceptor)
		}
	}

	override completeTerminalExpression_Member(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof NoopClass) {
			return
		}

		val nonStatic = model.getContainerOfType(Method)?.isNonStatic

		if (nonStatic) {
			model.listVariables(context).forEach [ variable |
				acceptor.accept(variable.createReferenceProposal(context))
			]
			model.containerClass.allMethodsTopDown.filter[nonNativeArray].suppressOverriden.forEach [ method |
				acceptor.accept(method.createInvocationProposal(context))
			]
		} else {
			model.listVariables(context).filter[static || nonField].forEach [ variable |
				acceptor.accept(variable.createReferenceProposal(context))
			]
			model.containerClass.allMethodsTopDown.filter[static].filter[nonNativeArray].suppressOverriden.forEach [ method |
				acceptor.accept(method.createInvocationProposal(context))
			]
		}

	}

	override completeTerminalExpression_Type(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof NoopClass) {
			return
		}

		super.completeTerminalExpression_Type(model, assignment, context, acceptor)
	}

	override completeKeyword(Keyword keyword, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		if (proposableKeywords.contains(keyword.value)) {
			if (keyword.value == 'this' || keyword.value == 'super') {
				val method = context.currentModel.getContainerOfType(Method)

				if (method === null || method.isStatic) {
					return
				}
			} else if (keyword.value == 'break' || keyword.value == 'continue') {
				val model = context.currentModel

				if (model.getContainerOfType(ForStatement) === null &&
					model.getContainerOfType(ForeverStatement) === null) {
					return
				}
			} else if (storageKeywords.contains(keyword.value)) {
				val model = context.currentModel

				if (!(model instanceof Member)) {
					return
				}
			}

			super.completeKeyword(keyword, context, acceptor)
		}
	}

	override complete_BOOL(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof Variable || model instanceof ReturnStatement ||
			(model instanceof AssignmentExpression && (model as AssignmentExpression).typeOf.isBoolean) ||
			(model instanceof EqualsExpression && (model as EqualsExpression).left?.typeOf?.isBoolean) ||
			(model instanceof DifferExpression && (model as DifferExpression).left?.typeOf?.isBoolean) ||
			(model instanceof IfStatement && (model as IfStatement).condition === null)) {
			val trueDisplay = new StyledString('true', StyledString::COUNTER_STYLER)
			val falseDisplay = new StyledString('false', StyledString::COUNTER_STYLER)
			val image = labelProvider.getImage('true')
			acceptor.accept(createCompletionProposal('true', trueDisplay, image, context))
			acceptor.accept(createCompletionProposal('false', falseDisplay, image, context))
		}
	}

	override complete_Byte(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof Variable || model instanceof ReturnStatement ||
			(model instanceof AssignmentExpression && (model as AssignmentExpression).typeOf.isNumeric)) {
			val displayString = new StyledString('0', StyledString::COUNTER_STYLER)
			val image = labelProvider.getImage('0')
			acceptor.accept(createCompletionProposal('0', displayString, image, context))
		}
	}

	override complete_STRING(EObject model, RuleCall ruleCall, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		if (model instanceof Variable && (model as Variable).isField) {
			for (file : model.URI.resFolder.listFiles) {
				val proposalString = '''"«Members::FILE_SCHEMA»«file.name»"'''
				val displayString = new StyledString(Members::FILE_SCHEMA + file.name, StyledString::COUNTER_STYLER)
				val image = labelProvider.getImage(file)
				acceptor.accept(createCompletionProposal(proposalString, displayString, image, context))
			}
		}
	}

	override protected doCreateProposal(String proposal, StyledString displayString, Image image, int replacementOffset,
		int replacementLength) {
		new NoopMethodCompletionProposal(proposal, replacementOffset, replacementLength, proposal.length(), image,
			displayString, null, null)
	}

	private def createReferenceProposal(Variable variable, ContentAssistContext context) {
		val priority = if (variable.isStatic) {
				4000
			} else if (variable.isField) {
				5000
			} else {
				6000
			}

		val prefix = context.prefix
		val proposal = createCompletionProposal(variable.name, variable.text, variable.image, priority, prefix, context)

		if (proposal instanceof ConfigurableCompletionProposal) {
			proposal => [
				it.matcher = matcher
			]
		}
	}

	private def createInvocationProposal(Method method, ContentAssistContext context) {
		val priority = if (method.isStatic) {
				2000
			} else {
				3000
			}

		val prefix = context.prefix
		val proposal = createCompletionProposal(method.name, method.text, method.image, priority, prefix, context)

		if (proposal instanceof NoopMethodCompletionProposal) {
			proposal => [
				it.matcher = matcher
				it.hover = hover
				it.additionalProposalInfo = method
				it.setLinkedModeForInvocation(context.viewer, method)
			]
		}
	}

	private def createOverrideProposal(Member member, ContentAssistContext context) {
		val prefix = context.prefix
		val displayString = new StyledString('override ').append(member.text)
		val proposal = createCompletionProposal(member.name, displayString, member.image, 0, prefix, context)

		if (proposal instanceof NoopMethodCompletionProposal) {
			proposal => [
				it.matcher = matcher
				it.hover = hover
				it.additionalProposalInfo = member

				if (member instanceof Method) {
					it.setLinkedModeForOverride(context.viewer, member, member.isStatic, [valueOf])
				}
			]
		}
	}

	private def Iterable<Variable> listVariables(EObject model, ContentAssistContext context) {
		if (model === null) {
			return newArrayList
		}

		return switch (model) {
			Block:
				model.statements.takeWhile[node.startLine < context.currentNode.startLine].filter(Variable)
			ForStatement:
				model.variables.takeWhile[node.offset < context.currentNode.offset].filter[value !== null]
			Method:
				model.params
			NoopClass:
				model.allFieldsTopDown.takeWhile [
					node.startLine < context.currentNode.startLine
				].suppressOverriden.suppressHeaders
			default:
				newArrayList
		} + model.eContainer.listVariables(context)
	}

	private def suppressHeaders(Iterable<Variable> variables) {
		variables.filter[typeOf.nonINESHeader]
	}

	private def <M extends Member> suppressOverriden(Iterable<M> members) {
		val suppressed = newHashSet

		members.forEach [ member, i |
			suppressed += members.drop(i + 1).findFirst[member.isOverrideOf(it)]
			suppressed += if (members.drop(i + 1).exists[isOverrideOf(member)]) {
				member
			}
		]

		members.filter[!suppressed.contains(it)]
	}

	private dispatch def text(NoopClass c) {
		labelProvider.text(c)
	}

	private dispatch def text(Method m) {
		labelProvider.text(m)
	}

	private dispatch def text(Variable v) {
		labelProvider.text(v)
	}

}
