import {ColumnOptions} from 'typeorm/decorator/options/ColumnOptions';

export class ColumnCharsetCS implements ColumnOptions {
  public get charset(): string {
    return 'utf8';
  }

  public get collation(): string {
    return null;
  }
}

export const columnCharsetCS = new ColumnCharsetCS();
export const SQL_COLLATE = 'utf8mb4_general_ci';
