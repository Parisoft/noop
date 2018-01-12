package org.parisoft.noop.ui.build

import org.eclipse.xtext.builder.BuilderParticipant
import java.util.List
import org.eclipse.xtext.resource.IResourceDescription.Delta
import java.util.Map
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.core.resources.IMarker
import org.eclipse.xtext.builder.IXtextBuilderParticipant.IBuildContext
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.core.runtime.CoreException
import org.eclipse.swt.widgets.Display

class NoopBuildParticipant extends BuilderParticipant {

	override protected doBuild(List<Delta> deltas, Map<String, OutputConfiguration> outputConfigurations,
		Map<OutputConfiguration, Iterable<IMarker>> generatorMarkers, IBuildContext context,
		EclipseResourceFileSystemAccess2 access, IProgressMonitor progressMonitor) throws CoreException {
		if (deltas.forall[shouldGenerate(context.resourceSet.getResource(uri, true), context)]) {
			super.doBuild(deltas, outputConfigurations, generatorMarkers, context, access, progressMonitor)
		} else {
			Display::current?.syncExec[progressMonitor.canceled = true]
		}
	}

}
