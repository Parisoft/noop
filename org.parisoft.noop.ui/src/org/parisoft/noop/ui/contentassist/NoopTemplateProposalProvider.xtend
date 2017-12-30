package org.parisoft.noop.ui.contentassist

import com.google.inject.Inject
import com.google.inject.Singleton
import org.eclipse.jface.text.templates.ContextTypeRegistry
import org.eclipse.jface.text.templates.Template
import org.eclipse.jface.text.templates.persistence.TemplateStore
import org.eclipse.swt.graphics.Image
import org.eclipse.ui.plugin.AbstractUIPlugin
import org.eclipse.xtext.ui.editor.templates.ContextTypeIdHelper
import org.eclipse.xtext.ui.editor.templates.DefaultTemplateProposalProvider

@Singleton
class NoopTemplateProposalProvider extends DefaultTemplateProposalProvider {

	var Image image

	@Inject
	new(TemplateStore templateStore, ContextTypeRegistry registry, ContextTypeIdHelper helper) {
		super(templateStore, registry, helper)
	}

	override getImage(Template template) {
		if (image === null) {
			image = AbstractUIPlugin::imageDescriptorFromPlugin('org.parisoft.noop.ui', 'icons/Template.png').
				createImage
		}
		
		return image
	}

}
