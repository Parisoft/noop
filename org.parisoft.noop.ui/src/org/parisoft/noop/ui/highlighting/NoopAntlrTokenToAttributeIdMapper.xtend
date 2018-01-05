package org.parisoft.noop.ui.highlighting

import org.eclipse.xtext.ui.editor.syntaxcoloring.DefaultAntlrTokenToAttributeIdMapper
import com.google.inject.Singleton
import org.parisoft.noop.noop.StorageType

@Singleton
class NoopAntlrTokenToAttributeIdMapper extends DefaultAntlrTokenToAttributeIdMapper {

	val storageTags = StorageType::VALUES.map["'" + literal + "'"]
	
	override protected calculateId(String tokenName, int tokenType) {
		if (tokenName == 'RULE_CID') {
			return NoopHighlightingConfiguration::CLASS_ID
		}

		if (tokenName == 'RULE_CHA') {
			return NoopHighlightingConfiguration::STRING_ID
		}

		if (tokenName == 'RULE_HEX' || tokenName == 'RULE_BIN') {
			return NoopHighlightingConfiguration::NUMBER_ID
		}

		if (tokenName == 'RULE_BOOL') {
			return NoopHighlightingConfiguration::BOOL_ID
		}

		if (storageTags.contains(tokenName)) {
			return NoopHighlightingConfiguration::TAG_ID
		}

		if (tokenName == 'RULE_ASM_TO_ASM' || tokenName == 'RULE_ASM_TO_VAR' || tokenName == 'RULE_VAR_TO_ASM' || tokenName == 'RULE_VAR_TO_VAR') {
			return NoopHighlightingConfiguration::ASM_ID
		}

		super.calculateId(tokenName, tokenType)
	}

}
