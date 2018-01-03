package org.parisoft.noop.ui.hover

import com.google.inject.Inject
import org.eclipse.core.runtime.FileLocator
import org.eclipse.emf.ecore.EObject
import org.eclipse.ui.plugin.AbstractUIPlugin
import org.eclipse.xtext.ui.PluginImageHelper
import org.eclipse.xtext.ui.editor.hover.html.DefaultEObjectHoverProvider
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.Variable
import org.parisoft.noop.ui.labeling.NoopLabelProvider

import static extension org.eclipse.xtext.EcoreUtil2.*

class NoopHoverProvider extends DefaultEObjectHoverProvider {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension Expressions
	@Inject extension NoopLabelProvider

	@Inject PluginImageHelper imageHelper
	@Inject AbstractUIPlugin uiPlugin

	override protected getFirstLine(EObject o) {
		switch (o) {
			NoopClass: '''
				«val classes = o.superClasses»
				<div>
				<img src="«o.image.toFileURL»" style="float:left">
				«FOR i : 0 ..< classes.size»
					«IF i > 0»extends «ENDIF»<b>«classes.get(i).name»</b>
					<ul style="list-style-type:none">
				«ENDFOR»
				«FOR i : 0 ..< classes.size»
					</ul>
				«ENDFOR»
				</div>
			'''
			Variable: '''
				«val type = o.typeOf.name»
				«val dimension = o.dimensionOf.map['''[«it»]'''].join»
				«val container = o.containerClass.name»
				«IF o.isField»
					<img src="«o.image.toFileURL»" style="float:left"> <b>«type»</b>«dimension» «container».<b>«o.name»</b>
				«ELSE»
					«val method = o.getContainerOfType(Method)»
					«val params = method.params.map['''«it.type.name»«it.dimension.map['''[«value?.valueOf»]'''].join»'''].join(', ')»
					<img src="«o.image.toFileURL»" style="float:left"> <b>«type»</b>«dimension» <b>«o.name»</b> - «container».«method.name»(«params»)
				«ENDIF»
			'''
			Method: '''
				«val type = o.typeOf.name»
				«val dimension = o.dimensionOf.map['''[«it»]'''].join»
				«val container = o.containerClass.name»
				«val params = o.params.map['''«it.type.name»«it.dimension.map['''[«value?.valueOf»]'''].join»'''].join(', ')»
				<img src="«o.image.toFileURL»" style="float:left"> <b>«type»</b>«dimension» «container».<b>«o.name»(«params»)</b>
			'''
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

	private def toFileURL(String image) {
		FileLocator::toFileURL(uiPlugin.bundle.getEntry(imageHelper.pathSuffix + image))
	}
}
