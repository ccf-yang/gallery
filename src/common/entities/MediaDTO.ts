import {DirectoryPathDTO} from './DirectoryDTO';
import {FileDTO} from './FileDTO';
import {SupportedFormats} from '../SupportedFormats';
import {Utils} from '../Utils';

export interface VideoProperties {
  size: MediaDimension;
  fileSize: number;
  duration: number;
  fps: number;
  bitRate: number;
}

export interface MediaDTO extends FileDTO {
  id: number;
  name: string;
  directory: DirectoryPathDTO;
  metadata: MediaMetadata;
  missingThumbnails?: number;
}

export type RatingTypes = 0 | 1 | 2 | 3 | 4 | 5;

export interface MediaMetadata {
  size: MediaDimension;
  creationDate: number;
  fileSize: number;
  creationDateOffset?: string;
  keywords?: string[];
  rating?: RatingTypes;
  title?: string;
  caption?: string;
}

export interface MediaDimension {
  width: number;
  height: number;
}

export const MediaDTOUtils = {
  isPhoto: (media: FileDTO): boolean => {
    return !MediaDTOUtils.isVideo(media);
  },

  isVideo: (media: FileDTO): boolean => {
    const lower = media.name.toLowerCase();
    for (const ext of SupportedFormats.WithDots.Videos) {
      if (lower.endsWith(ext)) {
        return true;
      }
    }
    return false;
  },

  isVideoPath: (path: string): boolean => {
    const lower = path.toLowerCase();
    for (const ext of SupportedFormats.WithDots.Videos) {
      if (lower.endsWith(ext)) {
        return true;
      }
    }
    return false;
  },

  isVideoTranscodingNeeded: (media: FileDTO): boolean => {
    const lower = media.name.toLowerCase();
    for (const ext of SupportedFormats.WithDots.TranscodeNeed.Videos) {
      if (lower.endsWith(ext)) {
        return true;
      }
    }
    return false;
  },

  calcAspectRatio: (photo: MediaDTO): number => {
    return (photo.metadata.size.width / photo.metadata.size.height) || 1; // NaN should be treated as a square photo
  },

  equals: (a: MediaDTO, b: MediaDTO): boolean => {
    return a.directory.path === b.directory.path &&
        a.directory.name === b.directory.name &&
        a.name === b.name;
  },
  createdThisYear(media: MediaDTO): boolean {
    return (
      new Date().getFullYear() ===
      Utils.getUTCFullYear(media.metadata.creationDate, media.metadata.creationDateOffset)
    );
  }
};
