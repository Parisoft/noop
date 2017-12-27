/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.ui

import com.google.inject.Binder
import com.google.inject.name.Names
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.ui.editor.contentassist.XtextContentAssistProcessor
import org.eclipse.xtext.ui.editor.hover.IEObjectHoverProvider
import org.eclipse.xtext.ui.editor.syntaxcoloring.AbstractAntlrTokenToAttributeIdMapper
import org.eclipse.xtext.ui.editor.syntaxcoloring.IHighlightingConfiguration
import org.parisoft.noop.ui.highlighting.NoopAntlrTokenToAttributeIdMapper
import org.parisoft.noop.ui.highlighting.NoopHighlightingConfiguration
import org.parisoft.noop.ui.highlighting.NoopSemanticHighlightingCalculator
import org.parisoft.noop.ui.hover.NoopHoverProvider
import org.parisoft.noop.ui.wizard.NoopProjectCreator
import org.parisoft.noop.ui.wizard.NoopProjectCreator2
import org.parisoft.noop.ui.contentassist.NoopTemplateProposalProvider

/**
 * Use this class to register components to be used within the Eclipse IDE.
 */
@FinalFieldsConstructor
class NoopUiModule extends AbstractNoopUiModule {

	override configure(Binder binder) {
		super.configure(binder)
		binder.bind(String).annotatedWith(Names.named((XtextContentAssistProcessor.COMPLETION_AUTO_ACTIVATION_CHARS))).toInstance(".,:")
		binder.bind(IEObjectHoverProvider).to(NoopHoverProvider)
		binder.bind(IHighlightingConfiguration).to(NoopHighlightingConfiguration)
		binder.bind(AbstractAntlrTokenToAttributeIdMapper).to(NoopAntlrTokenToAttributeIdMapper)
		binder.bind(ISemanticHighlightingCalculator).to(NoopSemanticHighlightingCalculator)
		binder.bind(NoopProjectCreator).to(NoopProjectCreator2)
	}
	
	override bindITemplateProposalProvider() {
		NoopTemplateProposalProvider
	}
	
}
