package org.parisoft.noop.ui.contentassist

import com.google.inject.Inject
import com.google.inject.Singleton
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.jface.text.templates.ContextTypeRegistry
import org.eclipse.jface.text.templates.Template
import org.eclipse.jface.text.templates.persistence.TemplateStore
import org.eclipse.swt.graphics.Image
import org.eclipse.xtext.ui.editor.templates.ContextTypeIdHelper
import org.eclipse.xtext.ui.editor.templates.DefaultTemplateProposalProvider
import utils.Images

@Singleton
class NoopTemplateProposalProvider extends DefaultTemplateProposalProvider {

	val imageCache = new ConcurrentHashMap<String, Image>

	@Inject
	new(TemplateStore templateStore, ContextTypeRegistry registry, ContextTypeIdHelper helper) {
		super(templateStore, registry, helper)
	}

	override getImage(Template template) {
		val name = switch (template.name) {
			case 'var': {
				'NewField.png'
			}
			case 'def': {
				'NewMethod.png'
			}
			default: {
				'Template.png'
			}
		}

		imageCache.computeIfAbsent(name, [Images::getDescriptor(name).createImage])
	}

}
