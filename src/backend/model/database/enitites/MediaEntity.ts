import {Column, Entity, Index, ManyToOne, PrimaryGeneratedColumn, TableInheritance, Unique,} from 'typeorm';
import {DirectoryEntity} from './DirectoryEntity';
import {MediaDimension, MediaDTO, MediaMetadata,} from '../../../../common/entities/MediaDTO';
import {columnCharsetCS} from './EntityUtils';
import {CameraMetadata,} from '../../../../common/entities/PhotoDTO';
import {Utils} from '../../../../common/Utils';

export class MediaDimensionEntity implements MediaDimension {
  @Column('int')
  width: number;

  @Column('int')
  height: number;
}

export class CameraMetadataEntity implements CameraMetadata {
  @Column('int', {nullable: true, unsigned: true})
  ISO: number;

  @Column({
    type: 'text',
    nullable: true,
    charset: columnCharsetCS.charset,
    collation: columnCharsetCS.collation,
  })
  model: string;

  @Column({
    type: 'text',
    nullable: true,
    charset: columnCharsetCS.charset,
    collation: columnCharsetCS.collation,
  })
  make: string;

  @Column('float', {nullable: true})
  fStop: number;

  @Column('float', {nullable: true})
  exposure: number;

  @Column('float', {nullable: true})
  focalLength: number;

  @Column('text', {nullable: true})
  lens: string;
}


export class MediaMetadataEntity implements MediaMetadata {
  @Column('text')
  caption?: string;

  @Column('text')
  title?: string;

  @Column(() => MediaDimensionEntity)
  size: MediaDimensionEntity;

  /**
   * Date in local timezone
   * Reason: If you look back your holiday photos from a different timezone,
   * you do not want to see 2AM next to a photo that was taken during lunch
   */
  @Column('bigint', {
    transformer: {
      from: (v) => parseInt(v, 10),
      to: (v) => v,
    },
  })
  @Index()
  creationDate: number;

  @Column('smallint', {
    transformer: {
      from: (v) => Utils.getOffsetString(v), //from database repr. as smallint (minutes) to string (+/-HH:MM)
      to: (v) => Utils.getOffsetMinutes(v), //from entiry repr. as string (+/-HH:MM) to smallint (minutes)
    },
  })
  creationDateOffset?: string;


  @Column('bigint', {unsigned: true, transformer: {from: (v) => v == null ? null : parseInt(v, 10), to: (v) => v}})
  fileSize: number;

  @Column({
    type: 'simple-array',
    charset: columnCharsetCS.charset,
    collation: columnCharsetCS.collation,
  })
  keywords: string[];

  @Column(() => CameraMetadataEntity)
  cameraData: CameraMetadataEntity;

  @Column('tinyint', {unsigned: true})
  @Index()
  rating: 0 | 1 | 2 | 3 | 4 | 5;

  @Column('int', {unsigned: true})
  bitRate: number;

  @Column('int', {unsigned: true})
  duration: number;
}

// TODO: fix inheritance once its working in typeorm
@Entity()
@Unique(['name', 'directory'])
@TableInheritance({column: {type: 'varchar', name: 'type', length: 16}})
export abstract class MediaEntity implements MediaDTO {
  @Index()
  @PrimaryGeneratedColumn({unsigned: true})
  id: number;

  @Column(columnCharsetCS)
  name: string;

  @Index()
  @ManyToOne(() => DirectoryEntity, (directory) => directory.media, {
    onDelete: 'CASCADE',
    nullable: false,
  })
  directory: DirectoryEntity;

  @Column(() => MediaMetadataEntity)
  metadata: MediaMetadataEntity;

  missingThumbnails: number;
}
