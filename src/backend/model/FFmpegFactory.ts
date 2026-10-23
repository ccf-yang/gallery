import {FfmpegCommand} from 'fluent-ffmpeg';

/* eslint-disable @typescript-eslint/no-var-requires */
export class FFmpegFactory {
  public static get(): (path?: string) => FfmpegCommand {
    // uses the system installed ffmpeg/ffprobe from PATH
    return require('fluent-ffmpeg');
  }
}
