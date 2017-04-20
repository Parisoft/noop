package org.parisoft.noop.ui.highlighting

import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultAntlrTokenToAttributeIdMapper
import com.google.inject.Singleton

@Singleton
class NoopAntlrTokenToAttributeIdMapper extends DefaultAntlrTokenToAttributeIdMapper {
	
	override protected calculateId(String tokenName, int tokenType) {
		if (tokenName == "RULE_CHA") {
			return NoopHighlightingConfiguration.CHAR_ID
		}
		
		super.calculateId(tokenName, tokenType)
	}
	
}