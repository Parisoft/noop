package org.parisoft.noop.ui.contentassist

import org.eclipse.xtext.ui.editor.templates.DefaultTemplateProposalProvider
import org.eclipse.jface.text.templates.persistence.TemplateStore
import org.eclipse.jface.text.templates.ContextTypeRegistry
import org.eclipse.xtext.ui.editor.templates.ContextTypeIdHelper
import com.google.inject.Inject
import com.google.inject.Singleton
import org.eclipse.jface.text.templates.TemplateContext
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ITemplateAcceptor
import org.eclipse.jface.text.templates.Template
import org.parisoft.noop.services.NoopGrammarAccess
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.^extension.Classes

@Singleton
class NoopTemplateProposalProvider extends DefaultTemplateProposalProvider {

	@Inject extension Classes
	@Inject ContextTypeIdHelper helper
	@Inject NoopGrammarAccess grammarAccess

	@Inject
	new(TemplateStore templateStore, ContextTypeRegistry registry, ContextTypeIdHelper helper) {
		super(templateStore, registry, helper)
	}

	override protected createTemplates(TemplateContext templateContext, ContentAssistContext context,
		ITemplateAcceptor acceptor) {
		super.createTemplates(templateContext, context, acceptor)
		val rule = grammarAccess.selectionExpressionRule
		val id = helper.getId(rule)
		val model = context.currentModel

		if (model instanceof NewInstance) {
			if (id == 'org.parisoft.noop.Noop.SelectionExpression') {
				model.type.allMethodsTopDown.forEach [method|
					val pattern = '''«model.type.name».«method.name»(${cursor})'''
					val name = '''«model.type.name».«method.name»'''
					val tpl = new Template(name, method.name, Integer::toHexString(method.hashCode), pattern, true)
					acceptor.accept(createProposal(tpl, templateContext, context, tpl.image, tpl.relevance))
				]
			}
		}
	}

}
