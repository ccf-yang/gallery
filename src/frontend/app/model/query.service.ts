import {Injectable} from '@angular/core';
import {MediaDTO} from '../../../common/entities/MediaDTO';
import {QueryParams} from '../../../common/QueryParams';
import {Utils} from '../../../common/Utils';
import {Config} from '../../../common/config/public/Config';
import {ParentDirectoryDTO, SubDirectoryDTO,} from '../../../common/entities/DirectoryDTO';
import {ContentLoaderService} from '../ui/gallery/contentLoader.service';

@Injectable()
export class QueryService {
  constructor(
    private galleryService: ContentLoaderService
  ) {
  }

  getMediaStringId(media: MediaDTO): string {
    if (this.galleryService.isSearchResult()) {
      return Utils.concatUrls(
        media.directory.path,
        media.directory.name,
        media.name
      );
    } else {
      return media.name;
    }
  }

  getParams(lightbox?: { media?: MediaDTO,map?:boolean}): { [key: string]: string } {
    const query: { [key: string]: string } = {};
    if (lightbox?.media) {
      query[QueryParams.gallery.photo] = this.getMediaStringId(lightbox?.media);
    }
    if (lightbox?.map && !lightbox?.media) {
      query[QueryParams.gallery.map.show] = 'true';
    }
    return query;
  }

  getParamsForDirs(directory: ParentDirectoryDTO | SubDirectoryDTO): {
    [key: string]: any;
  } {
    const params: { [key: string]: any } = {};
    if (
      directory &&
      directory.lastModified &&
      directory.lastScanned &&
      !directory.isPartial
    ) {
      params[QueryParams.gallery.knownLastModified] = directory.lastModified;
      params[QueryParams.gallery.knownLastScanned] = directory.lastScanned;
    }

    return params;
  }
}
