export const QueryParams = {
  gallery: {
    random: {
      directory: 'dir',
      recursive: 'recursive',
      orientation: 'orientation',
      fromDate: 'fromDate',
      toDate: 'toDate',
      minResolution: 'fromRes',
      maxResolution: 'toRes',
    },
    search: {
      type: 'type',
      query: 'qs',
    },
    map: {
      show: 'map'
    },
    photo: 'p',
    directory: 'directory',
    knownLastModified: 'klm',
    knownLastScanned: 'kls',
    lightbox: {
      playback: 'play',
      captionAlwaysOn: 'cAO',
      controllersDimmed: 'cd',
      loopVideos: 'lv',
      loopSlideshow: 'ls',
      slideshowSpeed: 'ssp', // in seconds
      titles: {
        topLeftTitle: 'tlt',
        topLeftSubTitle: 'tlst',
        bottomLeftTitle: 'blt',
        bottomLeftSubTitle: 'blst',
      }
    },
    autoPollInterval: 'auInt',
  },
};
