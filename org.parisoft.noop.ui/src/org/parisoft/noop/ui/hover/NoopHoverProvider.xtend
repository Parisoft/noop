package org.parisoft.noop.ui.hover

import com.google.inject.Inject
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.Variable
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.noop.NoopClass

class NoopHoverProvider extends DefaultEObjectHoverProvider {

	@Inject extension Members
	@Inject extension IQualifiedNameProvider

	override protected getFirstLine(EObject o) {
		switch (o) {
			NoopClass: '''Class <b>«o.fullyQualifiedName»</b>'''
			Variable: '''«IF o.eContainer instanceof NoopClass»Field«ELSE»Variable«ENDIF»
			<b>«o.name»</b>«IF o.isConstant» = «o.valueOf»«ENDIF»
			 of type <b>«o.typeOf.fullyQualifiedName»</b>«FOR i : 0 ..< o.dimensionOf.size»[«IF o.isBounded»«o.dimensionOf.get(i)»«ENDIF»]«ENDFOR»'''
			Method: '''Method <b>«o.name»</b> returns <b>«o.typeOf?.name»</b>«FOR i : 0 ..< o.dimensionOf.size»[«o.dimensionOf.get(i)»]«ENDFOR».'''
			default:
				super.getFirstLine(o)
		}
	}

	override protected getDocumentation(EObject o) {
		val doc = super.getDocumentation(o)
		var index = -1

		if (doc !== null && (index = doc.indexOf('*/')) !== -1) {
			return doc.substring(0, index)
		}

		return doc
	}

}
