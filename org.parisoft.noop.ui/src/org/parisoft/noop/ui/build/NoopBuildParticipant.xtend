package org.parisoft.noop.ui.build

import com.google.inject.Inject
import java.util.List
import java.util.Map
import java.util.NoSuchElementException
import org.eclipse.core.resources.IMarker
import org.eclipse.core.runtime.CoreException
import org.eclipse.core.runtime.IProgressMonitor
import org.eclipse.xtext.builder.BuilderParticipant
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2
import org.eclipse.xtext.generator.OutputConfiguration
import org.eclipse.xtext.resource.IResourceDescription.Delta
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.noop.NoopClass

class NoopBuildParticipant extends BuilderParticipant {

	@Inject extension Classes

	override protected doBuild(List<Delta> deltas, Map<String, OutputConfiguration> outputConfigs,
		Map<OutputConfiguration, Iterable<IMarker>> generatorMarkers, IBuildContext context,
		EclipseResourceFileSystemAccess2 access, IProgressMonitor monitor) throws CoreException {
		val resources = deltas.map[context.resourceSet.getResource(uri, true)]

		if (resources.forall[shouldGenerate(context)]) {
			try {
				val games = resources.flatMap[contents].filter(NoopClass).filter[game]
				val game = games.maxBy[superClasses.size]
				val delta = deltas.findFirst[uri == game.eResource.URI]//TODO compile all non relatives games

				if (delta !== null) {
					super.doBuild(newArrayList(delta), outputConfigs, generatorMarkers, context, access, monitor)
				}
			} catch (NoSuchElementException notFound) {
			}
		}
	}

}
