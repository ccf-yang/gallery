import {DynamicConfig} from '../DynamicConfig';

export enum DefaultsJobs {
  Indexing = 1,
  'Gallery Reset' = 2,
  'Video Converting' = 3,
  'Photo Converting' = 5,
  'Temp Folder Cleaning' = 6,
  'Album Cover Filling' = 7,
  'Album Cover Reset' = 8,
  'Album Reset' = 10
}


export enum DefaultMessengers {
  Stdout = 2
}


export interface JobDTO {
  Name: string;
  ConfigTemplate: DynamicConfig[];
}


export interface JobStartDTO {
  soloRun: boolean;
  config?: Record<string, unknown>;
  allowParallelRun: boolean;
}

export const JobDTOUtils = {
  getHashName: (jobName: string, config: any = {}) => {
    const sorted = Object.keys(config).sort().reduce((ret, key) => `${ret},${key}:${JSON.stringify(config[key])}`, '');
    return jobName + '-' + JSON.stringify(sorted);
  },
};
