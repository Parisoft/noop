package org.parisoft.noop.ui.highlighting

import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ide.editor.syntaxcoloring.IHighlightedPositionAcceptor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.util.CancelIndicator
import org.parisoft.noop.noop.NoopClass
import com.google.inject.Singleton
import org.eclipse.xtext.ParserRule

@Singleton
class NoopSemanticHighlightingCalculator implements ISemanticHighlightingCalculator {

	override provideHighlightingFor(XtextResource resource, IHighlightedPositionAcceptor acceptor, CancelIndicator cancelIndicator) {
		val root = resource.getParseResult().getRootNode();

		for (node : root.getAsTreeIterable()) {
			val grammarElement = node.getGrammarElement();

			switch (grammarElement) {
				ParserRule: {
					if (grammarElement.name == NoopClass.simpleName && node.semanticElement instanceof NoopClass) {
						acceptor.addPosition(node.offset, (node.semanticElement as NoopClass).name.length, NoopHighlightingConfiguration.CLASS_ID);
					}
				}

				RuleCall: {//dont work for class, but maybe for others...
					var rule = grammarElement.getRule();
					val container = grammarElement.eContainer();

					if (rule.getName().equals("ID") && container instanceof Assignment && (container as Assignment).getFeature().equals("name")) {
						val parent = node.getParent();

						if (parent !== null && parent.getGrammarElement() instanceof RuleCall) {
							rule = (parent.getGrammarElement() as RuleCall).getRule();

							if (rule.getName().equals(NoopClass.simpleName)) {
								acceptor.addPosition(node.getOffset(), node.getLength(), NoopHighlightingConfiguration.CLASS_ID);
							}
						}
					}
				}
			}
		}
	}

}
