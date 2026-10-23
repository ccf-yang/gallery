import {DirectoryPathDTO} from './DirectoryDTO';
import {MediaDimension, MediaDTO, MediaMetadata} from './MediaDTO';

export interface CoverPhotoDTO extends MediaDTO {
  name: string;
  directory: DirectoryPathDTO;
}

export interface PhotoDTO extends CoverPhotoDTO, MediaDTO {
  id: number;
  name: string;
  directory: DirectoryPathDTO;
  metadata: PhotoMetadata;
  missingThumbnails?: number;
}

export interface PhotoMetadata extends MediaMetadata {
  title?: string;
  caption?: string;
  cameraData?: CameraMetadata;
  size: MediaDimension;
  creationDate: number;
  creationDateOffset?: string;
  fileSize: number;
}

export interface CameraMetadata {
  ISO?: number;
  model?: string;
  make?: string;
  fStop?: number; // float with precision: 2
  exposure?: number; // float with precision: 4
  focalLength?: number;
  lens?: string;
}
