import {Component, ElementRef, Input, OnDestroy, OnInit, ViewChild,} from '@angular/core';
import {Dimension, IRenderable} from '../../../../model/IRenderable';
import {GridMedia} from '../GridMedia';
import {RouterLink} from '@angular/router';
import {Thumbnail, ThumbnailManagerService,} from '../../thumbnailManager.service';
import {Config} from '../../../../../../common/config/public/Config';
import {PageHelper} from '../../../../model/page.helper';
import {PhotoDTO, PhotoMetadata,} from '../../../../../../common/entities/PhotoDTO';
import {SearchQueryTypes, TextSearch, TextSearchQueryMatchTypes,} from '../../../../../../common/entities/SearchQueryDTO';
import {AuthenticationService} from '../../../../model/network/authentication.service';
import {NgFor, NgIf, NgSwitch, NgSwitchCase} from '@angular/common';
import {GalleryPhotoLoadingComponent} from './loading/loading.photo.grid.gallery.component';
import {NgIconComponent} from '@ng-icons/core';
import {DurationPipe} from '../../../../pipes/DurationPipe';
import {SearchQueryUtils} from '../../../../../../common/SearchQueryUtils';

@Component({
  selector: 'app-gallery-grid-photo',
  templateUrl: './photo.grid.gallery.component.html',
  styleUrls: ['./photo.grid.gallery.component.css'],
  imports: [
    NgIf,
    GalleryPhotoLoadingComponent,
    NgIconComponent,
    RouterLink,
    NgFor,
    NgSwitch,
    NgSwitchCase,
    DurationPipe,
  ]
})
export class GalleryPhotoComponent implements IRenderable, OnInit, OnDestroy {
  @Input() gridMedia: GridMedia;
  @ViewChild('img', {static: false}) imageRef: ElementRef;
  @ViewChild('photoContainer', {static: true}) container: ElementRef;

  thumbnail: Thumbnail;
  keywords: { value: string; type: SearchQueryTypes }[] = null;
  infoBarVisible = false;
  animationTimer: number = null;

  readonly SearchQueryTypes: typeof SearchQueryTypes = SearchQueryTypes;
  searchEnabled = true;

  wasInView: boolean = null;
  loaded = false;

  constructor(
    private thumbnailService: ThumbnailManagerService,
    private authService: AuthenticationService,
  ) {
    this.searchEnabled = this.authService.canSearch();
  }

  get ScrollListener(): boolean {
    return !this.thumbnail.Available && !this.thumbnail.Error;
  }

  get Title(): string {
    if (Config.Gallery.captionFirstNaming === false) {
      return this.gridMedia.media.name;
    }
    if ((this.gridMedia.media as PhotoDTO).metadata.caption) {
      if ((this.gridMedia.media as PhotoDTO).metadata.caption.length > 20) {
        return (
          (this.gridMedia.media as PhotoDTO).metadata.caption.substring(0, 17) +
          '...'
        );
      }
      return (this.gridMedia.media as PhotoDTO).metadata.caption;
    }
    return this.gridMedia.media.name;
  }

  ngOnInit(): void {
    this.thumbnail = this.thumbnailService.getThumbnail(this.gridMedia);
    const metadata = this.gridMedia.media.metadata as PhotoMetadata;
    if (metadata.keywords && metadata.keywords.length > 0) {
      this.keywords = (metadata.keywords || []).map(
        (k): { type: SearchQueryTypes; value: string } => ({
          value: k,
          type: SearchQueryTypes.keyword,
        })
      );
    }
  }

  ngOnDestroy(): void {
    this.thumbnail.destroy();

    if (this.animationTimer != null) {
      clearTimeout(this.animationTimer);
    }
  }

  isInView(): boolean {
    return (
      PageHelper.ScrollY <
      this.container.nativeElement.offsetTop +
      this.container.nativeElement.clientHeight &&
      PageHelper.ScrollY + window.innerHeight >
      this.container.nativeElement.offsetTop
    );
  }

  onScroll(): void {
    if (this.thumbnail.Available === true || this.thumbnail.Error === true) {
      return;
    }
    const isInView = this.isInView();
    if (this.wasInView !== isInView) {
      this.wasInView = isInView;
      this.thumbnail.Visible = isInView;
    }
  }

  getTextSearchQuery(name: string, type: SearchQueryTypes): string {
    return SearchQueryUtils.urlify({
      type,
      matchType: TextSearchQueryMatchTypes.exact_match,
      value: name,
    } as TextSearch);
  }

  mouseOver(): void {
    this.infoBarVisible = true;
    if (this.animationTimer != null) {
      clearTimeout(this.animationTimer);
      this.animationTimer = null;
    }
  }

  mouseOut(): void {
    if (this.animationTimer != null) {
      clearTimeout(this.animationTimer);
    }
    this.animationTimer = window.setTimeout((): void => {
      this.animationTimer = null;
      this.infoBarVisible = false;
    }, 500);
  }

  public getDimension(): Dimension {
    if (!this.imageRef?.nativeElement?.offsetParent) {
      return {
        top: 0,
        left: 0,
        width: 0,
        height: 0,
      };
    }
    return {
      top: this.imageRef.nativeElement.offsetParent.offsetTop,
      left: this.imageRef.nativeElement.offsetParent.offsetLeft,
      width: this.imageRef.nativeElement.width,
      height: this.imageRef.nativeElement.height,
    };
  }
}
