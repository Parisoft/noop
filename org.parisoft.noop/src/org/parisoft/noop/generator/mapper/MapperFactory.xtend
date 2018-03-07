package org.parisoft.noop.generator.mapper

import com.google.inject.Inject

class MapperFactory {

	@Inject Nrom nrom
	@Inject Unrom unrom

	def get(int inesmap) {
		switch (inesmap) {
			case 0: nrom
			case 2: unrom
		}
	}
}
