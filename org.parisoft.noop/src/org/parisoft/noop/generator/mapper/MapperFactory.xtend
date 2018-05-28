package org.parisoft.noop.generator.mapper

import com.google.inject.Inject

class MapperFactory {

	@Inject Nrom nrom
	@Inject Unrom unrom
	@Inject Cnrom cnrom
	@Inject Mmc3 mmc3

	def get(int inesmap) {
		switch (inesmap) {
			case 0: nrom
			case 2: unrom
			case 3: cnrom
			case 4: mmc3
		}
	}
}
