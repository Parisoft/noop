package utils

import org.eclipse.xtext.ui.PluginImageHelper
import com.google.inject.Inject
import org.eclipse.ui.plugin.AbstractUIPlugin
import org.eclipse.core.runtime.FileLocator

class Images {

	@Inject PluginImageHelper imageHelper
	@Inject AbstractUIPlugin uiPlugin

	def toFileURL(String image) {
		FileLocator::toFileURL(uiPlugin.bundle.getEntry(imageHelper.pathSuffix + image))
	}
	
	static def getDescriptor(String image) {
		AbstractUIPlugin::imageDescriptorFromPlugin('org.parisoft.noop.ui', 'icons/' + image)
	}
}
