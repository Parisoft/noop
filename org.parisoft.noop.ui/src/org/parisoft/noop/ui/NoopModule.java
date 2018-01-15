package org.parisoft.noop.ui;

import org.eclipse.xtext.builder.impl.XtextBuilder;
import org.eclipse.xtext.resource.clustering.DynamicResourceClusteringPolicy;
import org.eclipse.xtext.resource.clustering.IResourceClusteringPolicy;
import org.parisoft.noop.ui.build.NoopBuilder;

import com.google.inject.Binder;
import com.google.inject.Module;

@SuppressWarnings("restriction")
public class NoopModule implements Module {

	@Override
	public void configure(Binder binder) {
		binder.bind(IResourceClusteringPolicy.class).to(DynamicResourceClusteringPolicy.class);
		binder.bind(XtextBuilder.class).to(NoopBuilder.class);
	}

}
