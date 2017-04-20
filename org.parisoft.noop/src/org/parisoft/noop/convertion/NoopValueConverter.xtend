package org.parisoft.noop.convertion

import org.eclipse.xtext.common.services.DefaultTerminalConverters
import org.eclipse.xtext.conversion.IValueConverter
import org.eclipse.xtext.conversion.ValueConverter
import org.eclipse.xtext.conversion.ValueConverterException
import org.eclipse.xtext.nodemodel.INode
import com.google.inject.Inject
import org.parisoft.noop.^extension.Values

class NoopValueConverter extends DefaultTerminalConverters {

	@Inject extension Values

	@ValueConverter(rule="Byte")
	def convertByte() {
		return new IValueConverter<Integer>() {

			override toValue(String string, INode node) throws ValueConverterException {
				return string.parseInt();
			}

			override toString(Integer value) throws ValueConverterException {
				return value.toString();
			}

		};
	}
}
