package org.parisoft.noop.ui.highlighting

import com.google.inject.Singleton
import org.eclipse.xtext.Action
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ide.editor.syntaxcoloring.IHighlightedPositionAcceptor
import org.eclipse.xtext.ide.editor.syntaxcoloring.ISemanticHighlightingCalculator
import org.eclipse.xtext.resource.XtextResource
import org.eclipse.xtext.util.CancelIndicator
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection

@Singleton
class NoopSemanticHighlightingCalculator implements ISemanticHighlightingCalculator {

	override provideHighlightingFor(XtextResource resource, IHighlightedPositionAcceptor acceptor, CancelIndicator cancelIndicator) {
		val root = resource.getParseResult().getRootNode();

		for (node : root.getAsTreeIterable()) {
			val grammarElement = node.getGrammarElement();

			switch (grammarElement) {
//				ParserRule: {
//					if (grammarElement.name == NoopClass.simpleName && node.semanticElement instanceof NoopClass) {
//						acceptor.addPosition(node.offset, (node.semanticElement as NoopClass).name.length, NoopHighlightingConfiguration.CLASS_ID);
//					}
//				}
				RuleCall: { // dont work for class, but maybe for others...
					var rule = grammarElement.getRule();
					val container = grammarElement.eContainer();

					if (rule.getName().equals("ID") && container instanceof Assignment && (container as Assignment).getFeature().equals("name")) {
						val parent = node.getParent();

						if (parent !== null && parent.getGrammarElement() instanceof RuleCall) {
							rule = (parent.getGrammarElement() as RuleCall).getRule();

							if (rule.name == 'Variable' && node.text.startsWith('_')) {
								acceptor.addPosition(node.getOffset(), node.getLength(), NoopHighlightingConfiguration.STRING_ID);
							}
						}
					}
				}
				Action:
					if (node.semanticElement instanceof MemberRef) {
						if ((node.semanticElement as MemberRef).member.name.startsWith('_')) {
							acceptor.addPosition(node.getOffset(), node.getLength(), NoopHighlightingConfiguration.STRING_ID);
						}
					} else if (node.semanticElement instanceof MemberSelection) {
						val selection = node.semanticElement as MemberSelection
						val name = selection.member?.name ?: ""

						if (!selection.isMethodInvocation && name.startsWith('_')) {
							acceptor.addPosition(node.endOffset - name.length, name.length, NoopHighlightingConfiguration.STRING_ID);
						}
					}
			}
		}
	}

}
