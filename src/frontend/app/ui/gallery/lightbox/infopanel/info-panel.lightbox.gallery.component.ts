import {Component, EventEmitter, Input, OnInit, Output,} from '@angular/core';
import {CameraMetadata, PhotoDTO, PhotoMetadata,} from '../../../../../../common/entities/PhotoDTO';
import {Config} from '../../../../../../common/config/public/Config';
import {MediaDTO, MediaDTOUtils,} from '../../../../../../common/entities/MediaDTO';
import {VideoDTO, VideoMetadata,} from '../../../../../../common/entities/VideoDTO';
import {Utils} from '../../../../../../common/Utils';
import {QueryService} from '../../../../model/query.service';
import {
  ANDSearchQuery,
  DateSearch,
  SearchQueryTypes,
  TextSearch,
  TextSearchQueryMatchTypes,
} from '../../../../../../common/entities/SearchQueryDTO';
import {AuthenticationService} from '../../../../model/network/authentication.service';
import {ContentLoaderService} from '../../contentLoader.service';
import {NgIf, NgFor, NgSwitch, NgSwitchCase, DatePipe} from '@angular/common';
import {NgIconComponent} from '@ng-icons/core';
import {RouterLink} from '@angular/router';
import {DurationPipe} from '../../../../pipes/DurationPipe';
import {FileSizePipe} from '../../../../pipes/FileSizePipe';
import {SearchQueryUtils} from '../../../../../../common/SearchQueryUtils';

@Component({
  selector: 'app-info-panel',
  styleUrls: ['./info-panel.lightbox.gallery.component.css'],
  templateUrl: './info-panel.lightbox.gallery.component.html',
  imports: [
    NgIf,
    NgIconComponent,
    RouterLink,
    NgFor,
    NgSwitch,
    NgSwitchCase,
    DatePipe,
    DurationPipe,
    FileSizePipe,
  ]
})
export class InfoPanelLightboxComponent implements OnInit {
  @Input() media: MediaDTO;
  @Output() closed = new EventEmitter();

  public readonly searchEnabled: boolean;
  public readonly starsSuffix = $localize`:@@lightbox.stars:stars`;
  public keywords: { value: string; type: SearchQueryTypes }[] = null;
  public readonly SearchQueryTypes: typeof SearchQueryTypes = SearchQueryTypes;

  constructor(
    public queryService: QueryService,
    public contentLoaderService: ContentLoaderService,
    private authService: AuthenticationService
  ) {
    this.searchEnabled = this.authService.canSearch();
  }

  get FullPath(): string {
    return Utils.concatUrls(
      this.media.directory.path,
      this.media.directory.name,
      this.media.name
    );
  }

  get DirectoryPath(): string {
    return Utils.concatUrls(
      this.media.directory.path,
      this.media.directory.name
    );
  }

  get DirectoryPathStr(): string {
    const p = this.DirectoryPath;
    if (p === '.') {
      return $localize`Home`;
    }
    if (p.length > 25) {
      return '...' + p.slice(-22);
    }
    return p;
  }

  get VideoData(): VideoMetadata {
    if (typeof (this.media as VideoDTO).metadata.bitRate === 'undefined') {
      return null;
    }
    return (this.media as VideoDTO).metadata;
  }

  get Rating(): number {
    return (this.media as PhotoDTO).metadata.rating;
  }

  get CameraData(): CameraMetadata {
    return (this.media as PhotoDTO).metadata.cameraData;
  }

  ngOnInit(): void {
    const metadata = this.media.metadata as PhotoMetadata;
    if (metadata.keywords && metadata.keywords.length > 0) {
      this.keywords = (metadata.keywords || []).map(
        (k): { type: SearchQueryTypes; value: string } => ({
          value: k,
          type: SearchQueryTypes.keyword,
        })
      );
    }
  }

  isPhoto(): boolean {
    return this.media && MediaDTOUtils.isPhoto(this.media);
  }

  calcMpx(): string {
    return (
      (this.media.metadata.size.width * this.media.metadata.size.height) /
      1000000
    ).toFixed(2);
  }

  isThisYear(): boolean {
    return MediaDTOUtils.createdThisYear(this.media);
  }

  toFraction(f: number): string | number {
    if (f > 1) {
      return f;
    }
    return '1/' + Math.round(1 / f);
  }

  close(): void {
    this.closed.emit();
  }

  getTextSearchQuery(name: string, type: SearchQueryTypes): string {
    return SearchQueryUtils.urlify({
      type,
      matchType: TextSearchQueryMatchTypes.exact_match,
      value: name,
    } as TextSearch);
  }

  getDateSearchQuery(): string {
    // Search for photos taken on the same date (within 24 hours)
    const creationDate = new Date(this.media.metadata.creationDate);
    const startOfDay = new Date(creationDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(creationDate);
    endOfDay.setHours(23, 59, 59, 999);

    return SearchQueryUtils.urlify({
      type: SearchQueryTypes.date,
      min: startOfDay.getTime(),
      max: endOfDay.getTime()
    } as DateSearch);
  }

}
