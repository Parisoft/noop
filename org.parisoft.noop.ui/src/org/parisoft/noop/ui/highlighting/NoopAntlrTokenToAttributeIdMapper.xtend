package org.parisoft.noop.ui.highlighting

import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultAntlrTokenToAttributeIdMapper
import com.google.inject.Singleton

@Singleton
class NoopAntlrTokenToAttributeIdMapper extends DefaultAntlrTokenToAttributeIdMapper {
	
	override protected calculateId(String tokenName, int tokenType) {
		if (tokenName == "RULE_CHA") {
			return NoopHighlightingConfiguration.STRING_ID
		}
		
		if (tokenName == "RULE_HEX" || tokenName == "RULE_BIN") {
			return NoopHighlightingConfiguration.NUMBER_ID
		}
		
		if (tokenName == "RULE_TAG_ID" || tokenName == "'@PRG-ROM'" || tokenName == "'@CHR-ROM'") {
			return NoopHighlightingConfiguration.TAG_ID
		}
		
		super.calculateId(tokenName, tokenType)
	}
	
}